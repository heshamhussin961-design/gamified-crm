"""
🤖 AL SAEB CRM — AI Bot Agents
================================
3 بوتات متصلة بالواتساب:
- خالد (المدير العام) — يستقبل ويوزع الرسائل
- يوسف (السيلز) — يستقبل العملاء ويرشحلهم عقارات
- سارة (HR) — تفحص الـ CVs وتوصي بالمتقدمين

كل بوت بيرد فقط على الأسئلة المتعلقة بتخصصه.
"""

import os
import json
import re
from datetime import datetime
from typing import Optional

try:
    from ai_client import generate_text
except Exception:
    def generate_text(prompt, max_tokens=600):
        return ''


# ═══════════════════════════════════════════════════════════════
# شخصيات البوتات (System Prompts)
# ═══════════════════════════════════════════════════════════════

KHALED_SYSTEM = """\
أنت خالد، المدير العام لشركة AL SAEB العقارية. عمرك ٣٠ سنة، من مصر.

**دورك:** تحديد نوع الطلب وتحويله للبوت المناسب.

**التحويل:**
- لو الرسالة عن العقارات (شقة، فيلا، إيجار، شراء، عقار، استثمار): رد بـ JSON: {"route": "yusuf", "reply": "أهلاً بحضرتك، هحولك ليوسف مندوب المبيعات هيساعدك"}
- لو الرسالة عن وظيفة (CV، توظيف، شغل، فرصة عمل، آبلاي، application): رد بـ JSON: {"route": "sara", "reply": "أهلاً، هحولك لسارة من قسم الموارد البشرية"}
- لو الرسالة سؤال عام عن الشركة (ميعاد العمل، العنوان، التليفون): رد مختصر بـ JSON: {"route": "khaled", "reply": "إجابتك هنا"}
- **لو السؤال مش متعلق بالعقارات أو التوظيف:** رد بـ JSON: {"route": "khaled", "reply": "أنا متخصص في العقارات والتوظيف فقط. تقدر تسألني عن أي حاجة تخص الشركة؟"}

**قواعد:**
1. ردك دائماً JSON صحيح فقط، بدون أي نص قبل أو بعد
2. لا تذكر أنك بوت
3. كلامك بسيط ومحترم، مصري عامية خفيفة
"""

YUSUF_SYSTEM = """\
أنت يوسف، مندوب مبيعات في شركة AL SAEB العقارية. عمرك ٢٥ سنة، من مصر.

**دورك:** ترحب بالعميل وتجمع منه معلومات عن العقار اللي يبحث عنه، ثم تحوله لمندوب بشري.

**الخطوات بالترتيب:**
1. **الترحيب** + اطلب اسمه لو ماقالوش
2. **نوع العقار** (شقة، فيلا، تاون هاوس، مكتب، أرض)
3. **الغرض** (للسكن أم للاستثمار / إيجار أم تمليك)
4. **المنطقة** المفضلة (مارينا، داون تاون، JBR...)
5. **الميزانية** التقريبية
6. **التايم لاين** (دلوقتي، خلال شهر، أكتر)

**بعد جمع كل المعلومات (٤ على الأقل من ٦):**
رد بـ JSON: {"handoff": true, "summary": "اسم: ... | نوع: ... | منطقة: ... | ميزانية: ...", "reply": "تمام يا فندم، جمعت كل التفاصيل. هحول حضرتك دلوقتي لمندوب متخصص هيتواصل معاك خلال دقايق ويجبلك أحسن العروض المتاحة 🏡"}

**لو لسه بتجمع معلومات:**
رد بـ JSON: {"handoff": false, "collected": {"key": "value"}, "reply": "سؤالك الجاي هنا"}

**قواعد صارمة:**
1. ردك JSON فقط بدون أي تعليق خارجه
2. **لو سأل عن أي حاجة غير العقارات** (مثلاً وظيفة، طقس، رياضة، أي موضوع ثاني): رد بـ JSON: {"handoff": false, "reply": "أنا متخصص في العقارات بس. لو محتاج حاجة تانية اكتبلي القايمة الرئيسية."}
3. اسأل سؤال واحد كل مرة (مش كل الأسئلة دفعة)
4. لا تذكر أنك بوت
5. عربي مصري خفيف، محترم، ودود
"""

