"""Game endpoints smoke tests — stamina, positions, badges, presence."""


def _auth():
    return {'Authorization': 'Bearer fake-token'}


# ── Stamina ──────────────────────────────────────────────

def test_get_stamina(client, fake_supabase):
    res = client.get('/api/stamina', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert 'stamina' in body['data']
    assert 'max_stamina' in body['data']


def test_drain_stamina(client, fake_supabase):
    fake_supabase.set_rpc_response('drain_stamina', {'ok': True, 'stamina': 90, 'drained': 10})
    res = client.post('/api/stamina/drain', json={'amount': 10}, headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'drain_stamina']
    assert len(rpcs) == 1
    assert rpcs[0]['args']['p_amount'] == 10


def test_regen_stamina(client, fake_supabase):
    fake_supabase.set_rpc_response('regen_stamina', {'ok': True, 'stamina': 100, 'regen': 5})
    res = client.post('/api/stamina/regen', json={'amount': 5}, headers=_auth())
    assert res.status_code == 200


# ── Positions ────────────────────────────────────────────

def test_get_positions(client, fake_supabase):
    res = client.get('/api/positions', headers=_auth())
    assert res.status_code == 200


def test_update_position(client, fake_supabase):
    fake_supabase.set_rpc_response('update_position', None)
    res = client.post('/api/positions/update',
                      json={'x': 5, 'y': 10, 'direction': 'up'},
                      headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'update_position']
    assert len(rpcs) == 1


# ── Presence ─────────────────────────────────────────────

def test_update_presence_status(client, fake_supabase):
    res = client.post('/api/presence/status',
                      json={'status': 'working'},
                      headers=_auth())
    assert res.status_code == 200


def test_get_online_users(client, fake_supabase):
    res = client.get('/api/presence/online', headers=_auth())
    assert res.status_code == 200


# ── Badges ───────────────────────────────────────────────

def test_get_badges(client, fake_supabase):
    res = client.get('/api/badges', headers=_auth())
    assert res.status_code == 200


def test_check_badges(client, fake_supabase):
    res = client.post('/api/badges/check', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert 'newly_earned' in body['data']


# ── Favicon ──────────────────────────────────────────────

def test_favicon(client, fake_supabase):
    res = client.get('/favicon.ico')
    assert res.status_code == 200
    assert res.content_type == 'image/x-icon'


# ── Game & Map pages ─────────────────────────────────────

def test_game_page(client, fake_supabase):
    res = client.get('/game')
    assert res.status_code == 200
    # Migrated to Three.js (was Phaser in v1) — assert the actual engine ships.
    assert b'three' in res.data.lower()


def test_map_page(client, fake_supabase):
    res = client.get('/map')
    assert res.status_code == 200
    assert b'svg' in res.data or b'SVG' in res.data


# ── Hot Leads ───────────────────────────────────────────

def test_get_active_hot_leads(client, fake_supabase):
    res = client.get('/api/hot-leads/active', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert 'events' in body['data']


def test_claim_hot_lead(client, fake_supabase):
    fake_supabase.set_rpc_response('claim_hot_lead', {'ok': True, 'xp_reward': 100, 'desk_index': 2})
    fake_supabase.set_rpc_response('award_xp_and_coins', {'ok': True})
    res = client.post('/api/hot-leads/claim',
                      json={'event_id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'},
                      headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'claim_hot_lead']
    assert len(rpcs) == 1


def test_claim_hot_lead_no_event_id(client, fake_supabase):
    res = client.post('/api/hot-leads/claim', json={}, headers=_auth())
    assert res.status_code == 400


# ── High Fives ──────────────────────────────────────────

def test_send_high_five(client, fake_supabase):
    fake_supabase.set_rpc_response('send_high_five', {'ok': True})
    fake_supabase.set_rpc_response('award_xp_and_coins', {'ok': True})
    res = client.post('/api/high-five/send',
                      json={'to_user_id': 'other-user-id'},
                      headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'send_high_five']
    assert len(rpcs) == 1
    assert rpcs[0]['args']['p_from'] == 'test-user-id'
    assert rpcs[0]['args']['p_to'] == 'other-user-id'


def test_send_high_five_no_target(client, fake_supabase):
    res = client.post('/api/high-five/send', json={}, headers=_auth())
    assert res.status_code == 400


def test_get_high_fives_today(client, fake_supabase):
    res = client.get('/api/high-fives/today', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert 'total_given' in body['data']


# ── Power Hours ─────────────────────────────────────────

def test_get_active_power_hour(client, fake_supabase):
    res = client.get('/api/power-hours/active', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert 'power_hour' in body['data']


# ── Daily Highlights ────────────────────────────────────

def test_get_latest_highlights(client, fake_supabase):
    res = client.get('/api/daily-highlights/latest', headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert 'highlights' in body['data']


# ── Admin: Hot Lead Spawn ───────────────────────────────

def test_spawn_hot_lead(client, admin_supabase):
    res = client.post('/api/hot-leads/spawn',
                      json={'xp_reward': 100, 'duration_secs': 60},
                      headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert 'desk_index' in body['data']


def test_spawn_hot_lead_no_admin(client, fake_supabase):
    """Non-admin should get 403."""
    res = client.post('/api/hot-leads/spawn', json={}, headers=_auth())
    assert res.status_code == 403


# ── Admin: Power Hour ──────────────────────────────────

def test_activate_power_hour(client, admin_supabase):
    res = client.post('/api/power-hours/activate',
                      json={'type': 'happy_hour', 'duration': 60},
                      headers=_auth())
    assert res.status_code == 200
    body = res.get_json()
    assert body['data']['type'] == 'happy_hour'


def test_activate_power_hour_invalid_type(client, admin_supabase):
    res = client.post('/api/power-hours/activate',
                      json={'type': 'invalid_type'},
                      headers=_auth())
    assert res.status_code == 400


# ── Admin: Daily Highlights ─────────────────────────────

def test_generate_daily_highlights(client, admin_supabase):
    admin_supabase.set_rpc_response('generate_daily_highlights', {
        'ok': True, 'best_dealer': {}, 'most_calls': {},
        'most_improved': {}, 'daily_mvp': {}, 'team_stats': {}
    })
    res = client.post('/api/daily-highlights/generate', headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in admin_supabase.rpc_calls() if c['name'] == 'generate_daily_highlights']
    assert len(rpcs) == 1
