"""Phase 9 endpoint smoke tests (no real Supabase, no real Stripe)."""

import hmac
import hashlib
import json
import time


def _auth_headers():
    return {'Authorization': 'Bearer fake-token'}


# ---------- permissions layer ---------------------------------------

def test_permissions_endpoint_returns_role_and_perms(client, fake_supabase):
    # /api/me/permissions reads employees.role then role_permissions
    # our fake chain returns last-inserted data by default; queue responses:
    store = fake_supabase._store
    store['responses'] = {}  # chain returns None → handler falls back gracefully

    res = client.get('/api/me/permissions', headers=_auth_headers())
    assert res.status_code == 200
    body = res.get_json()
    assert 'role' in body['data']
    assert 'permissions' in body['data']


# ---------- password reset ------------------------------------------

def test_password_reset_always_succeeds_to_avoid_enumeration(client, fake_supabase):
    res = client.post('/api/auth/password/reset-request',
                      json={'email': 'does-not-exist@test.com'})
    assert res.status_code == 200
    assert res.get_json()['data']['sent'] is True


def test_password_reset_requires_email(client, fake_supabase):
    res = client.post('/api/auth/password/reset-request', json={})
    assert res.status_code == 400


def test_password_update_requires_min_length(client, fake_supabase):
    res = client.post('/api/auth/password/update',
                      json={'new_password': 'short'}, headers=_auth_headers())
    assert res.status_code == 400


# ---------- MFA ------------------------------------------------------

def test_mfa_challenge_requires_factor_id(client, fake_supabase):
    res = client.post('/api/auth/mfa/challenge', json={}, headers=_auth_headers())
    assert res.status_code == 400


def test_mfa_verify_requires_all_fields(client, fake_supabase):
    res = client.post('/api/auth/mfa/verify',
                      json={'factor_id': 'x'}, headers=_auth_headers())
    assert res.status_code == 400


# ---------- GDPR -----------------------------------------------------

def test_gdpr_delete_refuses_without_confirm(client, fake_supabase):
    res = client.post('/api/admin/users/abc/gdpr-delete',
                      json={'confirm': 'nope'}, headers=_auth_headers())
    # either 403 (no permission) or 400 (bad confirm) is acceptable — both prove the guard fires
    assert res.status_code in (400, 403)


# ---------- Stripe webhook signature verification -------------------

def test_stripe_webhook_rejects_bad_signature(client, fake_supabase, monkeypatch):
    monkeypatch.setenv('STRIPE_WEBHOOK_SECRET', 'whsec_test_secret')
    res = client.post('/api/billing/webhooks/stripe',
                      data=json.dumps({'id': 'evt_1', 'type': 'ping'}),
                      headers={'Stripe-Signature': 't=1,v1=deadbeef',
                               'Content-Type': 'application/json'})
    assert res.status_code == 400


def test_stripe_webhook_accepts_valid_signature(client, fake_supabase, monkeypatch):
    secret = 'whsec_test_secret'
    monkeypatch.setenv('STRIPE_WEBHOOK_SECRET', secret)
    ts = str(int(time.time()))
    body = json.dumps({'id': 'evt_ok', 'type': 'ping', 'data': {'object': {}}})
    signed = f'{ts}.{body}'.encode()
    v1 = hmac.new(secret.encode(), signed, hashlib.sha256).hexdigest()
    res = client.post('/api/billing/webhooks/stripe',
                      data=body,
                      headers={'Stripe-Signature': f't={ts},v1={v1}',
                               'Content-Type': 'application/json'})
    assert res.status_code == 200


def test_stripe_webhook_accepts_unsigned_in_dev_mode(client, fake_supabase, monkeypatch):
    monkeypatch.delenv('STRIPE_WEBHOOK_SECRET', raising=False)
    res = client.post('/api/billing/webhooks/stripe',
                      json={'id': 'evt_dev', 'type': 'ping', 'data': {'object': {}}})
    assert res.status_code == 200
