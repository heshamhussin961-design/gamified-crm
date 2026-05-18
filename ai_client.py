"""
🤖 AI Client — يدعم Claude (Anthropic) أو OpenAI.
Priority: ANTHROPIC_API_KEY > OPENAI_API_KEY.
Returns structured lead advice: suggestion, lead_score, sentiment, recommended_action.
"""

import json
import os
import re

ANTHROPIC_KEY = os.getenv('ANTHROPIC_API_KEY', '')
OPENAI_KEY    = os.getenv('OPENAI_API_KEY', '')
AI_MODEL      = os.getenv('AI_MODEL', '')  # override

SYSTEM_PROMPT = """أنت مساعد مبيعات عربي خبير. هدفك مساعدة الموظف في إقناع العميل وإغلاق الصفقة.
ردودك دايماً بالعربية، مختصرة (جملتين بحد أقصى للاقتراح)، وعملية.
دايماً رد بـ JSON فقط بالشكل ده:
{
  "suggestion": "نص الاقتراح للموظف — مش رسالة للعميل",
  "lead_score": رقم من 0 لـ 100,
  "sentiment": "positive | neutral | negative",
  "recommended_action": "call | whatsapp | meeting | follow_up | close_deal | drop",
  "recommended_template": "اسم قالب مناسب أو null"
}"""


def _build_user_prompt(lead: dict, messages: list) -> str:
    msgs_text = '\n'.join(
        f"- {'العميل' if m.get('direction') == 'inbound' else 'الموظف'}: {m.get('message_text', '')}"
        for m in (messages or [])[:15]
    ) or '(لا توجد محادثات بعد)'

    return f"""بيانات الليد:
- الاسم: {lead.get('name') or 'غير معروف'}
- الموبايل: {lead.get('phone')}
- الحالة الحالية: {lead.get('status')}
- الجودة: {lead.get('quality')}
- عدد مرات التواصل: {lead.get('contact_count') or 0}
- الحملة: {(lead.get('projects') or {}).get('name') or 'غير محدد'}

آخر المحادثات:
{msgs_text}

حلّل الموقف وارجع الـ JSON."""


def _parse_response(text: str) -> dict:
    """استخرج JSON من رد الـ LLM (حتى لو في نص زيادة)."""
    text = (text or '').strip()
    m = re.search(r'\{.*\}', text, re.DOTALL)
    if m:
        try:
            return json.loads(m.group(0))
        except json.JSONDecodeError:
            pass
    return {
        'suggestion': text[:300] or 'تعذر تحليل الرد من الـ AI',
        'lead_score': 50,
        'sentiment': 'neutral',
        'recommended_action': 'follow_up',
        'recommended_template': None,
    }


def _call_anthropic(lead: dict, messages: list) -> dict:
    import anthropic  # lazy import
    client = anthropic.Anthropic(api_key=ANTHROPIC_KEY)
    model = AI_MODEL or 'claude-haiku-4-5-20251001'

    resp = client.messages.create(
        model=model,
        max_tokens=400,
        system=[{
            'type': 'text',
            'text': SYSTEM_PROMPT,
            'cache_control': {'type': 'ephemeral'},  # prompt caching
        }],
        messages=[{
            'role': 'user',
            'content': _build_user_prompt(lead, messages),
        }],
    )
    text = ''.join(block.text for block in resp.content if block.type == 'text')
    parsed = _parse_response(text)
    parsed['_model']  = model
    parsed['_cached'] = getattr(resp.usage, 'cache_read_input_tokens', 0) or 0
    return parsed


def _call_openai(lead: dict, messages: list) -> dict:
    import openai  # lazy import
    client = openai.OpenAI(api_key=OPENAI_KEY)
    model = AI_MODEL or 'gpt-4o-mini'

    resp = client.chat.completions.create(
        model=model,
        messages=[
            {'role': 'system', 'content': SYSTEM_PROMPT},
            {'role': 'user',   'content': _build_user_prompt(lead, messages)},
        ],
        response_format={'type': 'json_object'},
        max_tokens=400,
    )
    text = resp.choices[0].message.content or ''
    parsed = _parse_response(text)
    parsed['_model'] = model
    return parsed


