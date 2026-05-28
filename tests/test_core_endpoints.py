"""Core endpoint integration tests — Leads CRUD, Actions, /api/me, Leaderboard.

These are the business-critical paths that power the agent + admin UIs. All
Supabase calls run through the FakeSupabase fixture — no network, no DB.
"""

import json


def _auth():
    return {'Authorization': 'Bearer fake-token'}


# ══════════════════════════════════════════════════════════════
# LEADS — CRUD
# ══════════════════════════════════════════════════════════════

def test_get_leads_requires_auth(client):
    res = client.get('/api/leads')
    assert res.status_code == 401


def test_get_leads_admin_sees_admin_view(client, admin_supabase):
    res = client.get('/api/leads', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['data']['is_admin_view'] is True


def test_get_leads_agent_does_not_see_admin_view(client, fake_supabase):
    # Default role is sales_agent (no admin override)
    fake_supabase.set_table_default('employees', {'role': 'sales_agent'})
    res = client.get('/api/leads', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['data']['is_admin_view'] is False


def test_get_leads_passes_status_filter(client, admin_supabase):
    res = client.get('/api/leads?status=new', headers=_auth())
    assert res.status_code == 200
    # Status filter should result in an eq('status', 'new') being applied
    leads_calls = [c for c in admin_supabase.calls() if c.get('op') == 'select']
    # At least one select chain saw the status filter
    assert any('status' in c.get('filters', {}) for c in leads_calls)


def test_get_leads_pagination_default(client, admin_supabase):
    res = client.get('/api/leads', headers=_auth())
    body = res.get_json()
    assert body['data']['page'] == 1
    assert body['data']['per_page'] == 20


def test_get_lead_detail_returns_actions_and_messages(client, fake_supabase):
    fake_supabase.set_table_default('leads', {'id': 'L1', 'name': 'Test', 'status': 'new'})
    res = client.get('/api/leads/L1', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['lead']['id'] == 'L1'
    assert 'actions' in body
    assert 'messages' in body


def test_create_lead_requires_admin_or_manager(client, fake_supabase):
    res = client.post('/api/leads', json={'phone': '0501234567'}, headers=_auth())
    assert res.status_code == 403


def test_create_lead_requires_phone(client, admin_supabase):
    res = client.post('/api/leads', json={'name': 'No Phone'}, headers=_auth())
    assert res.status_code == 400


def test_create_lead_admin_success(client, admin_supabase):
    # The endpoint does result.data[0] after insert — the fake needs to return a list.
    admin_supabase.set_table_default('leads', [{
        'id': 'L1', 'phone': '+971-50-123-4567', 'phone_clean': '971501234567', 'name': 'Ahmed',
    }])
    res = client.post(
        '/api/leads',
        json={'phone': '+971-50-123-4567', 'name': 'Ahmed', 'source': 'manual'},
        headers=_auth(),
    )
    assert res.status_code == 201
    inserts = [c for c in admin_supabase.calls() if c.get('op') == 'insert']
    lead_inserts = [c for c in inserts if isinstance(c.get('data'), dict) and 'phone_clean' in c['data']]
    assert lead_inserts, 'expected an insert into leads with cleaned phone'
    # phone_clean must strip non-digits
    assert lead_inserts[0]['data']['phone_clean'] == '971501234567'


# ══════════════════════════════════════════════════════════════
# LEADS — STATUS TRANSITIONS
# ══════════════════════════════════════════════════════════════

def test_update_lead_status_rejects_unknown_status(client, fake_supabase):
    res = client.patch(
        '/api/leads/L1/status',
        data=json.dumps({'status': 'banana'}),
        content_type='application/json',
        headers=_auth(),
    )
    assert res.status_code == 400


def test_update_lead_status_blocks_when_not_owner(client, fake_supabase):
    fake_supabase.set_table_default('leads', {'assigned_to': 'other-user'})
    res = client.patch(
        '/api/leads/L1/status',
        data=json.dumps({'status': 'contacted'}),
        content_type='application/json',
        headers=_auth(),
    )
    assert res.status_code == 403


def test_update_lead_status_calls_change_lead_status_rpc(client, fake_supabase):
    fake_supabase.set_table_default('leads', {'assigned_to': 'test-user-id'})
    fake_supabase.set_rpc_response('change_lead_status', {'success': True, 'from': 'new', 'to': 'contacted'})
    res = client.patch(
        '/api/leads/L1/status',
        data=json.dumps({'status': 'contacted'}),
        content_type='application/json',
        headers=_auth(),
    )
    assert res.status_code == 200
    rpc_names = [c['name'] for c in fake_supabase.rpc_calls()]
    assert 'change_lead_status' in rpc_names


def test_update_lead_status_logs_action_row(client, fake_supabase):
    fake_supabase.set_table_default('leads', {'assigned_to': 'test-user-id'})
    fake_supabase.set_rpc_response('change_lead_status', {'success': True, 'from': 'new', 'to': 'contacted'})
    client.patch(
        '/api/leads/L1/status',
        data=json.dumps({'status': 'contacted'}),
        content_type='application/json',
        headers=_auth(),
    )
    inserts = [c for c in fake_supabase.calls() if c.get('op') == 'insert' and isinstance(c.get('data'), dict)]
    status_action_inserts = [c for c in inserts if c['data'].get('action') == 'status_changed']
    assert status_action_inserts, 'expected actions_log row with action=status_changed'


# ══════════════════════════════════════════════════════════════
# LEADS — LOCK / UNLOCK
# ══════════════════════════════════════════════════════════════

def test_lock_lead_calls_acquire_rpc(client, fake_supabase):
    fake_supabase.set_rpc_response('acquire_lead_lock', {
        'success': True, 'lead_id': 'L1', 'expires_at': '2099-01-01T00:00:00Z',
    })
    res = client.post('/api/leads/L1/lock', json={}, headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'acquire_lead_lock']
    assert rpcs and rpcs[0]['args']['p_lead_id'] == 'L1'


def test_lock_lead_propagates_rpc_error(client, fake_supabase):
    fake_supabase.set_rpc_response('acquire_lead_lock', {'error': 'already_locked'})
    res = client.post('/api/leads/L1/lock', json={}, headers=_auth())
    assert res.status_code >= 400


def test_unlock_lead_calls_release_rpc(client, fake_supabase):
    fake_supabase.set_rpc_response('release_lead_lock', {'success': True})
    res = client.delete('/api/leads/L1/lock', headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'release_lead_lock']
    assert rpcs


# ══════════════════════════════════════════════════════════════
# ACTIONS — XP earning paths
# ══════════════════════════════════════════════════════════════

def test_log_call_awards_xp_via_rpc(client, fake_supabase):
    fake_supabase.set_table_default('leads', {'id': 'L1', 'status': 'new', 'contact_count': 0})
    fake_supabase.set_rpc_response('award_xp_and_coins', {'success': True, 'xp_added': 15})
    res = client.post('/api/actions/call', json={'lead_id': 'L1', 'duration_seconds': 60}, headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'award_xp_and_coins']
    assert rpcs, 'call should award XP'
    assert rpcs[0]['args']['p_xp'] == 15  # XP_CONFIG['call_made']


def test_log_call_increments_counter(client, fake_supabase):
    fake_supabase.set_table_default('leads', {'id': 'L1', 'status': 'new', 'contact_count': 0})
    fake_supabase.set_rpc_response('award_xp_and_coins', {'success': True})
    client.post('/api/actions/call', json={'lead_id': 'L1'}, headers=_auth())
    counter_calls = [c for c in fake_supabase.rpc_calls() if c['name'] == 'increment_employee_counter']
    assert counter_calls, 'call should bump total_calls counter'
    assert counter_calls[0]['args']['p_counter'] == 'total_calls'


def test_close_deal_awards_big_xp_for_high_value_deal(client, fake_supabase):
    """deals over 1M get 3x bonus, so 500 XP * 3 = 1500."""
    fake_supabase.set_table_default('leads', {'id': 'L1', 'status': 'interested'})
    fake_supabase.set_rpc_response('award_xp_and_coins', {'success': True, 'xp_added': 1500})
    res = client.post(
        '/api/actions/close-deal',
        json={'lead_id': 'L1', 'deal_value': 1_500_000},
        headers=_auth(),
    )
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'award_xp_and_coins']
    assert rpcs
    # Base XP=500, multiplier=3.0 → 1500
    assert rpcs[0]['args']['p_xp'] == 1500
    assert rpcs[0]['args']['p_coins'] == 150


def test_whatsapp_send_requires_lead_id(client, fake_supabase):
    res = client.post('/api/actions/whatsapp', json={'message': 'hi'}, headers=_auth())
    assert res.status_code == 400


# ══════════════════════════════════════════════════════════════
# /api/me + Leaderboard
# ══════════════════════════════════════════════════════════════

def test_me_requires_auth(client):
    res = client.get('/api/me')
    assert res.status_code == 401


def test_me_returns_employee(client, fake_supabase):
    fake_supabase.set_table_default('employees', {
        'id': 'test-user-id', 'full_name': 'Test', 'total_xp': 500, 'level': 1,
    })
    res = client.get('/api/me', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['employee']['full_name'] == 'Test'


def test_leaderboard_returns_board(client, fake_supabase):
    fake_supabase.set_table_default('leaderboard', [
        {'rank': 1, 'employee_id': 'A', 'score': 1000},
        {'rank': 2, 'employee_id': 'B', 'score': 800},
    ])
    res = client.get('/api/leaderboard', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert isinstance(body['leaderboard'], list)
    assert body['period'] == 'weekly'


def test_leaderboard_accepts_period_query(client, fake_supabase):
    fake_supabase.set_table_default('leaderboard', [])
    res = client.get('/api/leaderboard?period=monthly', headers=_auth())
    assert res.status_code == 200
    assert res.get_json()['period'] == 'monthly'


# ══════════════════════════════════════════════════════════════
# Response envelope sanity
# ══════════════════════════════════════════════════════════════

def test_success_envelope_shape(client, fake_supabase):
    """Every success_response() wrapped endpoint must include the standard fields."""
    fake_supabase.set_table_default('employees', {
        'total_xp': 0, 'level': 1, 'syb_coins': 0, 'total_deals': 0,
        'full_name': 'X', 'title': 't',
    })
    res = client.get('/api/map/milestones', headers=_auth())
    body = res.get_json()
    for field in ('status', 'message', 'data', 'timestamp'):
        assert field in body, f'envelope missing {field!r}'
    assert body['status'] == 'success'


def test_error_envelope_shape(client, fake_supabase):
    res = client.post('/api/map/claim/99', headers=_auth())
    body = res.get_json()
    for field in ('status', 'message', 'timestamp'):
        assert field in body
    assert body['status'] == 'error'
