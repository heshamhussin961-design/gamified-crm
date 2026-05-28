"""Map Rewards Engine — Phase 1 endpoint tests.

Covers /api/map/milestones, /api/map/claim/<idx>, /api/map/branches/<key>/claim.
All Supabase calls go through the FakeSupabase fixture — no network.
"""


def _auth():
    return {'Authorization': 'Bearer fake-token'}


# ── GET /api/map/milestones ──────────────────────────────────

def test_milestones_requires_auth(client):
    res = client.get('/api/map/milestones')
    assert res.status_code == 401


def test_milestones_returns_all_ten(client, fake_supabase):
    fake_supabase.set_table_default('employees', {
        'total_xp': 300, 'level': 2, 'syb_coins': 0, 'total_deals': 0,
        'full_name': 'Test', 'title': 'متدرب',
    })
    res = client.get('/api/map/milestones', headers=_auth())
    assert res.status_code == 200
    data = res.get_json()['data']
    assert len(data['milestones']) == 10
    assert data['milestones'][0]['key'] == 'deira'
    assert data['milestones'][9]['key'] == 'burj_khalifa'


def test_milestones_marks_unlocked_by_xp(client, fake_supabase):
    fake_supabase.set_table_default('employees', {
        'total_xp': 600, 'level': 3, 'syb_coins': 0, 'total_deals': 0,
        'full_name': 'X', 'title': 't',
    })
    res = client.get('/api/map/milestones', headers=_auth())
    ms = res.get_json()['data']['milestones']
    # xp_req 0/200/500 unlocked; 1000+ locked
    assert ms[0]['unlocked'] and ms[1]['unlocked'] and ms[2]['unlocked']
    assert not ms[3]['unlocked']


def test_milestones_idx_zero_not_claimable_due_to_zero_reward(client, fake_supabase):
    fake_supabase.set_table_default('employees', {
        'total_xp': 100, 'level': 1, 'syb_coins': 0, 'total_deals': 0,
        'full_name': 'X', 'title': 't',
    })
    res = client.get('/api/map/milestones', headers=_auth())
    ms = res.get_json()['data']['milestones']
    # Deira has reward_xp=0, reward_coins=0 → never claimable
    assert ms[0]['unlocked'] is True
    assert ms[0]['claimable'] is False


def test_milestones_returns_four_branches(client, fake_supabase):
    fake_supabase.set_table_default('employees', {
        'total_xp': 0, 'level': 1, 'syb_coins': 0, 'total_deals': 0,
        'full_name': 'X', 'title': 't',
    })
    res = client.get('/api/map/milestones', headers=_auth())
    branches = res.get_json()['data']['branches']
    keys = {b['branch_key'] for b in branches}
    assert keys == {'calls', 'whatsapp', 'meetings', 'big_deals'}


def test_milestones_branch_defaults_when_no_row(client, fake_supabase):
    """When no branch_progress row exists, defaults should be returned."""
    fake_supabase.set_table_default('employees', {
        'total_xp': 0, 'level': 1, 'syb_coins': 0, 'total_deals': 0,
        'full_name': 'X', 'title': 't',
    })
    res = client.get('/api/map/milestones', headers=_auth())
    branches = res.get_json()['data']['branches']
    calls = next(b for b in branches if b['branch_key'] == 'calls')
    assert calls['current'] == 0
    assert calls['target'] == 10
    assert calls['xp_reward'] == 150
    assert calls['claimable'] is False


# ── POST /api/map/claim/<idx> ────────────────────────────────

def test_claim_milestone_requires_auth(client):
    res = client.post('/api/map/claim/1', headers={'X-Requested-With': 'XMLHttpRequest'})
    assert res.status_code == 401


def test_claim_milestone_rejects_out_of_range(client, fake_supabase):
    res = client.post('/api/map/claim/99', headers=_auth())
    assert res.status_code == 400


def test_claim_milestone_rejects_negative(client, fake_supabase):
    # Negative idx is a 404 — Flask route uses int converter which rejects '-1'.
    res = client.post('/api/map/claim/-1', headers=_auth())
    assert res.status_code in (400, 404)


