# 🏢 تقسيمة Pixxi CRM - دليل البناء لـ AlSaeb

> الهدف: إعادة هيكلة AlSaeb CRM ليكون بنفس تقسيمة Pixxi (المعيار في سوق الإمارات العقاري)
> المرجع: pixxicrm.com - الشركة عندها +٣٠٠ عميل في دبي
> آخر تحديث: مايو ٢٠٢٦

---

## 📋 الهيكل العام (Pixxi Style)

Pixxi مقسوم لـ **٣ أقسام رئيسية في الـ Sidebar**:

```
┌─────────────────────────────────────────┐
│  AlSaeb CRM                             │
├─────────────────────────────────────────┤
│                                         │
│  📊 FEATURES (الميزات الأساسية)         │
│  💼 SOLUTIONS (الحلول حسب القسم)        │
│  🔌 INTEGRATIONS (التكاملات)            │
│                                         │
└─────────────────────────────────────────┘
```

---

# 📊 القسم الأول: FEATURES (الميزات الأساسية)

ده القلب الرئيسي للنظام. ١٢ ميزة رئيسية:

## ١. 👥 Leads Management (إدارة الليدز)
**الهدف:** Capture, qualify, and assign leads

### الـ Sub-sections:
- قائمة الليدز (List view)
- Kanban view (حسب الحالة)
- Filters متقدمة
- Bulk Actions
- Search متطور
- Lead Profile كامل

### المميزات الأساسية:
- استقبال ليدز من كل المصادر تلقائي
- توزيع ذكي على الموظفين
- تتبع كل تفاعل مع الليد
- ملاحظات + Activity Log
- ربط بالعقارات

---

## ٢. 🏢 Listings Management (إدارة العقارات)
**الهدف:** Publish, update, and monitor listings

### الـ Sub-sections:
- كل العقارات (Grid + List views)
- إضافة عقار جديد
- نشر على البورتالز (Bayut, Property Finder, Dubizzle)
- إدارة الصور والفيديوهات
- VR Tours (اختياري)

### المميزات الأساسية:
- Validation تلقائي قبل النشر
- مزامنة مع portals
- تتبع المشاهدات والتفاعلات
- ربط بالمالك (Owner)
- ربط بالليدز المهتمة

---

## ٣. 👤 Owners Management (إدارة الملاك)
**الهدف:** Store owner details, manage relationships

### الـ Sub-sections:
- قاعدة بيانات الملاك
- إضافة مالك جديد
- ملف المالك الكامل
- عقاراته
- تاريخ التعاملات

### المميزات الأساسية:
- بيانات المالك كاملة (اسم، موبايل، هوية، جنسية)
- ملف اتصالات (مكالمات، رسائل)
- المستندات (Title Deed، Power of Attorney)
- العقارات المملوكة
- العمولات المستحقة

---

## ٤. 🏗️ Off-Plan Projects (المشاريع تحت الإنشاء)
**الهدف:** Track upcoming developments and sales

### الـ Sub-sections:
- كل المشاريع
- إضافة مشروع جديد
- خطة الدفع (Payment Plan)
- Floor Plans
- وحدات المشروع

### المميزات الأساسية:
- تتبع مراحل البناء
- خطط دفع تفاعلية
- حجوزات الوحدات
- ربط بالمطور (Developer)
- Brochures + PDFs

---

## ٥. 💰 Transactions & Commissions (العمليات والعمولات)
**الهدف:** Track deals, calculate payouts instantly

### الـ Sub-sections:
- كل العمليات (Transactions)
- إنشاء عملية جديدة
- موافقات الإدارة
- حساب العمولات تلقائي
- تقارير مالية

### المميزات الأساسية:
- ٤ تابات في كل عملية:
  - الأساسيات (Property + Buyer + Amount)
  - تفاصيل العقار
  - الطرف الآخر
  - البروكر
- حساب العمولة auto
- Workflow اعتماد
- ربط بالـ Invoicing

---

## ٦. 🗺️ Map View (عرض الخريطة)
**الهدف:** Visualize listings by location easily

### الـ Sub-sections:
- خريطة تفاعلية لكل العقارات
- فلترة بالمنطقة، السعر، النوع
- Heatmap للمناطق الأكثر طلباً
- Pin Drop لمواقع الليدز

### المميزات الأساسية:
- Leaflet/Google Maps integration
- مناطق دبي مفصلة
- Cluster Markers
- Quick Preview للعقار من الخريطة

---

## ٧. 📅 Calendar (التقويم)
**الهدف:** Plan schedules, never miss meetings

### الـ Sub-sections:
- Day / Week / Month views
- ميتنجات
- Viewings (معاينات)
- Tasks
- Follow-ups

### المميزات الأساسية:
- مزامنة مع Google Calendar
- تذكيرات تلقائية
- ربط بالليدز والعقارات
- Team Calendar (لو manager)
- Color coding حسب النوع

---

## ٨. 💾 Pixxi Database / Estate Index (قاعدة بيانات السوق)
**الهدف:** Centralized data, always up-to-date

