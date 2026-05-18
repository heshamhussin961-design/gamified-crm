# AlSaeb CRM — Full Documentation

> **"Lead Hunter"** — نظام CRM ذكي بيحول شغل المبيعات لعبة RPG بـ XP، مستويات، عملات، مهام، متجر، ليدربورد، ومسابقات.

---

## Table of Contents

1. [نظرة عامة (Overview)](#overview)
2. [المتطلبات (Requirements)](#requirements)
3. [التثبيت والتشغيل (Setup & Run)](#setup)
4. [البنية المعمارية (Architecture)](#architecture)
5. [قاعدة البيانات (Database)](#database)
6. [الـ API Endpoints](#api-endpoints)
7. [الواجهات (Frontends)](#frontends)
8. [نظام اللعب (Gamification)](#gamification)
9. [إدارة الليدز (Lead Management)](#leads)
10. [الإعلانات والويب هوك (Ads & Webhooks)](#ads-webhooks)
11. [WhatsApp Integration](#whatsapp)
12. [AI Analysis](#ai)
13. [Professional Mode](#professional-mode)
14. [الصلاحيات والأمان (Auth & RBAC)](#auth)
15. [النشر (Deployment)](#deployment)
16. [الاختبارات (Testing)](#testing)
17. [المتغيرات البيئية (Environment Variables)](#env-vars)
18. [دليل الاستخدام (User Guide)](#user-guide)
19. [FAQ](#faq)

---

<a name="overview"></a>
## 1. نظرة عامة (Overview)

**AlSaeb CRM** هو نظام إدارة علاقات عملاء (CRM) مصمم لفرق المبيعات العقارية في الإمارات. الفكرة إنه بيحول كل أكشن بيعمله الموظف (رسالة واتساب، مكالمة، اجتماع، صفقة) لـ XP ونقاط في لعبة RPG.

### المكونات الأساسية

| المكون | الوصف |
|--------|-------|
| **Flask Backend** | سيرفر واحد (`app.py`) فيه ~163 route |
| **Supabase** | قاعدة بيانات PostgreSQL + Auth + RLS |
| **Admin Panel** | لوحة تحكم كاملة للأدمن |
| **Agent App** | تطبيق PWA للموظفين (موبايل) |
| **2D Game** | لعبة مكتب 2D بـ Phaser 3 |
| **Journey Map** | خريطة مدينة cyberpunk بـ SVG |
| **WhatsApp** | ربط مع Meta WhatsApp Business API |
| **AI Analysis** | تحليل ذكي للليدز بـ Claude/OpenAI |
| **Ad Webhooks** | استقبال ليدز تلقائي من Facebook/Google Ads |

### التقنيات المستخدمة

```
Backend:   Python 3.11+ / Flask / Gunicorn
Database:  Supabase (PostgreSQL + Auth + RLS + RPCs)
Frontend:  Vanilla JS + Tailwind CSS CDN + Supabase JS SDK
Game:      Phaser 3 CDN
AI:        Claude (Anthropic) / OpenAI GPT
Messaging: Meta WhatsApp Business API
Payments:  Stripe (optional)
Deploy:    Docker / Railway / Render / Heroku
```

> **مفيش build step** — كل الفرونت إند vanilla JS + CDN.

---

<a name="requirements"></a>
## 2. المتطلبات (Requirements)

### System Requirements
- Python 3.11+
- pip package manager
- Supabase project (free tier كافي للتجربة)

### Python Packages

```
flask==3.1.1              # Web framework
flask-cors==5.0.1         # CORS
supabase==2.13.0          # Supabase client
python-dotenv==1.1.0      # .env loader
openpyxl==3.1.5           # Excel parsing
requests==2.32.3          # HTTP client
gunicorn==23.0.0          # Production server
anthropic==0.40.0          # Claude AI (optional)
openai==1.54.0             # OpenAI (optional)
stripe==11.4.1             # Billing (optional)
pytest==8.3.3              # Testing
ruff==0.7.4                # Linting
```

### External Services (Optional)
- **WhatsApp Business API** — لإرسال/استقبال رسائل
- **Anthropic/OpenAI API** — لتحليل الليدز بالذكاء الاصطناعي
- **Stripe** — للفوترة والاشتراكات
- **Facebook Developer App** — لاستقبال ليدز Facebook Lead Ads
- **SMTP Server** — لإشعارات الإيميل

---

<a name="setup"></a>
## 3. التثبيت والتشغيل (Setup & Run)

### الخطوة 1: Clone + Install

```bash
git clone <repo-url>
cd Gamified-CRM

# إنشاء بيئة افتراضية (مستحسن)
python -m venv .venv
source .venv/bin/activate   # Linux/Mac
.venv\Scripts\activate      # Windows

# تثبيت المتطلبات
pip install -r requirements.txt
```

### الخطوة 2: إعداد Supabase

1. أنشئ مشروع على [supabase.com](https://supabase.com)
2. روح على **SQL Editor** وشغّل:
   ```sql
   -- أول مرة:
   -- شغّل schema_complete.sql (ملف واحد فيه كل الجداول + الدوال)
   
   -- لو عايز بيانات تجريبية:
   -- شغّل seed_demo.sql بعد الـ schema
   
   -- لو عايز تعمل reset:
   -- شغّل schema_DROP_ALL.sql الأول، بعدين schema_complete.sql
   ```
3. من **Project Settings → API** انسخ:
   - `Project URL` → `SUPABASE_URL`
   - `anon public key` → `SUPABASE_ANON_KEY`
   - `service_role secret` → `SUPABASE_SERVICE_KEY`

### الخطوة 3: ملف البيئة (.env)

```bash
cp env.example .env
# عدّل القيم في .env
```

الحد الأدنى المطلوب:
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
SUPABASE_SERVICE_KEY=eyJhbGci...
SECRET_KEY=any_random_string
```

### الخطوة 4: التشغيل

```bash
# Development
python app.py
# → http://localhost:5000

# Production (Docker)
docker compose up --build
# → http://localhost:5000
```

### الروابط بعد التشغيل

| الرابط | الوصف |
|--------|-------|
| `http://localhost:5000/admin` | لوحة تحكم الأدمن |
| `http://localhost:5000/agent` | تطبيق الموظف (PWA) |
| `http://localhost:5000/game` | لعبة المكتب 2D |
| `http://localhost:5000/map` | خريطة الرحلة |
| `http://localhost:5000/api/health` | Health check |
| `http://localhost:5000/api/config` | Public config (anon key) |

---

<a name="architecture"></a>
## 4. البنية المعمارية (Architecture)

### ملف واحد — `app.py`

المشروع عن عمد في ملف واحد (~4800 سطر) منظم بـ banners:

```
# ==================== SECTION NAME ====================
```

**الأقسام الرئيسية:**

| القسم | الوصف |
|-------|-------|
| Config & Helpers | Supabase client, GPS, SMTP, webhooks |
| Auth & RBAC | `require_auth`, `check_role`, `audit_log`, `rate_limit` |
| Leads Endpoints | CRUD + search + assignment + locking |
| Actions & XP | WhatsApp, calls, meetings, deals → XP/coins |
| Quests | Daily quests + progress tracking |
| Leaderboard | XP-based ranking + refresh |
| Store | Cosmetics shop with syb-coins |
| Competitions | Timed events with prizes |
| Listings | Property listings management |
| Squads | Team alliances |
| Story Mode | 20-chapter progression |
| Break Room | Stamina regen + mini-games |
| CEO Visits | Boss events + power hours |
| Multiplayer | Real-time positions (2D game) |
| Billing | Stripe integration |
| Ad Campaigns | CRUD + dashboard + webhooks |
| Webhook Ingestion | Facebook Lead Ads + generic webhook |

### Auth Flow

```
Browser → Supabase Auth (JWT) → Flask API (verify JWT)
                                    ↓
                              @require_auth → request.user_id
                              @check_role(['admin']) → role check
                              @audit_log('action') → logging
                              @rate_limit('key', 30) → throttle
```

### Data Flow

```
Ad Platform → Webhook → /webhook/lead/<id>?key=XXX → Supabase (leads table)
                                                         ↓
                                                   auto_assign → agent
                                                         ↓
Agent App → /api/leads → see assigned leads
         → /api/actions/whatsapp → send message → +10 XP
         → /api/actions/call → log call → +15 XP
         → /api/actions/deal → close deal → +500 XP, +50 coins
                                                         ↓
                                               award_xp_and_coins RPC
                                                         ↓
                                               Level up? → title change
                                               Quest progress? → reward
```

---

<a name="database"></a>
## 5. قاعدة البيانات (Database)

### الجداول الرئيسية (30+ جدول)

| الجدول | الوصف |
|--------|-------|
| `employees` | الموظفين (XP, level, coins, role, title, professional_mode) |
| `leads` | الليدز (phone, status, quality, assigned_to, ad_campaign_id, UTM) |
| `actions_log` | سجل كل الأكشنز (action, xp_earned, coins_earned) |
| `projects` | المشاريع العقارية |
| `teams` | الفرق |
| `quests` | المهام اليومية |
| `quest_progress` | تقدم المهام |
| `badges` | الشارات المتاحة |
| `employee_badges` | شارات الموظفين |
| `competitions` | المسابقات المؤقتة |
| `competition_participants` | مشاركي المسابقات |
| `leaderboard_cache` | كاش الترتيب |
| `store_items` | عناصر المتجر |
| `employee_inventory` | مشتريات الموظفين |
| `ad_campaigns` | الحملات الإعلانية (webhook_key, facebook_page_id, auto_assign) |
| `listings` | العقارات المعروضة |
| `lead_locks` | أقفال الليدز (pessimistic locking) |
| `lead_status_history` | تاريخ تغيير حالة الليد |
| `power_hours` | ساعات القوة (XP multiplier) |
| `activity_feed` | نشاط اجتماعي |
| `admin_audit_log` | سجل تدقيق الأدمن |
| `webhooks` | Outbound webhooks configuration |
| `squads` | التحالفات |

### الدوال المهمة (RPCs)

| الدالة | الوصف | متى تستخدمها |
|--------|-------|-------------|
| `award_xp_and_coins` | **المسار الوحيد** لتعديل XP/coins/level | كل ما موظف يعمل أكشن |
| `change_lead_status` | تغيير حالة الليد مع validation | نقل الليد في الـ pipeline |
| `distribute_leads_to_agents` | توزيع ليدز round-robin | توزيع bulk |
| `acquire_lead_lock` / `release_lead_lock` | قفل/فتح ليد | منع تعارض التعديل |
| `increment_employee_counter` | زيادة عداد atomic | `total_messages`, `total_calls` |
| `drain_stamina` / `regen_stamina` | نظام الطاقة | كل أكشن بيستهلك stamina |
| `generate_daily_quests` | توليد مهام يومية | بداية كل يوم |
| `progress_matching_quests` | تقدم المهام (trigger) | تلقائي بعد أكشنز |
| `purchase_store_item` | شراء من المتجر | الموظف يشتري cosmetic |
| `claim_hot_lead` | مسك ليد ساخن (race-safe) | Hot Lead event |
| `generate_daily_highlights` | ملخص يومي سينمائي | نهاية اليوم |
| `has_permission` | فحص صلاحية | RBAC checks |

### نظام المستويات والألقاب

```
Level 1-4   → "Junior Scraper"    (0 - 4,000 XP)
Level 5-9   → "Lead Hunter"       (4,000 - 9,000 XP)
Level 10-14 → "Elite Hunter"      (9,000 - 15,000 XP)
Level 15-24 → "Sales Boss"        (15,000+ XP)
Level 25+   → "Legend"
```

**حساب المستوى:**
- أقل من 15,000 XP: `level = (total_xp / 1000) + 1`
- 15,000+ XP: `level = 15 + floor(sqrt((total_xp - 15000) / 1500))`

---

<a name="api-endpoints"></a>
## 6. الـ API Endpoints

### Authentication Headers

كل الـ endpoints المحمية بتحتاج:
```
Authorization: Bearer <supabase_jwt_token>
```

### الليدز (Leads)

| Method | Endpoint | Auth | الوصف |
|--------|----------|------|-------|
| GET | `/api/leads` | auth | جيب الليدز (فلتر بـ status, quality, search, ad_campaign_id) |
| GET | `/api/leads/<id>` | auth | تفاصيل ليد واحد |
| POST | `/api/leads` | admin/manager | إنشاء ليد جديد |
| PATCH | `/api/leads/<id>/status` | auth | تغيير حالة الليد |
| PATCH | `/api/leads/<id>/link-ad` | admin/manager | ربط ليد بإعلان |
| POST | `/api/leads/bulk-assign` | admin | توزيع bulk |
| POST | `/api/leads/<id>/lock` | auth | قفل ليد |
| DELETE | `/api/leads/<id>/lock` | auth | فتح قفل ليد |
| GET | `/api/leads/<id>/notes` | auth | ملاحظات الليد |
| POST | `/api/leads/<id>/notes` | auth | إضافة ملاحظة |
| GET | `/api/leads/<id>/history` | auth | تاريخ الليد |
| POST | `/api/leads/<id>/assign` | admin | تخصيص ليد لموظف |

### الأكشنز (Actions) — كل أكشن بيدي XP

| Method | Endpoint | XP | Coins | الوصف |
|--------|----------|-----|-------|-------|
| POST | `/api/actions/whatsapp` | +10 | — | إرسال رسالة واتساب |
| POST | `/api/actions/whatsapp-received` | +50 | — | استقبال رد |
| POST | `/api/actions/call` | +15 | — | تسجيل مكالمة |
| POST | `/api/actions/call-received` | +30 | — | استقبال مكالمة |
| POST | `/api/actions/meeting` | +200 | +20 | حجز اجتماع |
| POST | `/api/actions/deal` | +500 | +50 | إغلاق صفقة |
| POST | `/api/actions/note` | +5 | — | إضافة ملاحظة |

### اللعب (Gamification)

| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/api/quests` | المهام اليومية |
| POST | `/api/quests/<id>/claim` | استلام مكافأة مهمة |
| GET | `/api/leaderboard` | الترتيب |
| GET | `/api/badges` | الشارات |
| GET | `/api/store` | عناصر المتجر |
| POST | `/api/store/<id>/buy` | شراء عنصر |
| GET | `/api/competitions` | المسابقات النشطة |
| POST | `/api/competitions/<id>/join` | الانضمام لمسابقة |

### الإعلانات (Ad Campaigns)

| Method | Endpoint | Auth | الوصف |
|--------|----------|------|-------|
| GET | `/api/admin/ads` | admin/manager | كل الحملات |
| POST | `/api/admin/ads` | admin/manager | إنشاء حملة |
| GET | `/api/admin/ads/<id>` | admin/manager | تفاصيل حملة |
| PATCH | `/api/admin/ads/<id>` | admin/manager | تعديل حملة |
| DELETE | `/api/admin/ads/<id>` | admin/manager | حذف حملة |
| GET | `/api/admin/ads/dashboard` | admin/manager | داشبورد الإعلانات |
| POST | `/api/admin/ads/<id>/update-stats` | admin/manager | تحديث إحصائيات |
| POST | `/api/admin/ads/<id>/webhook` | admin/manager | توليد مفتاح webhook |
| GET | `/api/admin/ads/<id>/webhook` | admin/manager | عرض بيانات webhook |
| PATCH | `/api/admin/ads/<id>/webhook` | admin/manager | تحديث إعدادات webhook |

### Webhook Ingestion (بدون auth — API key)

| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/webhook/facebook` | Facebook verification |
| POST | `/webhook/facebook` | استقبال ليدز Facebook Lead Ads |
| POST | `/webhook/lead/<campaign_id>?key=XXX` | Generic webhook (أي منصة) |

### إدارة الموظفين (Admin)

| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/api/admin/employees` | قائمة الموظفين |
| PATCH | `/api/admin/employees/<id>` | تعديل موظف (role, professional_mode, title) |
| GET | `/api/me` | بيانات المستخدم الحالي |
| PATCH | `/api/me/mode` | تبديل الوضع المهني/اللعب |

---

<a name="frontends"></a>
## 7. الواجهات (Frontends)

### Admin Panel (`/admin`)

لوحة تحكم كاملة فيها:

- **📋 الليدز** — جدول + فلاتر + بحث (اسم، موبايل، إيميل، AI Summary) + pagination
- **👥 الفريق** — إدارة الموظفين + تبديل الأدوار + تبديل Professional Mode + تقارير PDF
- **📊 التقارير** — تقرير AI أسبوعي + إحصائيات
- **🏗️ المشاريع** — إدارة المشاريع العقارية
- **📢 الإعلانات** — حملات إعلانية CRUD + داشبورد + webhook management
- **🏆 المسابقات** — إنشاء/إدارة المسابقات
- **🛒 المتجر** — إدارة عناصر المتجر
- **📝 القوالب** — قوالب رسائل واتساب
- **🏢 العقارات** — إدارة الـ listings
- **📊 Audit Log** — سجل كل العمليات

### Agent App (`/agent`) — PWA

تطبيق موبايل للموظفين:

- **الداشبورد** — إحصائيات يومية + XP bar + coins + مستوى + streaks
- **📱 الليدز** — الليدز المخصصة + تفاصيل + أكشنز (اتصال، رسالة، اجتماع، صفقة)
- **🎯 المهام** — مهام يومية + تقدم + مكافآت
- **🏆 الليدربورد** — الترتيب مع الزملاء
- **🛒 المتجر** — شراء cosmetics بالعملات
- **🗺️ الخريطة** — رحلة cyberpunk city
- **🎮 اللعبة** — لعبة المكتب 2D
- **⚙️ الإعدادات** — Professional Mode toggle + حساب + صوت

**يدعم التثبيت كتطبيق** (Add to Home Screen) على iOS و Android.

### 2D Office Game (`/game`)

لعبة Phaser 3 فيها:
- حركة grid-based + D-pad للموبايل
- CRM modal (نفس أكشنز الليدز)
- Stamina system + break room
- Multiplayer (شوف زملائك بيتحركوا)
- Badges + Hot Leads events + High Fives
- CEO Boss Visits + Power Hours
- Cosmetics shop
- Daily Highlights cinematic

### Journey Map (`/map`)

خريطة SVG لمدينة cyberpunk:
- 20 landmark building (كل واحد = chapter في الستوري)
- عربية بتتحرك حسب تقدم XP
- Fog of war (المناطق اللي ما وصلتهاش مخفية)
- Neon city aesthetics + stars + street lamps

---

<a name="gamification"></a>
## 8. نظام اللعب (Gamification)

### XP (نقاط الخبرة)

| الأكشن | XP | Coins |
|--------|-----|-------|
| إرسال واتساب | +10 | — |
| استقبال رد واتساب | +50 | — |
| مكالمة صادرة | +15 | — |
| مكالمة واردة | +30 | — |
| حجز اجتماع | +200 | +20 |
| إغلاق صفقة | +500 | +50 |
| ملاحظة | +5 | — |
| ترقية ليد | +25 | +5 |

> **Power Hour**: في أوقات معينة، الـ XP بيتضاعف (multiplier 1.5x - 3x).

### Syb Coins (العملة)

بتتكسب من الصفقات والمهام والمسابقات. بتتصرف في **المتجر** على:
- Cosmetics (skins, badges, titles)
- Power-ups
- عناصر خاصة

### المهام اليومية (Quests)

بيتولدوا تلقائي كل يوم. أمثلة:
- "ابعت 5 رسائل واتساب" → +100 XP
- "اعمل 3 مكالمات" → +50 XP
- "اقفل صفقة واحدة" → +200 XP, +30 coins

### الشارات (Badges)

بتتفتح تلقائي لما تحقق إنجازات:
- "First Blood" — أول صفقة
- "Message Master" — 100 رسالة
- "Call King" — 50 مكالمة
- وغيرهم

### الليدربورد (Leaderboard)

ترتيب أسبوعي/شهري حسب XP. بيتحدث كل ساعة عبر `refresh_leaderboard` RPC.

### المسابقات (Competitions)

الأدمن يقدر ينشئ مسابقات مؤقتة:
- مدة محددة (يوم، أسبوع، شهر)
- هدف محدد (أكتر مكالمات، أكتر صفقات)
- جوائز XP + coins للفائز

### Stamina (الطاقة)

- كل أكشن بيستهلك طاقة
- الطاقة بتتجدد في **Break Room**
- لما الطاقة تخلص، لازم تستريح

---

<a name="leads"></a>
## 9. إدارة الليدز (Lead Management)

### حالات الليد (Pipeline)

```
new → contacted → interested → meeting_booked → negotiation → closed_won
                                                             → closed_lost
                                              → not_interested
```

التغيير بيمر عبر `change_lead_status` RPC اللي بيتأكد إن الانتقال صحيح.

### جودة الليد (Quality)

| الجودة | الوصف |
|--------|-------|
| `unknown` | جديد — مش معروف |
| `cold` | بارد — مفيش تفاعل |
| `warm` | دافئ — فيه اهتمام |
| `hot` | ساخن — جاهز للشراء |
| `vip` | VIP — عميل مميز |

### Lead Locking

نظام pessimistic locking مع TTL:
- لما موظف يفتح ليد، بياخد lock
- مفيش حد تاني يقدر يعدل نفس الليد
- الـ lock بيتفك تلقائي بعد وقت معين

### توزيع الليدز

**يدوي**: الأدمن يخصص ليد لموظف معين.

**Round-robin**: `distribute_leads_to_agents` بيوزع تلقائي بالتساوي.

**من الويب هوك**: لو `auto_assign = true`، الليدز الجديدة بتتوزع تلقائي.

---

<a name="ads-webhooks"></a>
## 10. الإعلانات والويب هوك (Ads & Webhooks)

### إنشاء حملة إعلانية

1. ادخل `/admin` → **📢 الإعلانات** → **+ إعلان جديد**
2. حدد: الاسم، المنصة، الميزانية، UTM tags، التواريخ
3. اضغط **حفظ**

### المنصات المدعومة

Facebook, Google Ads, Instagram, TikTok, Snapchat, Twitter/X, LinkedIn, YouTube, SMS, Email, أخرى

### ربط الليدز بالإعلانات (3 طرق)

#### الطريقة 1: Generic Webhook (أي منصة)

1. من الإعلان → اضغط **🔗** → **توليد المفتاح**
2. انسخ الـ Webhook URL
3. حطه في Zapier / Make / Google Ads / أي منصة

```bash
# مثال: إرسال ليد واحد
curl -X POST "https://your-domain.com/webhook/lead/CAMPAIGN_UUID?key=YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0501234567",
    "name": "أحمد محمد",
    "email": "ahmed@example.com"
  }'

# مثال: إرسال مصفوفة ليدز
curl -X POST "https://your-domain.com/webhook/lead/CAMPAIGN_UUID?key=YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '[
    {"phone": "050111", "name": "Ali"},
    {"phone": "050222", "name": "Omar"}
  ]'
```

**الحقول المقبولة:**

| الحقل | مطلوب | الوصف |
|-------|-------|-------|
| `phone` | نعم | رقم التليفون |
| `name` | لا | الاسم |
| `email` | لا | الإيميل |
| `source` | لا | المصدر (default: webhook) |
| `quality` | لا | الجودة (default: unknown) |
| `notes` | لا | ملاحظات |
| `project_id` | لا | UUID المشروع |
| `utm_source` | لا | يستخدم UTM الحملة لو مش محدد |
| `utm_medium` | لا | يستخدم UTM الحملة لو مش محدد |
| `utm_campaign` | لا | يستخدم UTM الحملة لو مش محدد |

#### الطريقة 2: Facebook Lead Ads

1. أنشئ **Facebook Developer App** على [developers.facebook.com](https://developers.facebook.com)
2. فعّل **Webhooks** product
3. أضف webhook:
   - **Callback URL**: `https://your-domain.com/webhook/facebook`
   - **Verify Token**: `alsaeb_crm_verify` (أو اللي في `FB_VERIFY_TOKEN`)
   - **اشترك في**: `leadgen` field
4. في الأدمن → الإعلان → **🔗** → حط **Facebook Page ID** + **Form ID** (اختياري)
5. أضف في `.env`:
   ```env
   FB_VERIFY_TOKEN=alsaeb_crm_verify
   FB_APP_SECRET=your_app_secret
   FB_PAGE_ACCESS_TOKEN=your_page_token
   ```

**الفلو:**
```
User fills Facebook Lead Form
  → Facebook sends POST to /webhook/facebook
    → CRM matches page_id + form_id to campaign
      → Fetches lead details from Graph API
        → Creates lead in DB + links to campaign
          → Auto-assign (if enabled)
```

#### الطريقة 3: Excel Import

```bash
python import_leads.py \
  --file leads.xlsx \
  --ad-campaign-id "UUID_HERE" \
  --utm-source facebook \
  --utm-medium paid \
  --utm-campaign "dubai_villas" \
  --supabase-url $SUPABASE_URL \
  --supabase-key $SUPABASE_SERVICE_KEY
```

أو بدون Supabase (تصدير SQL/JSON):
```bash
python import_leads.py --file leads.xlsx --output-sql
python import_leads.py --file leads.xlsx --output-json
```

### التوزيع التلقائي (Auto-Assign)

من إعدادات الويب هوك (🔗) → فعّل **"توزيع تلقائي"**:
- كل ليد جديد من الويب هوك بيتوزع على أول agent نشط (round-robin)
- بيتتبع `last_lead_assigned_at` عشان التوزيع يبقى عادل

### داشبورد الإعلانات

من **📢 الإعلانات → 📊 الداشبورد**:
- إجمالي الحملات
- المصروف الكلي
- عدد الليدز
- CPL (تكلفة الليد = المصروف / عدد الليدز)
- معدل التحويل (Conversion Rate)
- تقسيم حسب المنصة والحالة

---

<a name="whatsapp"></a>
## 11. WhatsApp Integration

### الإعداد

1. أنشئ **WhatsApp Business Account** على [business.facebook.com](https://business.facebook.com)
2. أضف في `.env`:
   ```env
   WHATSAPP_API_URL=https://graph.facebook.com/v18.0
   WHATSAPP_PHONE_ID=your_phone_number_id
   WHATSAPP_TOKEN=your_access_token
   ```

### الاستخدام

- **من Agent App**: افتح ليد → اضغط "واتساب" → اختر قالب أو اكتب رسالة
- **من API**: `POST /api/actions/whatsapp` مع `{lead_id, message}`

> كل الدوال في `whatsapp_client.py` بتفشل بهدوء (graceful fail) لو مفيش credentials. مش محتاج تعمل if checks.

---

<a name="ai"></a>
## 12. AI Analysis

### الإعداد

أضف أحد المفاتيح في `.env`:
```env
# الأولوية: Anthropic أولاً، بعدين OpenAI، بعدين fallback
ANTHROPIC_API_KEY=sk-ant-...    # Claude (الافتراضي: claude-haiku-4-5-20251001)
OPENAI_API_KEY=sk-...            # GPT (الافتراضي: gpt-4o-mini)
```

### الاستخدام

`ai_client.analyze_lead(lead, messages)` بيرجع:
```json
{
  "suggestion": "نص اقتراح الخطوة التالية",
  "lead_score": 75,
  "sentiment": "positive",
  "recommended_action": "schedule_meeting",
  "recommended_template": "follow_up_interested"
}
```

- بيشتغل تلقائي لما الموظف يفتح تفاصيل ليد في الـ Agent App
- لو مفيش API keys، بيستخدم heuristic fallback بسيط

---

<a name="professional-mode"></a>
## 13. Professional Mode

### الفكرة

لو الموظف مش عايز يلعب، يقدر يفعّل **الوضع المهني (💼)** اللي بيخفي كل عناصر اللعب:

| يتخفي | يفضل ظاهر |
|--------|-----------|
| XP bar + level | الليدز + تفاصيلها |
| Coins | المكالمات + الرسائل |
| Quests | الاجتماعات + الصفقات |
| Badges | الملاحظات |
| Leaderboard | الحضور |
| Store | الإعدادات |
| Game + Map tabs | — |
| Streaks + confetti | — |

### التفعيل

**من الموظف**: Agent App → ⚙️ الإعدادات → اختر 💼 احترافي

**من الأدمن**: Admin → الفريق → اضغط 💼/🎮 جنب الموظف

### API

```bash
# الموظف يبدل الوضع
PATCH /api/me/mode
Body: {"professional_mode": true}

# الأدمن يبدل وضع موظف
PATCH /api/admin/employees/<user_id>
Body: {"professional_mode": true}
```

> في الوضع المهني، الأكشنز لسه بتسجل XP في الخلفية — بس الموظف مش بيشوف التنبيهات.

---

<a name="auth"></a>
## 14. الصلاحيات والأمان (Auth & RBAC)

### الأدوار (Roles)

| الدور | الصلاحيات |
|-------|----------|
| `admin` | كل شيء — إدارة موظفين، مشاريع، إعلانات، مسابقات، audit log |
| `manager` | إدارة الليدز + التوزيع + الإعلانات + التقارير |
| `agent` | الليدز المخصصة + الأكشنز + اللعب |

### Decorators

```python
@require_auth          # JWT verification → request.user_id
@check_role(['admin']) # role check (includes @require_auth)
@audit_log('action')   # logs to admin_audit_log
@rate_limit('key', 30) # max 30 requests/minute
```

### Row Level Security (RLS)

Supabase RLS policies تضمن:
- الموظف يشوف بياناته بس
- الأدمن يشوف الكل
- الـ anon key محدود بـ SELECT فقط على جداول معينة

### Webhook Security

- **Facebook**: HMAC-SHA256 signature verification عبر `X-Hub-Signature-256`
- **Generic**: API key per campaign عبر `?key=` parameter
- **Outbound**: HMAC-SHA256 signing عبر `X-AlSaeb-Signature`

---

<a name="deployment"></a>
## 15. النشر (Deployment)

### Docker (Recommended)

```bash
docker compose up --build
```

الـ container بيشتغل بـ:
- Gunicorn: 4 workers × 8 threads
- Non-root user
- Healthcheck: `/api/config` كل 30 ثانية
- Log rotation: 10MB × 3 files

### Railway

```bash
# railway.toml موجود — just push
railway up
```

### Render

```bash
# render.yaml موجود — connect repo on render.com
```

### Heroku

```bash
# Procfile موجود
heroku create
git push heroku main
```

### Environment Variables (Production)

لازم تضبط كل المتغيرات في `.env` على المنصة المختارة. أهمهم:
```
SUPABASE_URL, SUPABASE_SERVICE_KEY, SUPABASE_ANON_KEY, SECRET_KEY
```

---

<a name="testing"></a>
## 16. الاختبارات (Testing)

### تشغيل الاختبارات

```bash
# كل الاختبارات
pytest

# ملف واحد
pytest tests/test_phase9.py

# اختبار بالاسم
pytest -k "permissions"

# مع تفاصيل
pytest -v --tb=long
```

### البنية

```
tests/
├── conftest.py              # FakeSupabase fixture + auth mocks
├── test_ai_client.py        # AI integration
├── test_game_endpoints.py   # Game APIs
├── test_phase9.py           # Feature tests
├── test_v2_features.py      # V2 features
└── test_whatsapp_client.py  # WhatsApp API
```

> كل الاختبارات بتستخدم **FakeSupabase** — مفيش اختبار بيضرب الشبكة.

### Lint

```bash
ruff check .           # lint
ruff check --fix .     # auto-fix
ruff format --check .  # format check
```

### CI/CD

GitHub Actions بيشغل تلقائي على كل push/PR:
1. Ruff lint + format
2. Pytest (Python 3.11 + 3.12)
3. Docker build

---

<a name="env-vars"></a>
## 17. المتغيرات البيئية (Environment Variables)

| المتغير | مطلوب | الوصف |
|---------|-------|-------|
| `SUPABASE_URL` | نعم | رابط مشروع Supabase |
| `SUPABASE_SERVICE_KEY` | نعم | Service role key (backend) |
| `SUPABASE_ANON_KEY` | نعم | Anon key (browser) |
| `SECRET_KEY` | نعم | Flask secret |
| `WHATSAPP_API_URL` | لا | Meta Graph API URL |
| `WHATSAPP_PHONE_ID` | لا | WhatsApp phone number ID |
| `WHATSAPP_TOKEN` | لا | WhatsApp access token |
| `ANTHROPIC_API_KEY` | لا | Claude API key |
| `OPENAI_API_KEY` | لا | OpenAI API key |
| `STRIPE_SECRET_KEY` | لا | Stripe secret key |
| `STRIPE_WEBHOOK_SECRET` | لا | Stripe webhook secret |
| `FB_VERIFY_TOKEN` | لا | Facebook webhook verify token (default: alsaeb_crm_verify) |
| `FB_APP_SECRET` | لا | Facebook app secret (signature verification) |
| `FB_PAGE_ACCESS_TOKEN` | لا | Facebook page token (fetch lead data) |
| `OFFICE_LAT` | لا | خط عرض المكتب (GPS attendance) |
| `OFFICE_LNG` | لا | خط طول المكتب |
| `OFFICE_RADIUS_METERS` | لا | نطاق GPS (default: 200m) |
| `REQUIRE_GPS_CHECKIN` | لا | فرض GPS للحضور (default: false) |
| `SMTP_HOST` | لا | SMTP server |
| `SMTP_PORT` | لا | SMTP port (default: 587) |
| `SMTP_USER` | لا | SMTP username |
| `SMTP_PASS` | لا | SMTP password |
| `SMTP_FROM` | لا | From address |

> كل الخدمات الاختيارية بتفشل بهدوء (graceful fail) لو مفيش credentials.

---

<a name="user-guide"></a>
## 18. دليل الاستخدام (User Guide)

### للأدمن — إعداد النظام لأول مرة

1. **إنشاء حساب Supabase** وتشغيل `schema_complete.sql`
2. **تشغيل السيرفر** (`python app.py` أو Docker)
3. **إنشاء حسابات الموظفين** من Supabase Auth (أو من الواجهة)
4. **إضافة المشاريع** من `/admin` → المشاريع
5. **استيراد الليدز**: 
   - Excel: `python import_leads.py --file leads.xlsx --supabase-url ... --supabase-key ...`
   - يدوي: من الأدمن → الليدز → + ليد جديد
6. **إنشاء حملات إعلانية** وربط الويب هوك
7. **توزيع الليدز** على الموظفين (يدوي أو round-robin)
8. **إنشاء مسابقات** لتحفيز الفريق

### للأدمن — العمليات اليومية

| المهمة | الطريقة |
|--------|---------|
| متابعة الأداء | الليدربورد + تقرير AI |
| توزيع ليدز جديدة | الليدز → توزيع bulk أو تخصيص يدوي |
| إنشاء مسابقة | المسابقات → + مسابقة جديدة |
| تحديث إحصائيات الإعلان | الإعلانات → 📊 |
| مراجعة Audit Log | الإعدادات → سجل العمليات |
| تبديل وضع موظف | الفريق → 💼/🎮 |

### للموظف (Agent) — الشغل اليومي

1. **افتح** `/agent` أو التطبيق المثبت
2. **سجل دخول** بحسابك
3. **شوف الليدز** المخصصة ليك في قسم "الليدز"
4. **افتح ليد** → شوف التفاصيل + AI suggestion
5. **اعمل أكشن**:
   - 📞 اتصال → سجل المكالمة → +15 XP
   - 💬 واتساب → ابعت رسالة → +10 XP
   - 📅 اجتماع → حجز اجتماع → +200 XP, +20 coin
   - 🤝 صفقة → اقفل الصفقة → +500 XP, +50 coin
6. **تابع المهام اليومية** → حقق الهدف → استلم المكافأة
7. **اشتري من المتجر** بالعملات
8. **العب اللعبة** أو **تابع الخريطة** لو حابب

### للموظف — Professional Mode

لو مش عايز تشوف عناصر اللعب:
1. اضغط ⚙️ (الإعدادات)
2. اختر 💼 **احترافي**
3. هتختفي كل عناصر اللعب وتفضل واجهة CRM نظيفة

---

<a name="faq"></a>
## 19. FAQ

### س: إزاي أعمل reset للداتابيز؟
```sql
-- شغّل في Supabase SQL Editor:
-- 1. أولاً:
\i schema_DROP_ALL.sql
-- 2. بعدين:
\i schema_complete.sql
-- 3. (اختياري) بيانات تجريبية:
\i seed_demo.sql
```

### س: إزاي أضيف موظف جديد؟
1. أنشئ user في Supabase Auth (Dashboard → Authentication → Users → Invite)
2. أضف record في `employees` table بنفس الـ `id`

### س: إزاي أغير role موظف؟
من الأدمن: الفريق → اضغط على الموظف → غيّر الدور
أو: `PATCH /api/admin/employees/<id>` مع `{"role": "manager"}`

### س: الـ XP مش بيتحسب صح؟
**لازم** تستخدم `award_xp_and_coins` RPC. أي `UPDATE employees SET total_xp = ...` مباشر هيكسر النظام.

### س: إزاي أربط Google Ads؟
1. أنشئ حملة في الأدمن
2. ولّد webhook key (🔗)
3. في Google Ads: استخدم **Lead Form Extension** → **Webhook Integration** → حط الـ URL
4. أو استخدم **Zapier/Make**: Google Ads → Webhook → الـ URL بتاعك

### س: إزاي أربط Zapier/Make؟
1. ولّد webhook URL من الأدمن
2. في Zapier: New Zap → Trigger (أي trigger) → Action: Webhooks by Zapier → POST → الـ URL
3. Map الحقول: `phone` (مطلوب), `name`, `email`

### س: إيه الفرق بين anon key و service key؟
- **anon key**: محدود بـ RLS policies — آمن للبراوزر
- **service key**: صلاحيات كاملة — **أبداً** ما ينزل على الكلاينت

### س: إزاي أشغل بدون WhatsApp/AI/Stripe؟
مش محتاج تعمل حاجة. كل الخدمات بتفشل بهدوء لو مفيش credentials. الـ CRM هيشتغل عادي بدونهم.

### س: إزاي أضيف منصة إعلانية جديدة؟
المنصات محددة في `ad_campaigns.platform` CHECK constraint. لو عايز تضيف:
```sql
ALTER TABLE ad_campaigns DROP CONSTRAINT ad_campaigns_platform_check;
ALTER TABLE ad_campaigns ADD CONSTRAINT ad_campaigns_platform_check 
  CHECK (platform IN ('facebook','google','instagram','tiktok','snapchat',
    'twitter','linkedin','youtube','sms','email','other','NEW_PLATFORM'));
```

---

## File Structure

```
Gamified-CRM/
├── app.py                    # Flask backend (~4800 lines, 163 routes)
├── ai_client.py              # Claude/OpenAI AI wrapper
├── whatsapp_client.py        # WhatsApp Business API client
├── import_leads.py           # Excel → CRM lead importer
├── distribute_leads.py       # Bulk lead distribution
├── schema_complete.sql       # Full database schema (32 RPCs)
├── schema_DROP_ALL.sql       # Database reset script
├── seed_demo.sql             # Demo data
├── requirements.txt          # Python dependencies
├── env.example               # Environment template
├── Dockerfile                # Docker image
├── docker-compose.yml        # Docker Compose
├── Procfile                  # Heroku
├── railway.toml              # Railway
├── render.yaml               # Render
├── pyproject.toml            # Ruff + Pytest config
├── CLAUDE.md                 # Dev instructions
├── templates/
│   ├── admin.html            # Admin SPA
│   ├── agent.html            # Agent PWA
│   ├── game.html             # 2D Phaser game
│   └── map.html              # Cyberpunk journey map
├── static/
│   ├── favicon.ico
│   ├── manifest.json         # PWA manifest
│   └── sw.js                 # Service worker
├── tests/
│   ├── conftest.py           # Fixtures (FakeSupabase)
│   ├── test_ai_client.py
│   ├── test_game_endpoints.py
│   ├── test_phase9.py
│   ├── test_v2_features.py
│   └── test_whatsapp_client.py
└── .github/
    └── workflows/
        └── ci.yml            # GitHub Actions CI
```

---

*Built by AlSaeb — Turning Sales into an Adventure.*