def _fallback(lead: dict, messages: list = None) -> dict:
    """Smart heuristic fallback — no API keys needed."""
    status = lead.get('status', 'new')
    contacts = lead.get('contact_count') or 0
    msgs = messages or []
    has_inbound = any(m.get('direction') == 'inbound' for m in msgs)

    suggestions = {
        'new': ('ابعت رسالة تعارف ودية واعرض مساعدتك. ابدأ بالاسم وذكر الحملة.', 'whatsapp'),
        'contacted': ('اسأل عن ميزانيته وموعد الشراء المتوقع. حاول تعرف احتياجاته الأساسية.', 'whatsapp'),
        'interested': ('ادعه لمكالمة قصيرة عشان تقرب منه الصفقة. جهز 2-3 خيارات مناسبة.', 'call'),
        'meeting_set': ('جهز عرض مخصص وأكد الميعاد قبلها بيوم. جهز إجابات للاعتراضات المتوقعة.', 'follow_up'),
        'negotiation': ('قدم عرض نهائي واضح بمميزات حصرية. لا تضغط أكتر من اللازم.', 'meeting'),
        'closed_won': ('مبروك! تابع مع العميل لضمان رضاه واطلب referral.', 'follow_up'),
        'closed_lost': ('اسأل عن سبب الرفض بلباقة. ممكن يفيدك في الصفقات الجاية.', 'follow_up'),
    }

    suggestion, action = suggestions.get(status, ('تابع معاه بعد يومين بدون ضغط.', 'follow_up'))

    # Smart scoring
    score = 30
    score += {'new': 0, 'contacted': 10, 'interested': 25, 'meeting_set': 40, 'negotiation': 55, 'closed_won': 95, 'closed_lost': 5}.get(status, 0)
    if has_inbound:
        score += 15
    if contacts >= 3:
        score += 10
    score = max(0, min(100, score))

    sentiment = 'positive' if has_inbound or status in ('interested', 'meeting_set', 'negotiation') else 'neutral'
    if status == 'closed_lost':
        sentiment = 'negative'

    return {
        'suggestion': suggestion,
        'lead_score': score,
        'sentiment': sentiment,
        'recommended_action': action,
        'recommended_template': None,
        '_fallback': True,
    }


def analyze_lead(lead: dict, messages: list) -> dict:
    """
    Entry point. Picks the best available provider or returns a heuristic fallback.
    """
    if ANTHROPIC_KEY:
        try:
            return _call_anthropic(lead, messages)
        except Exception as e:
            return {**_fallback(lead, messages), '_error': f'anthropic: {e}'}
    if OPENAI_KEY:
        try:
            return _call_openai(lead, messages)
        except Exception as e:
            return {**_fallback(lead, messages), '_error': f'openai: {e}'}
    return _fallback(lead, messages)


def generate_text(prompt: str, max_tokens: int = 600) -> str:
    """
    Free-form text generation (not lead-specific).
    Used for weekly reports, summaries, etc.
    Returns plain text string.
    """
    if ANTHROPIC_KEY:
        try:
            import anthropic
            client = anthropic.Anthropic(api_key=ANTHROPIC_KEY)
            resp = client.messages.create(
                model=AI_MODEL or 'claude-haiku-4-5-20251001',
                max_tokens=max_tokens,
                messages=[{'role': 'user', 'content': prompt}],
            )
            return ''.join(b.text for b in resp.content if b.type == 'text').strip()
        except Exception:
            pass
    if OPENAI_KEY:
        try:
            import openai
            client = openai.OpenAI(api_key=OPENAI_KEY)
            resp = client.chat.completions.create(
                model=AI_MODEL or 'gpt-4o-mini',
                messages=[{'role': 'user', 'content': prompt}],
                max_tokens=max_tokens,
            )
            return (resp.choices[0].message.content or '').strip()
        except Exception:
            pass
    return ''  # caller handles empty string