### الـ Sub-sections:
- معلومات المباني (Buildings DB)
- معلومات المناطق
- متوسط الأسعار
- معدلات الإيجار
- معلومات المطورين

### المميزات الأساسية:
- بيانات RERA الرسمية
- تحديثات أسبوعية
- مرجعية للوكلاء عند التسعير

---

## ٩. 🗃️ Database Management (إدارة قاعدة البيانات)
**الهدف:** Organize records, keep data clean

### الـ Sub-sections:
- تنظيف الـ duplicates
- استيراد/تصدير
- النسخ الاحتياطي
- سجل التعديلات
- صلاحيات الوصول

### المميزات الأساسية:
- Auto-deduplication
- Import from Excel/CSV
- Audit Log كامل
- Data export بـ formats مختلفة

---

## ١٠. ✅ Workflow & Approvals (سير العمل والموافقات)
**الهدف:** Streamline tasks, approve faster daily

### الـ Sub-sections:
- Pending Approvals
- My Submissions
- Approval History
- Workflow Settings

### المميزات الأساسية:
- موافقة على Transactions
- موافقة على نشر العقارات
- موافقة على الخصومات
- Multi-level approval
- Notifications للموافقين

---

## ١١. 📈 KPI Insights (مؤشرات الأداء والرؤى)
**الهدف:** Track performance, improve decisions fast

### الـ Sub-sections:
- Dashboard عام
- أداء الفريق
- أداء الحملات
- تقارير مالية
- Custom Reports

### المميزات الأساسية:
- ١٢+ مؤشر أداء
- مقارنات شهرية
- Forecasting
- Export لـ PDF/Excel
- Visualization (Charts)

---

## ١٢. ⚙️ Custom Fields (الحقول المخصصة)
**الهدف:** Create custom inquiry fields that match your business needs

### الـ Sub-sections:
- حقول لليدز
- حقول للعقارات
- حقول للعمليات
- إدارة الحقول

### المميزات الأساسية:
- إنشاء حقول جديدة
- أنواع: نص، رقم، تاريخ، قائمة، Yes/No
- ربط بالـ filters والـ reports
- إجباري أو اختياري

---

## ١٣. 🔄 Lead Rotation (التدوير التلقائي)
**الهدف:** Real Estate Smart automation

### الـ Sub-sections:
- قواعد التدوير
- تاريخ التوزيع
- إعدادات الفرق

### المميزات الأساسية:
- Round Robin
- Random
- حسب الأداء (Performance-based)
- حسب المصدر
- إيقاف موظف من التدوير مؤقتاً

---

# 💼 القسم الثاني: SOLUTIONS (الحلول حسب القسم)

Pixxi بيعمل واجهات مختلفة حسب دور المستخدم. ٦ Solutions:

## ١. 🎯 Management (الإدارة)
**Lead with clarity. Operate with control.**

### اللي بيشوفه المدير:
- Dashboard عام للشركة
- أداء كل فرع
- أداء كل فريق
- أداء كل موظف
- التوقعات (Forecasts)
- Reports تفصيلية

---

## ٢. 💼 Sales (المبيعات)
**Work smarter, close faster**

### اللي بيشوفه موظف المبيعات:
- Pipeline الشخصي
- Quick Actions (Call, WhatsApp, Email)
- Today's Tasks
- My Listings
- My Commissions
- Performance Stats

---

## ٣. 📣 Marketing (التسويق)
**Connect campaigns to conversions**

### اللي بيشوفه فريق التسويق:
- Campaign Manager
- Source Performance (Bayut vs Meta vs Google)
- Cost per Lead
- Conversion Rate per source
- ROI reports
- A/B Testing

---

## ٤. 📋 Admins & Operations (الإدارة والعمليات)
**Streamline tasks, ensure compliance**

### اللي بيشوفه قسم العمليات:
- Document Management
- Compliance Tracking
- RERA Records
- Audit Trails
- Approval Queues

---

## ٥. 💵 Accounts (الحسابات)
**Transparent. Automated. Accurate.**

### اللي بيشوفه قسم الحسابات:
- Invoices
- Commissions Tracking
- Payments
- Financial Reports
- Tax Reports (VAT)

---

## ٦. 🔧 IT
**System administration and support**

### اللي بيشوفه قسم الـ IT:
- User Management
- Permissions
- API Keys
- Webhooks
- System Logs
- Backups

---

# 🔌 القسم الثالث: INTEGRATIONS (التكاملات)

Pixxi بيتكامل مع المنصات الأساسية في السوق:

## بورتالز عقارية
| التكامل | الوصف |
|---------|-------|
| **Property Finder** | نشر العقارات + استقبال الـ inquiries |
| **Bayut** | نشر العقارات + استقبال leads |
| **Dubizzle** | نشر العقارات + استقبال leads |
| **JamesEdition** | للعقارات الفاخرة |

## إعلانات
| التكامل | الوصف |
|---------|-------|
| **Meta Ads** | Facebook + Instagram Lead Ads |
| **Google Ads** | Google Lead Form Ads |
| **TikTok** | TikTok Lead Generation |