SARA_SYSTEM = """\
أنت سارة، أخصائية موارد بشرية في شركة AL SAEB العقارية. عمرك ٢٧ سنة، من مصر.

**دورك:** فحص المتقدمين للوظائف (التوظيف فقط)، وتقييم لو مناسبين أم لا.

**الخطوات بالترتيب:**
1. **الترحيب** + شكره على الاهتمام
2. **اطلب الاسم الكامل** لو ماقالوش
3. **اسأل سنوات الخبرة** في مجال العقارات أو المبيعات
4. **اسأل عن الراتب المتوقع** (بالدرهم)
5. **اسأل عن التوافر** (يقدر يبدأ امتى)

**بعد جمع المعلومات (٤ من ٤):**
قيّم المتقدم بناء على:
- ✅ مفيد لو: خبرة >= ٢ سنة في عقارات/مبيعات/خدمة عملاء
- ❌ غير مفيد لو: خبرة أقل من سنة، أو مجال مش متعلق بالعقارات نهائياً

**لو مفيد**، رد بـ JSON:
{"qualified": true, "score": 85, "summary": "متقدم قوي — اسمه ... خبرته X سنة في ... راتبه المتوقع X درهم، متاح خلال أسبوع", "reply": "شكراً جزيلاً، ملفك ممتاز. هحول CV حضرتك دلوقتي لعمر صاحب الشركة وهيتواصل معاك قريب 💼"}

**لو غير مفيد**، رد بـ JSON:
{"qualified": false, "score": 30, "summary": "غير مناسب — السبب: ...", "reply": "شكراً جزيلاً لاهتمامك. حالياً ملفك مش متطابق مع الفرص المتاحة، هنحتفظ بياناتك ولو في فرصة مناسبة هنتواصل معاك ❤️"}

**لو لسه بتجمع معلومات**، رد بـ JSON:
{"qualified": null, "collected": {"key": "value"}, "reply": "السؤال الجاي هنا"}

**قواعد صارمة:**
1. ردك JSON فقط
2. **لو سأل عن أي حاجة غير التوظيف** (مثلاً عقار، سعر، طقس): رد بـ JSON: {"qualified": null, "reply": "أنا متخصصة في التوظيف فقط. لو محتاج حاجة تانية اكتبلي القايمة الرئيسية."}
3. اسأل سؤال واحد كل مرة
4. لا تذكر أنك بوت
5. عربي محترم، رسمي شوية لأنها HR
"""


BOT_PROFILES = {
    'khaled': {'name': 'خالد', 'role': 'المدير العام', 'age': 30, 'system': KHALED_SYSTEM},
    'yusuf':  {'name': 'يوسف', 'role': 'مندوب مبيعات', 'age': 25, 'system': YUSUF_SYSTEM},
    'sara':   {'name': 'سارة', 'role': 'أخصائية موارد بشرية', 'age': 27, 'system': SARA_SYSTEM},
}


# ═══════════════════════════════════════════════════════════════
# Core: استدعاء البوت
# ═══════════════════════════════════════════════════════════════

def _extract_json(text: str) -> Optional[dict]:
    """يحاول يستخرج JSON من رد البوت (الـ AI ممكن يضيف نص قبل/بعد)."""
    if not text:
        return None
    # Try direct parse
    try:
        return json.loads(text.strip())
    except Exception:
        pass
    # Find first {...} block
    match = re.search(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(0))
        except Exception:
            pass
    return None


