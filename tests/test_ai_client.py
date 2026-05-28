"""Unit tests for ai_client (no network)."""

import os

import pytest

import ai_client


def _sample_lead():
    return {
        'name': 'أحمد', 'phone': '+201001234567',
        'status': 'new', 'quality': 'hot', 'contact_count': 0,
        'projects': {'name': 'Campaign A'},
    }


def test_fallback_used_when_no_keys(monkeypatch):
    monkeypatch.setattr(ai_client, 'ANTHROPIC_KEY', '')
    monkeypatch.setattr(ai_client, 'OPENAI_KEY', '')
    result = ai_client.analyze_lead(_sample_lead(), [])
    assert result['_fallback'] is True
    assert result['recommended_action'] == 'whatsapp'  # new lead → whatsapp
    assert 0 <= result['lead_score'] <= 100


def test_fallback_picks_call_for_interested_leads(monkeypatch):
    monkeypatch.setattr(ai_client, 'ANTHROPIC_KEY', '')
    monkeypatch.setattr(ai_client, 'OPENAI_KEY', '')
    lead = {**_sample_lead(), 'status': 'interested'}
    result = ai_client.analyze_lead(lead, [])
    assert result['recommended_action'] == 'call'


def test_parse_response_extracts_embedded_json():
    text = 'Sure! Here is the analysis: {"suggestion": "تواصل", "lead_score": 80, "sentiment": "positive", "recommended_action": "call", "recommended_template": null} — hope this helps.'
    parsed = ai_client._parse_response(text)
    assert parsed['lead_score'] == 80
    assert parsed['sentiment'] == 'positive'


def test_parse_response_graceful_on_garbage():
    parsed = ai_client._parse_response('not json at all')
    assert 'suggestion' in parsed
    assert parsed['lead_score'] == 50
