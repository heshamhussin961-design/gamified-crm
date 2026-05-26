# 📱 دليل تطوير الـ Mobile App — AlSaeb CRM

> **آخر تحديث:** 2026-05-21
> **الكاتب:** Hesham Hussin
> **الحالة:** Pre-planning — الـ web app شغال على [al-saeb-crm.online](https://al-saeb-crm.online)

---

## 🎯 الهدف من المستند

ده دليل تفصيلي لتطوير **iOS + Android native apps** لسيستم AlSaeb CRM، بما يشمل:
1. وضع المعمارية الحالية (web) وليه مش متبع Clean Architecture
2. ليه الـ backend الحالي **مظبوط 100%** للموبايل بدون refactor كبير
3. اللي محتاج يتعمل قبل ما نبدأ كتابة الموبايل
4. خطة الـ apps من الـ A للـ Z

---

## 1️⃣ المعمارية الحالية (Web)

### Backend
- **`app.py`** — ملف Flask واحد (~5000 سطر) فيه 135+ endpoint
- Routes + Business logic + DB calls + AI integrations كلهم في نفس الملف
- منظم بـ banners (`# ==== SECTION ====`) بدلاً من modules
- الـ "real magic" في **PostgreSQL RPCs** (functions في `schema_complete.sql`)
- Auth: **Supabase JWT** (Bearer tokens)
- DB: **Supabase Postgres**
- AI: **Gemini Flash** (مجاني) → Anthropic → OpenAI fallback chain

### Frontend Templates
- `templates/admin.html` — Admin SPA (dark theme professional)
- `templates/agent.html` — Sales agent PWA (Web Push notifications)
- `templates/game.html` — 2D Phaser game
- `templates/map.html` — Cyberpunk city journey
- `templates/game3d.html` — 3D world (Three.js — Days 1-7 of build)

### ❌ ليه مش Clean Architecture؟
ده قرار مقصود من الـ project design (موثق في `CLAUDE.md`):
> "When adding endpoints, find the matching banner rather than creating new modules — the project **intentionally stays in one file**."

**الأسباب:**
- مفيش build step على الـ frontend (Tailwind CDN + vanilla JS)
- سهل في الـ debug والـ deploy
- سرعة تطوير عالية في المرحلة الأولى
- المنطق الأساسي محمي في PostgreSQL functions (مش بيتأثر بالـ Python refactor)

---

## 2️⃣ ليه الـ Backend الحالي **مظبوط** للموبايل؟

السؤال المهم: **هل لازم نـ refactor الـ Python كله قبل ما نبدأ الموبايل؟**

**الإجابة: لأ، مش لازم.** الموبايل ابليكيشن بيتعامل مع الـ HTTP API بس — مش بيشوف جوّا الكود الـ Python.

### ✅ اللي بالفعل جاهز:
| الميزة | الحالة | للموبايل |
|--------|--------|----------|
| REST endpoints (`/api/...`) | ✅ موجود | حيوي ✅ |
| JWT Bearer Auth | ✅ موجود | حيوي ✅ |
| JSON responses | ✅ موجود | حيوي ✅ |
| HTTPS via Nginx | ✅ موجود | حيوي ✅ |
| Supabase Realtime | ✅ موجود (WebSocket) | حيوي ✅ |
| Push notifications backend | ✅ Web Push شغال | محتاج تعديل ⚠️ |

### ⚠️ اللي محتاج تعديل/إضافة قبل الموبايل:
1. **توحيد شكل الـ responses** — بعض الـ endpoints بيرجع `{data: {...}}` وبعضها `{leads: [...]}` مباشرة
2. **OpenAPI/Swagger docs** — مش موجودين دلوقتي، **مهم جداً للموبايل**
3. **API Versioning** (`/api/v1/`) — عشان تغييرات بعد كده ميحطموش الـ apps القديمة
4. **Push backend** — يدعم APNs (Apple) + FCM (Google) بجانب Web Push الحالي

### ❌ اللي **مش** محتاج تعديل:
- ❌ **Clean Architecture refactor** — الموبايل بيشوف الـ HTTP API بس، مش الكود
- ❌ **DI / Repository pattern** — مش هيفيد الموبايل في حاجة
- ❌ نقل الكود لـ FastAPI أو Django — Flask مظبوط جداً

---

## 3️⃣ Tech Stack الموصى به للـ Apps

### الخيار الأمثل: **Flutter** ⭐ (Recommended)
**ليه؟**
- **Codebase واحد** يطلع iOS + Android (وموبايل ويب لو حبيت)
- Performance قريب من Native
- Supabase عندها **`supabase_flutter`** SDK رسمي ممتاز
- نفس الـ developer يقدر يشتغل على الـ apps الاتنين بدون فرق
- UI كاستوم بسهولة (لـ gamification الـ CRM لازم تكون عندك مرونة)
- موجود في الـ Google + ByteDance + eBay + BMW

```dart
// مثال: استدعاء API من Flutter
final response = await http.get(
  Uri.parse('https://al-saeb-crm.online/api/me'),
  headers: {'Authorization': 'Bearer $jwt'},
);
final data = jsonDecode(response.body);
```

### الخيار البديل: **React Native**
- Codebase واحد + JavaScript familiar
- **بطيء شوية** عن Flutter
- Hot reload ممتاز
- Supabase JS SDK نفسه شغال
- مناسب لو الفريق عنده React experience

### الخيار الناتيف (Two Apps): **Swift (iOS) + Kotlin (Android)**
- أفضل performance + native feel
- لازم team أكبر (developer لكل platform)
- وقت تطوير أطول
- مناسب لو محتاج features ناتيف عميقة (ARKit / Camera ML)
- **ممكن نختاره لاحقاً** لو الـ Flutter app نجح

### مقارنة:
| | Flutter | React Native | Swift+Kotlin |
|--|---------|--------------|--------------|
| **Time to market** | ⚡ سريع | ⚡ سريع | 🐢 بطيء |
| **Code reuse** | ✅ 95%+ | ✅ 90%+ | ❌ 0% |
| **Performance** | ⚡⚡ ممتاز | ⚡ كويس | ⚡⚡⚡ الأفضل |
| **Team size needed** | 1 dev | 1 dev | 2 devs (iOS+Android) |
| **Supabase support** | ✅ ممتاز | ✅ ممتاز | ✅ ممتاز |
| **Cost (تقديري)** | $$ | $$ | $$$$ |

**التوصية النهائية:** Flutter للـ MVP، بعدين Native لو الـ scale كبر.

---

## 4️⃣ خطة الـ Mobile App (المرحلة الأولى — MVP)

### Phase 0: Pre-Mobile (قبل ما يبدأ المطور الموبايل) — أسبوع واحد
**في الـ Web Backend:**

1. **توحيد شكل الـ Responses** (يومين)
   - كل endpoint يرجع نفس الـ envelope:
     ```json
     {
       "status": "success" | "error",
       "data": { ... },
       "message": "...",
       "timestamp": "2026-05-21T..."
     }
     ```
   - Audit الـ 135 endpoint الحالية

2. **إضافة OpenAPI Documentation** (يومين)
   - استخدم `flasgger` أو `flask-smorest`
   - كل endpoint يبقى موصوف: parameters, body, response shape, errors
   - الـ endpoint `/api/docs` يعرض Swagger UI

3. **API Versioning** (نص يوم)
   - كل الـ endpoints الحالية تتنقل لـ `/api/v1/...`
   - alias مؤقت يخلي القديم شغال (`/api/me` → `/api/v1/me`)

4. **Push Notifications يدعم Native** (يوم)
   - في `app.py` نضيف:
     - `send_push_apns(employee_id, ...)` لـ Apple
     - `send_push_fcm(employee_id, ...)` لـ Android
   - الـ `push_subscriptions` table يبقى فيها `platform` column (`web|ios|android`) + `token`
   - الـ Web Push الحالي يبقى كما هو

5. **CORS Headers** (نص يوم)
   - تأكيد إن الـ origins بتاع mobile apps مسموح بيها (في الـ debug)

### Phase 1: MVP App (3-4 أسابيع)
**Screens الأساسية:**
1. **Login** (Supabase Auth — email + password)
2. **Home Dashboard** — XP, Level, Coins, Stamina, Daily Quests
3. **Leads List + Detail** — قائمة الليدز + تفاصيل كل ليد + actions
4. **Actions Quick** — Call, WhatsApp, Note buttons
5. **Leaderboard** — Top 10 + your rank
6. **Profile + Settings**
7. **Push Notifications** — للـ leads جديدة + WhatsApp messages

**Tech:**
- Flutter 3.x
- `supabase_flutter` للـ auth + realtime
- `flutter_local_notifications` للـ local
- `firebase_messaging` للـ FCM
- `flutter_apns` للـ APNs (iOS)
- State management: **Riverpod** أو **Bloc**
- UI: Material 3 + custom theme matching the web app

### Phase 2: Advanced Features (2-3 أسابيع)
- WhatsApp inbox + reply (real-time)
- Voice notes recording
- Camera (لتسجيل لقاءات/visits)
- GPS tracking للـ attendance
- Offline mode (sqflite cache)
- Biometric login (Face ID / Fingerprint)

### Phase 3: Gamification (1-2 أسبوع)
- Achievement badges popup
- XP animations
- Leaderboard live updates
- Streak tracker (calendar view)
- Daily highlights cinematic

### Phase 4: 3D World على الموبايل؟ (اختياري — 2-3 أسابيع)
- استخدام **`flutter_3d_controller`** أو **WebView** لتشغيل `/game3d`
- بس مش ضروري للـ MVP

---

## 5️⃣ الـ API Endpoints اللي الموبايل هيستخدمها

### Auth
```
POST /api/auth/login              # عبر Supabase SDK مباشرة
POST /api/auth/refresh
POST /api/auth/logout
```

### الموظف
```
GET  /api/me                      # بيانات اللاعب
GET  /api/me/stats                # إحصائيات أسبوع/شهر
PATCH /api/me/mode                # toggle professional/game mode
GET  /api/badges/mine             # شارات الموظف
```

### الليدز
```
GET    /api/leads                 # list (filter + pagination)
GET    /api/leads/:id             # detail
POST   /api/leads                 # create
PATCH  /api/leads/:id             # update
POST   /api/leads/:id/lock        # lock (anti-collision)
POST   /api/leads/:id/unlock
POST   /api/leads/:id/status      # change status
POST   /api/leads/:id/ai-analyze  # Gemini analysis
```

### الـ Actions (LOG)
```
POST /api/actions                 # log call/message/deal/meeting
GET  /api/actions/recent
```

### Gamification
```
GET  /api/leaderboard             # global top players
GET  /api/quests/me               # daily/weekly quests
POST /api/quests/:id/complete
GET  /api/store/items             # متجر العملات
POST /api/store/buy/:item_id
GET  /api/employees/me/inventory  # المشتريات
```

### Realtime (عبر Supabase Realtime SDK)
- `leads` table (INSERT/UPDATE filter by assigned_to)
- `activity_feed` table (INSERT — for level ups, deals)
- `whatsapp_messages` table (INSERT — for inbound messages)
- `quests` table (UPDATE — for completion)

### Push (Backend)
```
POST /api/push/subscribe          # save device token
POST /api/push/unsubscribe
```

---

## 6️⃣ Push Notifications — Detailed Plan

### الحالة دلوقتي:
- `app.py` فيه `send_push_to_employee()` بتاع **Web Push (VAPID)**
- `push_subscriptions` table فيها `employee_id` + `subscription` JSONB

### اللي محتاج يتعمل:
1. **توسيع `push_subscriptions` schema:**
   ```sql
   ALTER TABLE push_subscriptions ADD COLUMN platform TEXT DEFAULT 'web';
   -- platform: 'web' | 'ios' | 'android'
   ALTER TABLE push_subscriptions ADD COLUMN device_token TEXT;
   -- For iOS APNs token / Android FCM token (instead of full subscription JSON)
   ```

2. **في `app.py` نضيف:**
   ```python
   def send_push_to_employee(employee_id, title, body, url=None):
       subs = supabase.table('push_subscriptions').select('*').eq('employee_id', employee_id).execute().data
       for sub in subs:
           if sub['platform'] == 'web':
               _send_web_push(sub['subscription'], title, body, url)
           elif sub['platform'] == 'ios':
               _send_apns(sub['device_token'], title, body)
           elif sub['platform'] == 'android':
               _send_fcm(sub['device_token'], title, body)
   ```

3. **Libraries محتاجين:**
   - `apns2` للـ iOS (APNs)
   - `firebase-admin` للـ Android (FCM)
   - الـ Web Push الحالي يبقى كما هو (`pywebpush`)

4. **Credentials محتاجين:**
   - APNs: certificate من Apple Developer Account (Auth Key `.p8` file)
   - FCM: Service Account JSON من Firebase Console

---

## 7️⃣ المخططات (Diagrams)

### الـ Architecture الحالي:
```
┌─────────────────┐
│   Browser/PWA   │ ← Web Push (VAPID)
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────┐
│   Nginx (HTTPS) │ ← Port 443, HSTS, security headers
└────────┬────────┘
         │ proxy
         ▼
┌─────────────────┐
│  Gunicorn + Flask│ ← app.py (135 endpoints)
│  port 5003       │
└────────┬────────┘
         │
         ├──→ Supabase Postgres (DB + Auth + Realtime + RPCs)
         ├──→ Gemini / Anthropic / OpenAI (AI)
         └──→ WhatsApp Business API (Meta Graph)
```

### الـ Architecture المخطط (بعد إضافة الموبايل):
```
┌────────────┐  ┌────────────┐  ┌────────────┐
│  Web App   │  │  iOS App   │  │ Android    │
│  (PWA)     │  │  (Flutter) │  │  App       │
└─────┬──────┘  └─────┬──────┘  └─────┬──────┘
      │ Web Push       │ APNs          │ FCM
      │                │               │
      └────────┬───────┴───────────────┘
               │ HTTPS REST + Supabase Realtime
               ▼
┌─────────────────────────────────────────────┐
│       Nginx + Flask app.py                  │
│  (الـ API الحالي — مش محتاج refactor)       │
└──────────────┬──────────────────────────────┘
               │
               ├──→ Supabase (DB + Auth + Realtime)
               ├──→ AI providers
               ├──→ WhatsApp API
               ├──→ APNs (Apple Push) ← جديد
               └──→ FCM (Google Push) ← جديد
```

---

## 8️⃣ Timeline + Cost Estimate (تقديري)

| Phase | Duration | Cost Estimate (UAE Market) |
|-------|----------|-----------------------------|
| **Phase 0: Backend Prep** (Swagger + versioning + APNs/FCM) | 5-7 أيام | 8,000-12,000 درهم |
| **Phase 1: MVP App** (Flutter) | 3-4 أسابيع | 25,000-40,000 درهم |
| **Phase 2: Advanced** | 2-3 أسابيع | 15,000-25,000 درهم |
| **Phase 3: Gamification** | 1-2 أسبوع | 8,000-15,000 درهم |
| **Phase 4: 3D World** (اختياري) | 2-3 أسابيع | 15,000-25,000 درهم |
| **App Store Submission** (iOS + Android) | 1 أسبوع | 2,000-4,000 درهم |
| **المجموع (بدون Phase 4)** | **~10 أسابيع** | **~58,000-96,000 درهم** |

**ملاحظات:**
- الأرقام دي للـ developer الواحد متوسط الخبرة
- Apple Developer Account: **$99/سنة** (~360 درهم)
- Google Play Console: **$25 لمرة واحدة** (~95 درهم)
- اختبار + QA إضافي محسوب

---

## 9️⃣ Checklist قبل البدء في الموبايل

### قبل ما ندعو developer:
- [ ] توحيد شكل الـ API responses
- [ ] OpenAPI/Swagger documentation كاملة
- [ ] API versioning (`/api/v1/`)
- [ ] إضافة APNs + FCM للـ push backend
- [ ] إنشاء Apple Developer Account
- [ ] إنشاء Google Play Developer Account
- [ ] إنشاء Firebase Project
- [ ] إعداد certificates + keys في secure vault

### وقت ما الموبايل يبدأ:
- [ ] اختيار Flutter (يفضل) أو React Native أو Native
- [ ] تحديد Brand colors + assets للـ app
- [ ] App Store screenshots + descriptions
- [ ] Privacy Policy + Terms of Service (لازم للـ store submission)
- [ ] Logo + App Icon (1024×1024)

---

## 🔟 ملاحظات مهمة

### ✅ نقاط قوة المعمارية الحالية (للمنظور الـ mobile):
1. **REST API standard** — أي تكنولوجي موبايل يقدر يكلمه
2. **Supabase ecosystem** — SDKs ممتازة لكل المنصات
3. **JWT Auth** — مفيش session/cookie مشاكل
4. **PostgreSQL RPCs** — البزنس لوجيك في الـ DB، فيتنفذ نفس النتيجة سواء طلبه ويب أو موبايل
5. **CORS مظبوط** — بس محتاج تعديل بسيط للموبايل origins (في الـ dev)
6. **HTTPS + Security headers** — production-ready

### ⚠️ نقاط احتياج تحسين:
1. **مفيش API tests automated** — قبل الموبايل لازم نـ test كل endpoint
2. **Error responses غير موحدة** — بعض الـ endpoints بترجع `{error: ...}` وبعضها `{message: ...}`
3. **Rate limiting موجود بس مش documented**
4. **مفيش audit log للموبايل-specific events**

### 🚫 ما يجبش نعمله:
- ❌ نشيل Flask ونحط FastAPI — وقت ضايع
- ❌ نقسم `app.py` لملفات كتير — قرار design للمشروع
- ❌ نضيف Docker microservices — over-engineering
- ❌ نعمل GraphQL — REST كفاية تماماً
- ❌ نـ refactor الـ frontend templates — الويب شغال

---

## 📚 References

- **Web app live:** [al-saeb-crm.online](https://al-saeb-crm.online)
- **GitHub repo:** [github.com/heshamhussin961-design/gamified-crm](https://github.com/heshamhussin961-design/gamified-crm)
- **Supabase Flutter SDK:** [supabase.com/docs/reference/dart](https://supabase.com/docs/reference/dart)
- **Flutter Docs:** [docs.flutter.dev](https://docs.flutter.dev)
- **APNs Setup:** [developer.apple.com/documentation/usernotifications](https://developer.apple.com/documentation/usernotifications)
- **FCM Setup:** [firebase.google.com/docs/cloud-messaging](https://firebase.google.com/docs/cloud-messaging)

---

## 📞 الخطوات القادمة الفورية

1. **اقرأ المستند ده كامل** ✅
2. **قرر**: Flutter أم Native (Swift + Kotlin)?
3. **ابدأ Phase 0** (الـ backend prep) — حتى لو الموبايل dev مش جاهز
4. **افتح Apple + Google Developer accounts** (بياخدوا أيام للموافقة)
5. **شارك المستند ده** مع الـ moblie developer قبل ما يبدأ

---

**📝 ملاحظة من Claude:**
الـ codebase الحالي **مش متبع Clean Architecture** بشكل صريح، وده **قرار مقصود** يخدم الـ web app كـ MVP سريع. **لكن** ده مش مشكلة للموبايل ابليكيشن، لأن الموبايل بيكلم HTTP API فقط — مش بيشوف الكود الـ Python الداخلي. اللي يفيد الموبايل هو **API contract documentation** (Swagger) و **versioning**، مش refactor الكود.

---

*— End of Document —*