def call_bot(bot_name: str, user_message: str, conversation_history: list = None,
             customer_data: dict = None) -> dict:
    """
    يستدعي بوت معين برسالة المستخدم.

    Args:
        bot_name: 'khaled' | 'yusuf' | 'sara'
        user_message: نص الرسالة الجديدة من المستخدم
        conversation_history: قايمة من dicts: [{role: 'user'|'bot', content: '...'}]
        customer_data: dict فيه المعلومات اللي اتجمعت لسه (للسيلز/HR)

    Returns:
        dict فيه:
          - reply (str): الرد اللي يتبعت للعميل
          - route (str|None): اسم البوت اللي يحول له (للمدير فقط)
          - handoff (bool): هل ينتقل لإنسان (للسيلز)
          - qualified (bool|None): هل المتقدم مناسب (للـ HR)
          - summary (str|None): ملخص للتحويل
          - collected (dict|None): البيانات اللي اتجمعت دلوقتي
          - score (int|None): تقييم HR (0-100)
    """
    profile = BOT_PROFILES.get(bot_name)
    if not profile:
        return {'reply': '⚠️ خطأ داخلي', 'route': None}

    # Build the prompt
    history_text = ''
    if conversation_history:
        # Last 10 messages to keep prompt manageable
        for msg in conversation_history[-10:]:
            role_label = 'العميل' if msg['role'] == 'user' else 'أنت'
            history_text += f"{role_label}: {msg['content']}\n"

    data_text = ''
    if customer_data:
        data_text = f"\n**معلومات مجمعة عن العميل حتى الآن:**\n{json.dumps(customer_data, ensure_ascii=False, indent=2)}\n"

    prompt = (
        f"{profile['system']}\n\n"
        f"{data_text}"
        f"**المحادثة حتى الآن:**\n{history_text}\n"
        f"**الرسالة الجديدة من العميل:** {user_message}\n\n"
        f"اكتب ردك (JSON فقط):"
    )

    raw = generate_text(prompt, max_tokens=500) or ''
    parsed = _extract_json(raw)

    if not parsed:
        # Fallback — if AI didn't return valid JSON
        fallback = {
            'khaled': {'route': 'khaled', 'reply': 'حضرتك تقدر تسألني عن العقارات أو فرص العمل.'},
            'yusuf':  {'handoff': False, 'reply': 'ممكن توضح أكتر يا فندم؟'},
            'sara':   {'qualified': None, 'reply': 'ممكن توضح أكتر؟'},
        }.get(bot_name, {'reply': 'مش فاهم، ممكن توضح؟'})
        return fallback

    return parsed


# ═══════════════════════════════════════════════════════════════
# Orchestrator: يدير المحادثة كاملة
# ═══════════════════════════════════════════════════════════════

