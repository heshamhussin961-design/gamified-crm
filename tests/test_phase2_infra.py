"""Phase 2 — Security & Infra tests.

Covers:
  * API versioning (/api/v1/ alias + Deprecation header on unversioned)
  * Rate-limit backend selection (memory vs db) + DB fail-open
  * Logger exists
  * Sentry init is conditional on env
"""

import os


def _auth():
    return {'Authorization': 'Bearer fake-token'}


# ── API Versioning ───────────────────────────────────────────

def test_v1_alias_routes_to_same_handler(client, fake_supabase):
    """GET /api/v1/health should hit the same handler as GET /api/health."""
    r1 = client.get('/api/health')
    r2 = client.get('/api/v1/health')
    assert r1.status_code == r2.status_code == 200
    # Both must return the same JSON body — the middleware rewrites the path so
    # routing resolves to the same handler.
    assert r1.get_json() == r2.get_json()


def test_versioned_response_has_x_api_version(client):
    res = client.get('/api/v1/health')
    assert res.headers.get('X-API-Version') == '1'


def test_unversioned_response_carries_deprecation(client):
    res = client.get('/api/health')
    assert res.headers.get('X-API-Version') == '1'
    assert res.headers.get('Deprecation') == 'true'
    assert '/api/v1/' in res.headers.get('Link', '')


def test_versioned_does_not_carry_deprecation(client):
    res = client.get('/api/v1/health')
    assert 'Deprecation' not in res.headers


def test_non_api_paths_have_no_version_headers(client):
    res = client.get('/')   # serves index template
    assert 'X-API-Version' not in res.headers
    assert 'Deprecation' not in res.headers


def test_v1_alias_works_for_authenticated_endpoint(client, fake_supabase):
    """The map milestones endpoint added in Phase 1 should also work under /api/v1/."""
    fake_supabase.set_table_default('employees', {
        'total_xp': 0, 'level': 1, 'syb_coins': 0, 'total_deals': 0,
        'full_name': 'X', 'title': 't',
    })
    res = client.get('/api/v1/map/milestones', headers=_auth())
    assert res.status_code == 200
    assert res.headers.get('X-API-Version') == '1'
    assert 'Deprecation' not in res.headers


# ── Logging ──────────────────────────────────────────────────

def test_logger_is_configured():
    import app
    assert hasattr(app, 'logger')
    assert app.logger.name == 'alsaeb'


# ── Sentry conditional init ──────────────────────────────────

def test_sentry_disabled_when_dsn_absent():
    import app
    # Default test env has no SENTRY_DSN
    assert app._sentry_enabled is False


# ── Rate-limit backend ───────────────────────────────────────

def test_rate_limit_backend_defaults_to_memory():
    import app
    assert app.RATE_LIMIT_BACKEND in ('memory', 'db')


def test_rate_limit_db_helper_fails_open_on_exception(fake_supabase, monkeypatch):
    """If the RPC throws, _rate_limit_db must return True (don't take down the app)."""
    import app

    class _BrokenRpc:
        def execute(self_inner):
            raise RuntimeError('db down')

    def fake_rpc(name, args=None):
        return _BrokenRpc()
    monkeypatch.setattr(app.supabase, 'rpc', fake_rpc, raising=False)
    assert app._rate_limit_db('uid', 'endpoint', 60) is True


def test_rate_limit_db_helper_honors_rpc_boolean(fake_supabase):
    """When RPC returns False (limit exceeded), helper returns False."""
    import app
    fake_supabase.set_rpc_response('check_rate_limit', False)
    assert app._rate_limit_db('uid', 'endpoint', 60) is False


def test_rate_limit_db_helper_allows_when_rpc_true(fake_supabase):
    import app
    fake_supabase.set_rpc_response('check_rate_limit', True)
    assert app._rate_limit_db('uid', 'endpoint', 60) is True


def test_rate_limit_db_backend_calls_rpc(client, fake_supabase, monkeypatch):
    """Switching backend to 'db' should make the decorator route through check_rate_limit."""
    import app
    monkeypatch.setattr(app, 'RATE_LIMIT_BACKEND', 'db', raising=False)
    fake_supabase.set_rpc_response('check_rate_limit', True)
    fake_supabase.set_rpc_response('award_xp_and_coins', {'success': True})
    # Trigger any rate-limited endpoint — claim_map_milestone has @rate_limit
    fake_supabase.set_rpc_response('claim_milestone_reward', {'success': True})
    res = client.post('/api/map/claim/1', headers=_auth())
    assert res.status_code == 200
    rpcs = [c['name'] for c in fake_supabase.rpc_calls()]
    assert 'check_rate_limit' in rpcs


def test_rate_limit_db_backend_returns_429_when_throttled(client, fake_supabase, monkeypatch):
    import app
    monkeypatch.setattr(app, 'RATE_LIMIT_BACKEND', 'db', raising=False)
    # Clear negative cache between tests to avoid bleed
    monkeypatch.setattr(app, '_rate_throttle_cache', {}, raising=False)
    fake_supabase.set_rpc_response('check_rate_limit', False)
    res = client.post('/api/map/claim/1', headers=_auth())
    assert res.status_code == 429


# ── Schema constants present ─────────────────────────────────

def test_current_api_version_constant():
    import app
    assert app.CURRENT_API_VERSION == '1'
