"""Unit tests for whatsapp_client (no real HTTP)."""

import whatsapp_client


def test_skip_when_not_configured(monkeypatch):
    monkeypatch.setattr(whatsapp_client, 'PHONE_ID', '')
    monkeypatch.setattr(whatsapp_client, 'TOKEN', '')
    assert whatsapp_client.send_text('201000', 'hi')['skipped'] is True
    assert whatsapp_client.send_template('201000', 'welcome')['skipped'] is True


def test_clean_phone_number():
    assert whatsapp_client._clean('+20 100 123 4567') == '201001234567'
    assert whatsapp_client._clean('+20-100-123-4567') == '201001234567'
    assert whatsapp_client._clean('') == ''


def test_parse_webhook_text_messages():
    payload = {
        'entry': [{
            'changes': [{
                'value': {
                    'messages': [
                        {'from': '201001234567', 'id': 'wamid.1',
                         'type': 'text', 'text': {'body': 'Hello'}},
                        {'from': '201009999999', 'id': 'wamid.2',
                         'type': 'text', 'text': {'body': 'مرحبا'}},
                    ],
                },
            }],
        }],
    }
    parsed = whatsapp_client.parse_webhook(payload)
    assert len(parsed) == 2
    assert parsed[0]['text'] == 'Hello'
    assert parsed[1]['text'] == 'مرحبا'
    assert parsed[0]['message_id'] == 'wamid.1'


def test_parse_webhook_media_message():
    payload = {
        'entry': [{
            'changes': [{
                'value': {
                    'messages': [{
                        'from': '201000', 'id': 'wamid.3',
                        'type': 'image',
                        'image': {'id': 'media_123', 'caption': 'look'},
                    }],
                },
            }],
        }],
    }
    parsed = whatsapp_client.parse_webhook(payload)
    assert parsed[0]['media_id'] == 'media_123'
    assert parsed[0]['text'] == 'look'


def test_parse_webhook_empty_payload():
    assert whatsapp_client.parse_webhook({}) == []
    assert whatsapp_client.parse_webhook({'entry': []}) == []
