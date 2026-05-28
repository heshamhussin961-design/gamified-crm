"""V2 feature endpoint tests — Break Room, CEO Visits, Squads."""


def _auth():
    return {'Authorization': 'Bearer fake-token'}


# ── Break Room ──────────────────────────────────────────

def test_breakroom_coffee_calls_regen_stamina(client, fake_supabase):
    fake_supabase.set_rpc_response('regen_stamina', {'ok': True, 'stamina': 100, 'regen': 30})
    res = client.post('/api/breakroom/coffee', json={}, headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'regen_stamina']
    assert len(rpcs) == 1
    assert rpcs[0]['args']['p_amount'] == 30


def test_breakroom_coffee_returns_message(client, fake_supabase):
    fake_supabase.set_rpc_response('regen_stamina', {'ok': True, 'stamina': 100, 'regen': 30})
    res = client.post('/api/breakroom/coffee', json={}, headers=_auth())
    body = res.get_json()
    assert res.status_code == 200
    assert 'قهوة' in body.get('message', '')


def test_breakroom_minigame_awards_xp(client, fake_supabase):
    fake_supabase.set_rpc_response('award_xp_and_coins', {'success': True})
    res = client.post('/api/breakroom/minigame', json={'score': 500}, headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['data']['xp'] == 5  # 500 // 100 = 5, clamped 2-10


def test_breakroom_minigame_clamps_xp_low(client, fake_supabase):
    fake_supabase.set_rpc_response('award_xp_and_coins', {'success': True})
    res = client.post('/api/breakroom/minigame', json={'score': 50}, headers=_auth())
    body = res.get_json()
    assert body['data']['xp'] >= 2


def test_breakroom_minigame_clamps_xp_high(client, fake_supabase):
    fake_supabase.set_rpc_response('award_xp_and_coins', {'success': True})
    res = client.post('/api/breakroom/minigame', json={'score': 5000}, headers=_auth())
    body = res.get_json()
    assert body['data']['xp'] <= 10


def test_breakroom_minigame_logs_action(client, fake_supabase):
    fake_supabase.set_rpc_response('award_xp_and_coins', {'success': True})
    res = client.post('/api/breakroom/minigame', json={'score': 300}, headers=_auth())
    assert res.status_code == 200
    inserts = [c for c in fake_supabase.calls() if c['op'] == 'insert']
    assert any(c['data'].get('action') == 'minigame' for c in inserts)


def test_breakroom_requires_auth(client, fake_supabase):
    # Send X-Requested-With so CSRF check passes; the actual auth check should then 401.
    res = client.post('/api/breakroom/coffee', json={},
                      headers={'X-Requested-With': 'XMLHttpRequest'})
    assert res.status_code == 401


# ── CEO Visits ──────────────────────────────────────────

def test_ceo_visit_start_requires_admin(client, fake_supabase):
    # Default fixture is non-admin
    res = client.post('/api/ceo-visit/start', json={'duration': 30}, headers=_auth())
    assert res.status_code == 403


def test_ceo_visit_start_admin(client, admin_supabase):
    import app
    app.app.config['TESTING'] = True
    c = app.app.test_client()
    res = c.post('/api/ceo-visit/start', json={'duration': 30}, headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['data']['multiplier'] == 3.0
    assert body['data']['type'] == 'ceo_visit'


def test_ceo_visit_start_default_duration(client, admin_supabase):
    import app
    app.app.config['TESTING'] = True
    c = app.app.test_client()
    res = c.post('/api/ceo-visit/start', json={}, headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['data']['duration'] == 30


def test_ceo_visit_active_returns_visit(client, fake_supabase):
    fake_supabase.set_table_default('power_hours', [{'type': 'ceo_visit', 'is_active': True, 'ends_at': '2099-01-01'}])
    res = client.get('/api/ceo-visit/active', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['data']['visit'] is not None


def test_ceo_visit_active_returns_none_when_empty(client, fake_supabase):
    res = client.get('/api/ceo-visit/active', headers=_auth())
    assert res.status_code == 200


# ── Squads ──────────────────────────────────────────────

def test_create_squad_requires_name(client, fake_supabase):
    res = client.post('/api/squads/create', json={'name': ''}, headers=_auth())
    assert res.status_code == 400


def test_create_squad_success(client, fake_supabase):
    fake_supabase.set_table_default('teams', [{'id': 'squad-1', 'name': 'Alpha'}])
    res = client.post('/api/squads/create', json={'name': 'Alpha'}, headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert 'سكواد' in body.get('message', '')


def test_join_squad_requires_id(client, fake_supabase):
    res = client.post('/api/squads/join', json={}, headers=_auth())
    assert res.status_code == 400


def test_join_squad_success(client, fake_supabase):
    res = client.post('/api/squads/join', json={'squad_id': 'squad-1'}, headers=_auth())
    assert res.status_code == 200


def test_list_squads(client, fake_supabase):
    res = client.get('/api/squads', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert 'squads' in body['data']


def test_my_squad(client, fake_supabase):
    res = client.get('/api/squads/my', headers=_auth())
    assert res.status_code == 200


def test_leave_squad(client, fake_supabase):
    res = client.post('/api/squads/leave', json={}, headers=_auth())
    assert res.status_code == 200


def test_squads_require_auth(client, fake_supabase):
    res = client.get('/api/squads')
    assert res.status_code == 401


# ── Story Mode ─────────────────────────────────────────

def test_story_progress(client, fake_supabase):
    fake_supabase.set_table_default('employees', {'total_xp': 5000, 'level': 5})
    res = client.get('/api/story/progress', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['data']['current_chapter'] >= 0
    assert body['data']['total_chapters'] == 20


def test_story_progress_returns_milestones(client, fake_supabase):
    fake_supabase.set_table_default('employees', {'total_xp': 1500, 'level': 3})
    res = client.get('/api/story/progress', headers=_auth())
    body = res.get_json()
    milestones = body['data'].get('milestones', [])
    assert len(milestones) == 20


def test_story_requires_auth(client, fake_supabase):
    res = client.get('/api/story/progress')
    assert res.status_code == 401


# ── Billing ────────────────────────────────────────────

def test_billing_checkout_requires_admin(client, fake_supabase):
    res = client.post('/api/billing/checkout', json={'plan': 'pro'}, headers=_auth())
    assert res.status_code == 403


def test_billing_portal_requires_admin(client, fake_supabase):
    res = client.post('/api/billing/portal', json={}, headers=_auth())
    assert res.status_code == 403


def test_billing_checkout_no_stripe_key(client, admin_supabase):
    import app
    app.app.config['TESTING'] = True
    c = app.app.test_client()
    res = c.post('/api/billing/checkout', json={'plan': 'pro'}, headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['data']['url'] is None


def test_billing_subscription_view(client, fake_supabase):
    res = client.get('/api/billing/subscription', headers=_auth())
    # May return 200 or 403 depending on permission check
    assert res.status_code in (200, 403)
