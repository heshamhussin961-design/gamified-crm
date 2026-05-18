"""
Pytest fixtures.

Monkey-patches the Supabase client so tests never hit the network.
Each test gets a fresh FakeSupabase instance that records calls and
returns scripted data.
"""

import sys
import types
import pytest


class _Chain:
    """Minimal fluent chain that mimics Supabase-py's query builder."""

    def __init__(self, store, op='select'):
        self._store = store
        self._op = op
        self._data = None
        self._filters = {}

    def select(self, *_a, **_k): return self
    def insert(self, data):      self._data = data; self._op = 'insert'; return self
    def update(self, data):      self._data = data; self._op = 'update'; return self
    def delete(self):            self._op = 'delete'; return self
    def upsert(self, data):      self._data = data; self._op = 'upsert'; return self

    def eq(self, field, val):     self._filters[field] = val; return self
    def neq(self, *_, **__):      return self
    def gt(self, *_, **__):       return self
    def gte(self, *_, **__):      return self
    def lt(self, *_, **__):       return self
    def lte(self, *_, **__):      return self
    def in_(self, *_, **__):      return self
    def or_(self, *_, **__):      return self
    def order(self, *_, **__):    return self
    def limit(self, *_, **__):    return self
    def range(self, *_, **__):    return self
    def single(self):             return self

    def execute(self):
        self._store['calls'].append({
            'op': self._op, 'data': self._data, 'filters': self._filters,
        })
        key = self._store['_next_key']
        result = self._store['responses'].pop(key, None) if key else None
        if result is None:
            # Check table-level default responses
            table = self._store.get('last_table')
            if table and table in self._store.get('table_defaults', {}):
                result = {'data': self._store['table_defaults'][table]}
            else:
                result = {'data': self._data if self._op in ('insert', 'update') else None}
        self._store['_next_key'] = None
        return types.SimpleNamespace(data=result.get('data'), count=result.get('count'))


class _RpcChain:
    def __init__(self, store, name, args):
        self._store = store
        self._name = name
        self._args = args

    def execute(self):
        self._store['rpc_calls'].append({'name': self._name, 'args': self._args})
        payload = self._store['rpc_responses'].get(self._name, {'success': True})
        return types.SimpleNamespace(data=payload)


class _TableQueue:
    def __init__(self, store): self._store = store
    def __call__(self, name):
        self._store['last_table'] = name
        return _Chain(self._store)


class FakeSupabase:
    """Drop-in for the real Supabase client."""

    def __init__(self):
        self._store = {
            'calls':          [],
            'rpc_calls':      [],
            'responses':      {},  # keyed by 'next' marker, optional
            'rpc_responses':  {},
            'table_defaults': {},  # table name → default data for selects
            'last_table':     None,
            '_next_key':      None,
        }
        self.table = _TableQueue(self._store)
        self.auth = types.SimpleNamespace(
            get_user=lambda token: types.SimpleNamespace(
                user=types.SimpleNamespace(id='test-user-id', email='t@test.com'),
            ),
            sign_out=lambda: None,
        )

    def rpc(self, name, args=None):
        return _RpcChain(self._store, name, args or {})

    # --- test helpers ---
    def set_rpc_response(self, name, payload):
        self._store['rpc_responses'][name] = payload

    def set_table_default(self, table_name, data):
        """Set default data returned for SELECT queries on a table."""
        self._store['table_defaults'][table_name] = data

    def calls(self):
        return self._store['calls']

    def rpc_calls(self):
        return self._store['rpc_calls']


@pytest.fixture
def fake_supabase(monkeypatch):
    """Replaces `supabase` symbol in app module with a FakeSupabase."""
    fake = FakeSupabase()

    # ensure load_dotenv doesn't interfere and env vars exist
    import os
    os.environ.setdefault('SUPABASE_URL', 'http://fake')
    os.environ.setdefault('SUPABASE_SERVICE_KEY', 'fake')
    os.environ.setdefault('SUPABASE_ANON_KEY', 'fake-anon')

    # stub the supabase package before app.py imports it
    if 'supabase' not in sys.modules:
        stub = types.ModuleType('supabase')
        stub.create_client = lambda *a, **kw: fake
        stub.Client = object
        sys.modules['supabase'] = stub

    import app  # noqa: E402
    monkeypatch.setattr(app, 'supabase', fake, raising=False)
    return fake


@pytest.fixture
def client(fake_supabase):
    """Flask test client with auth stubbed."""
    import app  # noqa: E402
    app.app.config['TESTING'] = True
    return app.app.test_client()


@pytest.fixture
def admin_supabase(fake_supabase):
    """FakeSupabase configured to pass admin role checks."""
    fake_supabase.set_table_default('employees', {'role': 'admin', 'id': 'test-user-id'})
    return fake_supabase