## أدوات
| التكامل | الوصف |
|---------|-------|
| **Google Calendar** | مزامنة المواعيد |
| **Zapier** | ربط مع +٥٠٠٠ تطبيق |
| **WhatsApp Business** | الرسائل والمكالمات |

---

# 🎨 الـ UI/UX (الشكل العام)

## Sidebar (القائمة الجانبية)
Pixxi بيستخدم sidebar ثابتة على اليمين (RTL) فيها:

```
┌──────────────────┐
│   🏢 AlSaeb     │  ← Logo
├──────────────────┤
│ 🏠 Home          │
│ 👥 Leads         │
│ 🏢 Listings      │
│ 👤 Owners        │
│ 🏗️ Off-Plan      │
│ 💰 Transactions  │
│ 🗺️ Map           │
│ 📅 Calendar      │
│ 📈 KPI           │
│ ⚙️ Settings      │
└──────────────────┘
```

## Top Bar (الشريط العلوي)
```
┌────────────────────────────────────────┐
│ Search... 🔍   Notifications 🔔  User 👤│
└────────────────────────────────────────┘
```

## Main Content Area
- استخدم Cards بظلال خفيفة
- Spacing مريح (مش زحمة)
- Colors: أبيض/رمادي فاتح + لون primary واحد
- Typography: واضح ومش مزدحم

---

# 🎯 الفرق بين Pixxi و AlSaeb الحالي

## اللي عندك دلوقتي (AlSaeb):
✅ كل الـ features الأساسية موجودة
❌ التقسيمة غير منظمة بطريقة Pixxi
❌ الـ Sidebar مزدحمة
❌ الـ Gamification بتطغى على الـ CRM
❌ مفيش solutions views حسب الدور
❌ الـ Integrations مش ظاهرة بوضوح

## اللي تحتاج تعمله:

### الأولوية الأولى:
1. **إعادة تنظيم الـ Sidebar** بنفس ترتيب Pixxi (١٢-١٣ feature)
2. **فصل Gamification** في tab منفصل (Game Mode)
3. **عمل Solutions Views** حسب الدور

### الأولوية الثانية:
4. **توحيد الـ Design Language** (cards، spacing، colors)
5. **بناء Integrations Page** مرئية
6. **تحسين الـ Search** ليبقى عام في كل النظام

### الأولوية الثالثة:
7. **Owner Management** كقسم منفصل (مش جوا Listings)
8. **Off-Plan Projects** كقسم منفصل
9. **Pixxi Database** equivalent (RERA data)

---

# 📝 خطة التنفيذ المقترحة

## الأسبوع الأول: التقسيمة
- [ ] إعادة هيكلة Sidebar
- [ ] فصل Gamification في tab منفصل
- [ ] ترتيب الـ Features بنفس Pixxi

## الأسبوع الثاني: الـ Solutions
- [ ] Management Solution view
- [ ] Sales Solution view
- [ ] Marketing Solution view

## الأسبوع الثالث: الـ Integrations
- [ ] Integrations page
- [ ] ربط Property Finder / Bayut / Dubizzle
- [ ] Meta Ads + Google Ads tracking

## الأسبوع الرابع: Polish
- [ ] توحيد الـ Design
- [ ] Performance optimization
- [ ] User testing

---

# 💬 برومبت لـ Claude Code

```
# مهمة: إعادة هيكلة AlSaeb CRM بتقسيمة Pixxi

## قبل ما تبدأ
1. اقرأ templates/admin.html كامل
2. اقرأ templates/agent.html كامل
3. قولي إيه الـ sections الموجودة دلوقتي

## المطلوب

### Phase 1: Sidebar Restructure
أعد ترتيب الـ sidebar تكون كده بالترتيب:

1. 🏠 Home (Dashboard)
2. 👥 Leads
3. 🏢 Listings
4. 👤 Owners
5. 🏗️ Off-Plan Projects
6. 💰 Transactions
7. 🗺️ Map View
8. 📅 Calendar
9. 📈 KPI Insights
10. ✅ Workflow & Approvals
11. 🔄 Lead Rotation
12. ⚙️ Custom Fields
13. 🎮 Game Mode (separate tab للجيمفيكشن)

### Phase 2: فصل Gamification
- اعمل tab منفصل اسمه "Game Mode"
- نقل لـ هناك: XP, Coins, Badges, Quests, Leaderboard
- في الـ CRM الأساسي اعرض الـ XP/Level بشكل خفيف فقط (corner badge)

### Phase 3: Owners Section
- اعمل قسم منفصل للملاك (مش جوا Listings)
- نفس تصميم الـ Leads بس للملاك

### Phase 4: Polish
- توحيد الـ design (cards, spacing, colors)
- تنظيف الـ visual clutter
- جعل النظام يحس "سلس" زي Pixxi

## ملاحظات
- لا تشيل أي feature موجودة، بس أعد ترتيبها
- حافظ على كل الـ APIs الحالية
- بعد كل phase اعمل git commit
- اختبر بعد كل phase
```

---

*آخر تحديث: مايو ٢٠٢٦*
*المرجع: pixxicrm.com (UAE Real Estate CRM Standard)*