def handle_incoming_message(supabase, whatsapp_number: str, message_text: str) -> dict:
    """
    نقطة الدخول الوحيدة — استقبال رسالة واتساب.

    يرجع dict فيه:
      - reply (str): الرد اللي يتبعت للمستخدم
      - handoff_to (UUID|None): لو لازم يحول لموظف بشري
      - notify (dict|None): إشعار يبعت لموظف
    """
    if not message_text or not whatsapp_number:
        return {'reply': '', 'handoff_to': None, 'notify': None}

    # 1. Get or create conversation
    conv = _get_or_create_conversation(supabase, whatsapp_number)
    if not conv:
        return {'reply': 'حصلت مشكلة، حاول كمان شوية.', 'handoff_to': None, 'notify': None}

    # If already handed off, don't bother the bot — let human handle
    if conv['state'] == 'handed_off':
        # Optionally relay message to the human via their notification feed
        _append_message(supabase, conv['id'], 'user', None, message_text)
        return {'reply': '', 'handoff_to': conv.get('handed_off_to'), 'notify': None}

    # 2. Save user message
    _append_message(supabase, conv['id'], 'user', None, message_text)

    # 3. Build history for AI
    history = _get_history(supabase, conv['id'])

    # 4. Call current bot
    current_bot = conv.get('current_bot', 'khaled')
    customer_data = conv.get('customer_data') or {}
    result = call_bot(current_bot, message_text, history, customer_data)

    reply_text = result.get('reply', '').strip()

    # 5. Handle bot decision
    notify = None
    handoff_to = None
    update_fields = {'last_message_at': datetime.utcnow().isoformat()}

    # ─── Khaled routes to another bot ───
    if current_bot == 'khaled':
        route = result.get('route', 'khaled')
        if route in ('yusuf', 'sara') and route != current_bot:
            update_fields['current_bot'] = route
            # The routing reply is from Khaled; the new bot will take over on next message

    # ─── Yusuf collects data + possibly hands off to human sales ───
    elif current_bot == 'yusuf':
        collected = result.get('collected') or {}
        if collected:
            customer_data.update(collected)
            update_fields['customer_data'] = customer_data
        if result.get('handoff'):
            summary = result.get('summary', '') or _build_summary(customer_data)
            # Pick a sales agent (round-robin or admin assigns)
            handoff_to = _pick_available_sales_agent(supabase)
            update_fields['state'] = 'handed_off'
            update_fields['handed_off_to'] = handoff_to
            update_fields['handed_off_at'] = datetime.utcnow().isoformat()
            update_fields['handoff_summary'] = summary
            # Create lead record so it shows in CRM
            _create_lead_from_bot(supabase, whatsapp_number, customer_data, handoff_to, summary)
            notify = {
                'type': 'sales_handoff',
                'employee_id': handoff_to,
                'title': '🤖 ليد جديد من البوت يوسف',
                'body': summary,
                'whatsapp_number': whatsapp_number,
            }

    # ─── Sara evaluates job applicant ───
    elif current_bot == 'sara':
        collected = result.get('collected') or {}
        if collected:
            customer_data.update(collected)
            update_fields['customer_data'] = customer_data
        qualified = result.get('qualified')
        if qualified is True:
            summary = result.get('summary', '') or _build_summary(customer_data)
            score = result.get('score', 75)
            # Find Omar (owner) — assume role='admin' or specific name
            omar_id = _find_omar(supabase)
            handoff_to = omar_id
            update_fields['state'] = 'handed_off'
            update_fields['handed_off_to'] = handoff_to
            update_fields['handed_off_at'] = datetime.utcnow().isoformat()
            update_fields['handoff_summary'] = summary
            # Save job application
            _create_job_application(supabase, whatsapp_number, customer_data, True, score, summary, omar_id)
            notify = {
                'type': 'hr_handoff',
                'employee_id': omar_id,
                'title': '🤖 متقدم وظيفة مناسب — من سارة',
                'body': summary,
                'whatsapp_number': whatsapp_number,
            }
        elif qualified is False:
            summary = result.get('summary', '') or 'غير مناسب'
            update_fields['state'] = 'rejected'
            _create_job_application(supabase, whatsapp_number, customer_data, False, 30, summary, None)

    # 6. Save bot reply + update conversation
    if reply_text:
        _append_message(supabase, conv['id'], 'bot', current_bot, reply_text)
    try:
        supabase.table('bot_conversations').update(update_fields).eq('id', conv['id']).execute()
    except Exception:
        pass

    return {
        'reply': reply_text,
        'handoff_to': handoff_to,
        'notify': notify,
    }


# ═══════════════════════════════════════════════════════════════
# Helpers (DB)
# ═══════════════════════════════════════════════════════════════

def _get_or_create_conversation(supabase, phone: str) -> Optional[dict]:
    try:
        r = supabase.table('bot_conversations').select('*').eq(
            'whatsapp_number', phone
        ).order('created_at', desc=True).limit(1).execute()
        if r.data:
            return r.data[0]
        # Create new
        new = supabase.table('bot_conversations').insert({
            'whatsapp_number': phone,
            'current_bot': 'khaled',
            'state': 'active',
        }).execute()
        return (new.data or [None])[0]
    except Exception as e:
        print('Bot conv error:', e)
        return None