def test_claim_milestone_rejects_zero_reward(client, fake_supabase):
    """idx=0 (Deira) has reward_xp=0, reward_coins=0 — server should refuse."""
    res = client.post('/api/map/claim/0', headers=_auth())
    assert res.status_code == 400


def test_claim_milestone_calls_rpc_with_canonical_values(client, fake_supabase):
    fake_supabase.set_rpc_response('claim_milestone_reward', {
        'success': True, 'milestone_idx': 1, 'xp_awarded': 50, 'coins_awarded': 25,
    })
    res = client.post('/api/map/claim/1', headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'claim_milestone_reward']
    assert len(rpcs) == 1
    args = rpcs[0]['args']
    # Server uses its own MAP_MILESTONES dict — values must match the canonical entry for idx=1
    assert args['p_milestone_idx'] == 1
    assert args['p_milestone_key'] == 'bur_dubai'
    assert args['p_required_xp']   == 200
    assert args['p_reward_xp']     == 50
    assert args['p_reward_coins']  == 25


def test_claim_milestone_propagates_rpc_error(client, fake_supabase):
    fake_supabase.set_rpc_response('claim_milestone_reward', {'error': 'already_claimed'})
    res = client.post('/api/map/claim/1', headers=_auth())
    assert res.status_code == 400
    assert 'already_claimed' in res.get_json()['message']


def test_claim_milestone_returns_success_payload(client, fake_supabase):
    fake_supabase.set_rpc_response('claim_milestone_reward', {
        'success': True, 'xp_awarded': 100, 'coins_awarded': 50,
    })
    res = client.post('/api/map/claim/2', headers=_auth())
    body = res.get_json()
    assert body['data']['xp_awarded'] == 100
    assert body['data']['coins_awarded'] == 50


# ── POST /api/map/branches/<key>/claim ───────────────────────

def test_claim_branch_requires_auth(client):
    res = client.post('/api/map/branches/calls/claim',
                      headers={'X-Requested-With': 'XMLHttpRequest'})
    assert res.status_code == 401


def test_claim_branch_rejects_unknown_key(client, fake_supabase):
    res = client.post('/api/map/branches/cooking/claim', headers=_auth())
    assert res.status_code == 400


def test_claim_branch_calls_rpc(client, fake_supabase):
    fake_supabase.set_rpc_response('claim_branch_reward', {
        'success': True, 'branch_key': 'calls', 'xp_awarded': 150, 'coins_awarded': 50,
    })
    res = client.post('/api/map/branches/calls/claim', headers=_auth())
    assert res.status_code == 200
    rpcs = [c for c in fake_supabase.rpc_calls() if c['name'] == 'claim_branch_reward']
    assert len(rpcs) == 1
    assert rpcs[0]['args']['p_branch_key'] == 'calls'


def test_claim_branch_propagates_rpc_error(client, fake_supabase):
    fake_supabase.set_rpc_response('claim_branch_reward', {'error': 'not_completed'})
    res = client.post('/api/map/branches/whatsapp/claim', headers=_auth())
    assert res.status_code == 400
    assert 'not_completed' in res.get_json()['message']


def test_claim_branch_accepts_all_four_keys(client, fake_supabase):
    fake_supabase.set_rpc_response('claim_branch_reward', {'success': True})
    for key in ('calls', 'whatsapp', 'meetings', 'big_deals'):
        res = client.post(f'/api/map/branches/{key}/claim', headers=_auth())
        assert res.status_code == 200, f'branch key {key} should be accepted'


# ── Server-authoritative behavior ────────────────────────────

def test_server_values_match_milestone_dict():
    """Sanity check: the MAP_MILESTONES dict mirrors what the map UI expects."""
    import app
    # Indices contiguous from 0..9
    for i, m in enumerate(app.MAP_MILESTONES):
        assert m['idx'] == i
    # Last milestone is Burj Khalifa (the legend tier)
    top = app.MAP_MILESTONES[-1]
    assert top['key'] == 'burj_khalifa'
    assert top['xp_req'] == 15000
    assert top['reward_xp'] == 2000
    assert top['reward_coins'] == 2500


def test_branch_keys_constant_is_complete():
    import app
    assert set(app.MAP_BRANCH_KEYS) == {'calls', 'whatsapp', 'meetings', 'big_deals'}
