"""
📱 WhatsApp Business API client.
Wraps Meta Graph API for send/receive operations.

Required env vars (all in .env):
  WHATSAPP_API_URL   -- e.g. https://graph.facebook.com/v18.0
  WHATSAPP_PHONE_ID  -- Business phone number ID
  WHATSAPP_TOKEN     -- Permanent access token
  WHATSAPP_APP_SECRET -- for HMAC signature verification on webhooks

All methods fail gracefully if credentials are missing — they return
{"ok": False, "skipped": True} so the CRM stays usable in dev.
"""

import contextlib
import os

import requests

API_URL   = os.getenv('WHATSAPP_API_URL', 'https://graph.facebook.com/v18.0')
PHONE_ID  = os.getenv('WHATSAPP_PHONE_ID', '')
TOKEN     = os.getenv('WHATSAPP_TOKEN', '')

_TIMEOUT = 10


def _configured() -> bool:
    return bool(PHONE_ID and TOKEN)


def _headers():
    return {
        'Authorization': f'Bearer {TOKEN}',
        'Content-Type':  'application/json',
    }


def _endpoint(path: str) -> str:
    return f"{API_URL}/{PHONE_ID}/{path}"


def _clean(phone: str) -> str:
    """Normalize to international format without + (Meta requirement)."""
    return (phone or '').lstrip('+').replace(' ', '').replace('-', '')


# ============================================================
# SEND
# ============================================================

def send_text(to_phone: str, body: str) -> dict:
    """إرسال رسالة نص حرة."""
    if not _configured():
        return {'ok': False, 'skipped': True, 'reason': 'credentials_missing'}
    if not body:
        return {'ok': False, 'error': 'empty_body'}
    try:
        r = requests.post(
            _endpoint('messages'),
            json={
                'messaging_product': 'whatsapp',
                'to': _clean(to_phone),
                'type': 'text',
                'text': {'preview_url': False, 'body': body[:4096]},
            },
            headers=_headers(),
            timeout=_TIMEOUT,
        )
        return _parse_send(r)
    except requests.RequestException as e:
        return {'ok': False, 'error': str(e)}


def send_template(to_phone: str, template_name: str,
                  language: str = 'ar', variables: list | None = None) -> dict:
    """
    إرسال قالب مُعتمد من Meta Business Manager.
    variables: قيم للـ {{1}}, {{2}}, ... بالترتيب.
    """
    if not _configured():
        return {'ok': False, 'skipped': True, 'reason': 'credentials_missing'}
    components = []
    if variables:
        components.append({
            'type': 'body',
            'parameters': [{'type': 'text', 'text': str(v)} for v in variables],
        })
    try:
        r = requests.post(
            _endpoint('messages'),
            json={
                'messaging_product': 'whatsapp',
                'to': _clean(to_phone),
                'type': 'template',
                'template': {
                    'name': template_name,
                    'language': {'code': language},
                    'components': components,
                },
            },
            headers=_headers(),
            timeout=_TIMEOUT,
        )
        return _parse_send(r)
    except requests.RequestException as e:
        return {'ok': False, 'error': str(e)}


def send_media(to_phone: str, media_type: str, media_url: str,
               caption: str | None = None) -> dict:
    """media_type: image | document | audio | video."""
    if not _configured():
        return {'ok': False, 'skipped': True, 'reason': 'credentials_missing'}
    body = {media_type: {'link': media_url}}
    if caption and media_type in ('image', 'video', 'document'):
        body[media_type]['caption'] = caption
    try:
        r = requests.post(
            _endpoint('messages'),
            json={
                'messaging_product': 'whatsapp',
                'to': _clean(to_phone),
                'type': media_type,
                **body,
            },
            headers=_headers(),
            timeout=_TIMEOUT,
        )
        return _parse_send(r)
    except requests.RequestException as e:
        return {'ok': False, 'error': str(e)}


def mark_as_read(wa_message_id: str) -> dict:
    """فعّل المؤشر الأزرق (read receipt)."""
    if not _configured() or not wa_message_id:
        return {'ok': False, 'skipped': True}
    try:
        r = requests.post(
            _endpoint('messages'),
            json={
                'messaging_product': 'whatsapp',
                'status': 'read',
                'message_id': wa_message_id,
            },
            headers=_headers(),
            timeout=_TIMEOUT,
        )
        return _parse_send(r)
    except requests.RequestException as e:
        return {'ok': False, 'error': str(e)}


# ============================================================
# RECEIVE (webhook payload parser)
# ============================================================

def parse_webhook(payload: dict) -> list[dict]:
    """
    Parse Meta webhook payload → list of normalized message dicts:
    { from, text, message_id, type, media_url, timestamp, profile_name, referral }
    Meta nests everything under entry[].changes[].value — flatten it.

    referral (from Click-to-WhatsApp ads) contains:
    { source_url, source_type, source_id, headline, body }
    """
    out = []
    for entry in (payload or {}).get('entry', []):
        for change in entry.get('changes', []):
            value = change.get('value') or {}

            # Extract contact name from contacts array
            contacts_map = {}
            for contact in value.get('contacts', []) or []:
                wa_id = contact.get('wa_id')
                profile = contact.get('profile', {})
                if wa_id:
                    contacts_map[wa_id] = profile.get('name', '')

            for msg in value.get('messages', []) or []:
                item = {
                    'from':         msg.get('from'),
                    'message_id':   msg.get('id'),
                    'timestamp':    msg.get('timestamp'),
                    'type':         msg.get('type'),
                    'text':         None,
                    'media_id':     None,
                    'profile_name': contacts_map.get(msg.get('from'), ''),
                    'referral':     msg.get('referral'),  # Click-to-WhatsApp ad data
                    'context':      msg.get('context'),   # reply context
                }
                mtype = msg.get('type')
                if mtype == 'text':
                    item['text'] = (msg.get('text') or {}).get('body')
                elif mtype in ('image', 'audio', 'video', 'document'):
                    item['media_id'] = (msg.get(mtype) or {}).get('id')
                    item['text'] = (msg.get(mtype) or {}).get('caption')
                elif mtype == 'button':
                    item['text'] = (msg.get('button') or {}).get('text')
                out.append(item)
    return out


def _parse_send(r: requests.Response) -> dict:
    """Uniform response shape."""
    try:
        data = r.json()
    except ValueError:
        data = {'raw': r.text}
    if r.ok:
        msg_id = None
        with contextlib.suppress(KeyError, IndexError, TypeError):
            msg_id = data['messages'][0]['id']
        return {'ok': True, 'message_id': msg_id, 'data': data}
    return {'ok': False, 'status': r.status_code, 'error': data}