def _append_message(supabase, conv_id: str, role: str, bot_name: Optional[str], content: str):
    try:
        supabase.table('bot_messages').insert({
            'conversation_id': conv_id,
            'role': role,
            'bot_name': bot_name,
            'content': content[:2000],
        }).execute()
    except Exception:
        pass


def _get_history(supabase, conv_id: str, limit: int = 20) -> list:
    try:
        r = supabase.table('bot_messages').select('role, content').eq(
            'conversation_id', conv_id
        ).order('created_at', desc=False).limit(limit).execute()
        return r.data or []
    except Exception:
        return []


def _build_summary(data: dict) -> str:
    parts = []
    label_map = {
        'name': 'الاسم', 'budget': 'الميزانية', 'location': 'المنطقة',
        'property_type': 'نوع العقار', 'purpose': 'الغرض', 'timeline': 'التايم لاين',
        'experience_years': 'سنوات الخبرة', 'expected_salary': 'الراتب المتوقع',
        'availability': 'التوافر', 'skills': 'المهارات', 'position': 'الوظيفة',
    }
    for k, v in data.items():
        label = label_map.get(k, k)
        parts.append(f'{label}: {v}')
    return ' | '.join(parts) if parts else 'لا توجد معلومات'


def _pick_available_sales_agent(supabase) -> Optional[str]:
    try:
        # Pick sales agent with fewest active leads (simple round-robin alternative)
        r = supabase.table('employees').select('id').eq(
            'role', 'sales_agent'
        ).eq('is_active', True).eq('is_locked', False).limit(10).execute()
        if r.data:
            import random
            return random.choice(r.data)['id']
    except Exception:
        pass
    return None


def _find_omar(supabase) -> Optional[str]:
    """Find Omar (or any admin) to receive HR handoffs."""
    try:
        # Try to find by name 'omar' first
        r = supabase.table('employees').select('id').ilike('full_name', '%omar%').limit(1).execute()
        if r.data:
            return r.data[0]['id']
        # Fallback: any admin
        r = supabase.table('employees').select('id').eq('role', 'admin').limit(1).execute()
        if r.data:
            return r.data[0]['id']
    except Exception:
        pass
    return None


def _create_lead_from_bot(supabase, phone: str, data: dict, assigned_to: Optional[str], summary: str):
    """Create a lead record in the CRM from a bot handoff."""
    try:
        row = {
            'name': data.get('name') or 'عميل من البوت',
            'phone': phone,
            'source': 'whatsapp_bot',
            'status': 'interested',
            'assigned_to': assigned_to,
            'notes': f'🤖 محادثة من بوت يوسف:\n{summary}',
        }
        if data.get('budget'):
            row['budget'] = data['budget']
        if data.get('location'):
            row['preferred_location'] = data['location']
        if data.get('property_type'):
            row['property_type'] = data['property_type']
        supabase.table('leads').insert(row).execute()
    except Exception as e:
        print('Create lead from bot error:', e)


def _create_job_application(supabase, phone: str, data: dict, qualified: bool,
                             score: int, summary: str, forwarded_to: Optional[str]):
    try:
        row = {
            'whatsapp_number': phone,
            'applicant_name': data.get('name') or 'متقدم',
            'experience_years': int(data.get('experience_years', 0)) if str(data.get('experience_years', '')).isdigit() else 0,
            'expected_salary': float(data.get('expected_salary', 0)) if str(data.get('expected_salary', '')).replace('.', '').isdigit() else None,
            'availability': data.get('availability'),
            'skills': data.get('skills'),
            'ai_evaluation': summary,
            'ai_score': score,
            'is_qualified': qualified,
            'status': 'qualified' if qualified else 'rejected',
            'forwarded_to': forwarded_to,
        }
        # Strip Nones
        row = {k: v for k, v in row.items() if v is not None}
        supabase.table('job_applications').insert(row).execute()
    except Exception as e:
        print('Create job app error:', e)
