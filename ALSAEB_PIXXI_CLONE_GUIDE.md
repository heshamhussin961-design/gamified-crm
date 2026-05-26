# 🎨 AlSaeb CRM - دليل تقليد Pixxi الكامل (UI/UX)

> الهدف: تحويل AlSaeb ليكون نسخة مطابقة من Pixxi في التقسيمة والشكل
> المرجع: pixxicrm.com - الشركة عندها +٣٠٠ عميل في دبي
> آخر تحديث: مايو ٢٠٢٦

---

# 🎨 الـ Design System (الـ UI الكامل)

## 🎨 الألوان (Color Palette)

Pixxi بيستخدم ألوان نظيفة وهادية. اللون الأساسي **أزرق غامق**:

```css
/* الألوان الأساسية */
--primary: #1E3A8A;          /* أزرق غامق - الـ Header والـ Sidebar */
--primary-light: #3B82F6;    /* أزرق فاتح - الأزرار */
--primary-hover: #1D4ED8;    /* hover state */

/* الخلفية */
--bg-main: #F9FAFB;          /* رمادي فاتح جداً - خلفية الصفحة */
--bg-card: #FFFFFF;          /* أبيض - الكروت */
--bg-hover: #F3F4F6;         /* hover للصفوف */

/* النصوص */
--text-primary: #111827;     /* أسود غامق - العناوين */
--text-secondary: #6B7280;   /* رمادي - النصوص الثانوية */
--text-muted: #9CA3AF;       /* رمادي فاتح - placeholder */

/* الحدود */
--border: #E5E7EB;           /* رمادي فاتح للحدود */
--border-focus: #3B82F6;     /* للـ inputs المختارة */

/* الحالات */
--success: #10B981;          /* أخضر - النجاح */
--warning: #F59E0B;          /* أصفر - التحذير */
--danger: #EF4444;           /* أحمر - الخطأ */
--info: #3B82F6;             /* أزرق - معلومات */

/* Status Colors للـ Leads */
--status-new: #3B82F6;       /* جديد */
--status-contacted: #8B5CF6; /* تم التواصل */
--status-interested: #F59E0B;/* مهتم */
--status-meeting: #10B981;   /* اجتماع */
--status-won: #059669;       /* فاز */
--status-lost: #DC2626;      /* خسارة */
```

## 🔤 الـ Typography

```css
/* الخط الأساسي */
font-family: 'Inter', 'Cairo', 'Tajawal', sans-serif;

/* الأحجام */
--text-xs: 11px;     /* labels صغيرة */
--text-sm: 13px;     /* النصوص الثانوية */
--text-base: 14px;   /* النص الأساسي */
--text-lg: 16px;     /* العناوين الفرعية */
--text-xl: 18px;     /* عناوين الأقسام */
--text-2xl: 24px;    /* عناوين الصفحات */
--text-3xl: 30px;    /* العناوين الكبيرة */

/* الأوزان */
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
```

## 📏 الـ Spacing

```css
/* مسافات منتظمة */
--space-1: 4px;
--space-2: 8px;
--space-3: 12px;
--space-4: 16px;
--space-5: 20px;
--space-6: 24px;
--space-8: 32px;
--space-10: 40px;
--space-12: 48px;
--space-16: 64px;
```

## 🔲 الـ Shadows

```css
--shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
--shadow-md: 0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06);
--shadow-lg: 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05);
--shadow-xl: 0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04);
```

## 🔘 الـ Border Radius

```css
--radius-sm: 4px;     /* buttons صغيرة */
--radius-md: 6px;     /* inputs */
--radius-lg: 8px;     /* cards */
--radius-xl: 12px;    /* large cards */
--radius-full: 9999px;/* pills, avatars */
```

---

# 🏗️ الـ Layout (الهيكل العام)

## 📐 الهيكل الكامل (Desktop)

```
┌──────────────────────────────────────────────────────────────────┐
│                          TOP BAR (60px)                          │
│  Logo │ Search 🔍              │  🔔 12 │ 👤 Profile           │
├──────┬───────────────────────────────────────────────────────────┤
│      │                                                            │
│ SIDE │                                                            │
│ BAR  │              MAIN CONTENT AREA                             │
│      │              (Padding: 24px)                               │
│ 250px│                                                            │
│      │                                                            │
│      │                                                            │
└──────┴───────────────────────────────────────────────────────────┘
```

## 📐 الهيكل (Mobile)

```
┌──────────────────────────┐
│       TOP BAR            │
│   ☰  Logo    🔔  👤     │
├──────────────────────────┤
│                          │
│      MAIN CONTENT        │
│                          │
│                          │
├──────────────────────────┤
│   🏠  📋  ➕  📅  👤    │  ← Bottom Tab Bar
└──────────────────────────┘
```

---

# 📐 الـ Sidebar (القائمة الجانبية) - بالتفصيل

## التصميم الكامل

```
┌────────────────────────┐
│                        │
│   🏢 AlSaeb CRM        │  ← Logo + اسم الشركة
│                        │
├────────────────────────┤
│                        │
│  📊  Dashboard         │  ← Active state: bg أزرق
│  ─────────────────     │
│                        │
│  MAIN                  │  ← Section label
│  👥  Leads        12   │  ← مع badge للعدد
│  🏢  Listings          │
│  👤  Owners            │
│  🏗️  Off-Plan          │
│  💰  Transactions      │
│                        │
│  TOOLS                 │
│  🗺️  Map View          │
│  📅  Calendar     3    │  ← اليوم 3 events
│  📈  KPI Insights      │
│  ✅  Approvals    5    │
│                        │
│  AUTOMATION            │
│  🔄  Lead Rotation     │
│  ⚙️  Custom Fields     │
│  🔗  Workflow          │
│                        │
│  ──────────────        │
│  🎮  Game Mode         │  ← منفصل تماماً
│                        │
├────────────────────────┤
│                        │
│  ⚙️  Settings          │  ← في الأسفل
│  🚪  Logout            │
│                        │
└────────────────────────┘
```

## ✨ تفاصيل الـ Sidebar

### المواصفات:
- **العرض:** ٢٥٠px ثابت (يطوي لـ ٧٠px على الموبايل)
- **اللون:** أبيض مع border رمادي فاتح يمين
- **الـ items:** ٤٠px height + padding ١٢px

### الـ States:
- **Default:** نص رمادي + ايقونة رمادية
- **Hover:** خلفية رمادي فاتح جداً
- **Active:** خلفية أزرق فاتح + نص أزرق غامق + شريط أزرق على اليمين

### Section Labels:
```css
.sidebar-section-label {
  font-size: 11px;
  font-weight: 600;
  color: #9CA3AF;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 8px 16px 4px;
}
```

### Item Style:
```css
.sidebar-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 16px;
  border-radius: 8px;
  margin: 2px 8px;
  font-size: 14px;
  color: #6B7280;
}

.sidebar-item.active {
  background: #EFF6FF;
  color: #1D4ED8;
  font-weight: 600;
  border-right: 3px solid #1D4ED8;
}

.sidebar-item .badge {
  margin-right: auto;
  background: #DBEAFE;
  color: #1E40AF;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 600;
}
```

---

# 🔝 الـ Top Bar

## التصميم

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ☰   🔍 Search leads, listings, owners...    🔔 12   👤 ▼     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## التفاصيل:

### Search Bar (مهم جداً في Pixxi):
- **العرض:** ٤٠٠px في الوسط
- **placeholder:** "Search leads, listings, owners..."
- **Icon:** 🔍 يسار
- **Behavior:** 
  - يفتح dropdown مع نتائج فوراً
  - يقسم النتائج: Leads / Listings / Owners
  - Keyboard shortcut: `Cmd/Ctrl + K`

### Notifications Bell:
- ايقونة جرس مع red dot لو فيه جديد
- يفتح dropdown بـ آخر ١٠ إشعارات
- "Mark all as read" زرار في الأعلى

### User Menu:
- Avatar + اسم + arrow down
- يفتح dropdown فيه:
  - My Profile
  - Settings
  - Help
  - Sign Out

---

# 📊 الـ Dashboard الرئيسي

## التصميم

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  Good morning, Ahmed 👋                       This week ▼   │
│  Here's what's happening with your business today.          │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │   123    │ │   45     │ │   12     │ │  $250K   │      │
│  │  Leads   │ │ Listings │ │  Deals   │ │ Revenue  │      │
│  │  +12% ↑  │ │  +3% ↑   │ │  +5 new  │ │  +18% ↑  │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
│                                                              │
│  ┌──────────────────────────┐ ┌───────────────────────┐    │
│  │                          │ │                       │    │
│  │   Sales Pipeline         │ │  Recent Activity      │    │
│  │   [Chart hier]           │ │  [Activity list]      │    │
│  │                          │ │                       │    │
│  └──────────────────────────┘ └───────────────────────┘    │
│                                                              │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Top Performers This Month                       │      │
│  │  [Leaderboard table]                              │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## مكونات الـ Dashboard:

### ١. KPI Cards (٤ كروت في صف)
```
┌─────────────────┐
│  ICON           │
│                 │
│  123            │  ← رقم كبير bold
│  Total Leads    │  ← label صغير
│                 │
│  +12% ↑         │  ← change indicator
└─────────────────┘
```

### ٢. Charts:
- استخدم **Chart.js** أو **ApexCharts**
- ألوان متناسقة مع الـ palette
- Animations خفيفة عند التحميل

### ٣. Activity Feed:
```
👤 Ahmed قام بإغلاق صفقة - Marina Tower    منذ ٥ دقائق
📞 Sara اتصلت بـ Mohammed Ali             منذ ١٥ دقيقة
🏢 New listing added: Downtown Apartment   منذ ٣٠ دقيقة
```

---

# 👥 صفحة الـ Leads (الأهم)

## التصميم الكامل

```
┌──────────────────────────────────────────────────────────────┐
│  Leads Management                            + New Lead       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Tabs: [All Leads] [My Leads] [Hot Leads] [Cold]           │
│                                                              │
│  🔍 Search...    [Filter ▼] [Source ▼] [Status ▼] [More ▼]│
│                                                              │
│  View: [📋 List] [📊 Kanban] [📅 Calendar]                │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ☐ │ Name        │ Phone      │ Source   │ Status │ Agent │
│  ──┼─────────────┼────────────┼──────────┼────────┼───────│
│  ☐ │ Ahmed Ali   │ +971501... │ Bayut    │ 🟢 New │ Sara  │
│  ☐ │ Mohammed K. │ +971502... │ PF       │ 🟡 Hot │ John  │
│  ☐ │ Fatima H.   │ +971503... │ Website  │ 🟢 New │ -     │
│                                                              │
│  Showing 1-20 of 123              ← Previous  Next →        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## الـ Kanban View (مهم جداً):

```
┌─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│   NEW   │CONTACTED│INTERESTED│ MEETING │  WON    │  LOST   │
│  (45)   │  (32)   │  (18)   │  (12)   │   (5)   │   (8)   │
├─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│         │         │         │         │         │         │
│ ┌─────┐ │ ┌─────┐ │ ┌─────┐ │ ┌─────┐ │ ┌─────┐ │ ┌─────┐ │
│ │ Card│ │ │ Card│ │ │ Card│ │ │ Card│ │ │ Card│ │ │ Card│ │
│ └─────┘ │ └─────┘ │ └─────┘ │ └─────┘ │ └─────┘ │ └─────┘ │
│         │         │         │         │         │         │
│ ┌─────┐ │ ┌─────┐ │         │         │         │         │
│ │ Card│ │ │ Card│ │         │         │         │         │
│ └─────┘ │ └─────┘ │         │         │         │         │
│         │         │         │         │         │         │
└─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘
```

### Drag & Drop:
- اسحب الـ card من column لـ column
- بيتحدث الحالة تلقائي

### الـ Card Design:
```
┌──────────────────────────┐
│  👤 Ahmed Ali        ⋮  │
│  📱 +971 50 123 4567    │
│  💼 Looking for villa   │
│                          │
│  🏷️ Bayut · $2M-$3M     │
│                          │
│  👤 Sara M.    🕐 2h    │
└──────────────────────────┘
```

---

# 📝 صفحة الـ Lead Profile

## التصميم الكامل (٣ أعمدة)

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  ← Back to Leads          Ahmed Ali             ✏️ Edit     │
│                                                              │
├──────────────┬──────────────────────────┬───────────────────┤
│              │                          │                   │
│   PROFILE    │   ACTIVITY TIMELINE      │  QUICK ACTIONS    │
│              │                          │                   │
│   👤         │   📅 Today               │  📞 Call          │
│              │                          │  💬 WhatsApp      │
│   Ahmed Ali  │   ✅ Meeting scheduled   │  📧 Email         │
│   +971501... │      Mar 25, 3:00 PM     │  📅 Meeting       │
│   ahmed@...  │                          │                   │
│              │   📞 Call - 5 min        │  ─────────────    │
│   Bayut      │      Discussed budget    │                   │
│   $2M-$3M    │      ✏️ Add note         │  INTERESTED IN    │
│              │                          │                   │
│   ─────────  │   📅 Yesterday           │  🏢 Villa         │
│              │                          │  📍 Dubai Marina  │
│   FIELDS     │   💬 WhatsApp sent       │  🛏️ 4 bedrooms    │
│              │      "Hi Ahmed..."        │  💰 $2M - $3M     │
│   Source:    │                          │                   │
│   Bayut      │   ─────────────────       │  ─────────────    │
│              │                          │                   │
│   Assigned:  │   + Add Activity         │  RELATED LISTINGS │
│   Sara M.    │                          │                   │
│              │                          │  [3 listings]     │
│   Created:   │                          │                   │
│   Mar 20     │                          │  ─────────────    │
│              │                          │                   │
│   ─────────  │                          │  DOCUMENTS        │
│              │                          │                   │
│   TAGS       │                          │  📄 ID Copy.pdf   │
│              │                          │  📄 Passport.pdf  │
│   [Hot]      │                          │                   │
│   [Villa]    │                          │  ⬆️ Upload        │
│              │                          │                   │
└──────────────┴──────────────────────────┴───────────────────┘
```

---

# 🏢 صفحة الـ Listings

## التصميم - Grid View

```
┌──────────────────────────────────────────────────────────────┐
│  Listings                              + New Listing          │
├──────────────────────────────────────────────────────────────┤
│  🔍 Search...   [Type ▼] [Status ▼] [Price ▼] [More ▼]     │
│                                                              │
│  View: [▦ Grid] [📋 List] [🗺️ Map]                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │             │ │             │ │             │           │
│  │  [IMAGE]    │ │  [IMAGE]    │ │  [IMAGE]    │           │
│  │             │ │             │ │             │           │
│  │  ─────────  │ │  ─────────  │ │  ─────────  │           │
│  │  Villa Maya │ │  Apartment  │ │  Penthouse  │           │
│  │  Marina     │ │  Downtown   │ │  JBR        │           │
│  │  $2.5M      │ │  $850K      │ │  $5.2M      │           │
│  │  🛏️ 4  🛁 5│ │  🛏️ 2  🛁 2│ │  🛏️ 5  🛁 6│           │
│  │             │ │             │ │             │           │
│  │  🟢 Active  │ │  🟡 Rented  │ │  🟢 Active  │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Listing Card:

```
┌─────────────────────────┐
│                         │
│   [PROPERTY IMAGE]      │  ← 16:10 ratio
│   [⭐ Save] [Share]     │  ← في الكورنر
│                         │
├─────────────────────────┤
│  $2,500,000             │  ← السعر bold كبير
│  Villa for Sale         │  ← النوع
│  Dubai Marina           │  ← الموقع
│                         │
│  🛏️ 4    🛁 5    📐 4500│  ← السمات
│                         │
│  🟢 Active              │  ← الحالة
│                         │
│  ⋮ Actions              │
└─────────────────────────┘
```

---

# 💰 صفحة الـ Transactions

## التصميم

```
┌──────────────────────────────────────────────────────────────┐
│  Transactions                          + New Transaction      │
├──────────────────────────────────────────────────────────────┤
│  Total Volume: $12.5M  │  Commissions: $625K  │  Deals: 45  │
├──────────────────────────────────────────────────────────────┤
│  Status: [All] [Pending] [Approved] [Closed] [Cancelled]    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │ #1234 │ Villa Marina │ Ahmed → Mohammed │ $2.5M    │    │
│  │       │ Buyer: Sara  │ Commission: $125K│ 🟢 Done  │    │
│  ├────────────────────────────────────────────────────┤    │
│  │ #1235 │ Apartment    │ Pending Approval │ $850K   │    │
│  │       │ Buyer: Fatima│ Commission: $42K │ 🟡 Hold │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

# 🎨 الـ Components الجاهزة

## ١. Button

```css
.btn-primary {
  background: #1D4ED8;
  color: white;
  padding: 8px 16px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s;
}

.btn-primary:hover {
  background: #1E40AF;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(29, 78, 216, 0.2);
}

.btn-secondary {
  background: white;
  color: #374151;
  border: 1px solid #E5E7EB;
  /* باقي نفس الأول */
}

.btn-danger {
  background: #EF4444;
  color: white;
}
```

## ٢. Input

```css
.input {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #E5E7EB;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.input:focus {
  outline: none;
  border-color: #3B82F6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}
```

## ٣. Card

```css
.card {
  background: white;
  border-radius: 12px;
  border: 1px solid #E5E7EB;
  padding: 20px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  transition: all 0.2s;
}

.card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  transform: translateY(-2px);
}
```

## ٤. Badge (Status Pills)

```css
.badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}

.badge-success { background: #D1FAE5; color: #065F46; }
.badge-warning { background: #FEF3C7; color: #92400E; }
.badge-danger { background: #FEE2E2; color: #991B1B; }
.badge-info { background: #DBEAFE; color: #1E40AF; }
```

## ٥. Table

```css
.table {
  width: 100%;
  background: white;
  border-radius: 12px;
  overflow: hidden;
}

.table th {
  background: #F9FAFB;
  padding: 12px 16px;
  text-align: right;
  font-size: 12px;
  font-weight: 600;
  color: #6B7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.table td {
  padding: 16px;
  border-top: 1px solid #F3F4F6;
  font-size: 14px;
  color: #111827;
}

.table tr:hover {
  background: #F9FAFB;
}
```

---

# 🎯 المبادئ الأساسية لتحقيق "الإحساس بـ Pixxi"

## ١. الـ "Spacing" (المسافات)
- **مسافات كبيرة** بين العناصر (مش زحمة)
- Padding ٢٤px على الأقل في الكروت
- Spacing ١٦px بين الأقسام

## ٢. الـ "Cleanliness" (النظافة)
- **ابتعد عن الألوان الكتيرة** (max ٣ ألوان في الصفحة)
- خلفية رمادية فاتحة + كروت بيضاء = شكل نظيف
- استخدم الأبيض كـ "negative space"

## ٣. الـ "Hierarchy" (الترتيب البصري)
- العناوين **bold وأكبر**
- النصوص الثانوية **رمادية وأصغر**
- الأرقام المهمة **كبيرة جداً**

## ٤. الـ "Consistency" (الاتساق)
- نفس الـ button style في كل النظام
- نفس الـ card design
- نفس الـ icons (Heroicons أو Lucide)

## ٥. الـ "Speed" (السرعة)
- Loading states واضحة (skeleton screens)
- Animations سريعة (٢٠٠ms max)
- Optimistic UI (الاكشن يبان قبل ما السيرفر يرد)

---

# 💬 برومبت كامل لـ Claude Code

```markdown
# مهمة: تحويل AlSaeb CRM لتقليد Pixxi بالكامل (UI/UX)

## قبل ما تبدأ - مهم!
1. اقرأ templates/admin.html كامل
2. اقرأ templates/agent.html كامل
3. اقرأ static/i18n.js
4. قولي إيه الحاجات اللي محتاجة تتغير

## الفلسفة العامة
Pixxi معروف بـ:
- بساطة + نظافة
- spacing كبير
- ألوان قليلة (أزرق + رمادي + أبيض)
- سرعة في التحميل
- نفس الـ design في كل صفحة

## Phase 1: Foundation (يوم واحد)

### 1.1 الألوان
استبدل كل الألوان الحالية بالـ palette ده:
- Primary: #1D4ED8 (أزرق)
- Background: #F9FAFB
- Card: #FFFFFF
- Text: #111827
- Border: #E5E7EB

### 1.2 الـ Typography
- خط: Inter (للإنجليزي) + Cairo (للعربي)
- استخدم النظام الموحد:
  - 11px (xs)
  - 13px (sm)
  - 14px (base)
  - 16px (lg)
  - 18px (xl)
  - 24px (2xl)

### 1.3 الـ Spacing
- استخدم نظام 4px (4, 8, 12, 16, 24, 32, 48, 64)
- كل كارد padding 20-24px
- كل قسم margin-bottom 24px

## Phase 2: Layout (يوم واحد)

### 2.1 الـ Sidebar
أعد تصميم الـ sidebar بالكامل:
- عرض 250px
- خلفية بيضاء
- 3 sections:
  - MAIN (Leads, Listings, Owners, Off-Plan, Transactions)
  - TOOLS (Map, Calendar, KPI, Approvals)
  - AUTOMATION (Lead Rotation, Custom Fields, Workflow)
- الـ Gamification في item منفصل تحت كل ده "Game Mode"

### 2.2 الـ Top Bar
- height: 60px
- خلفية بيضاء + border-bottom
- Search bar كبير في الوسط (400px)
- Notifications bell + User menu يمين

### 2.3 الـ Main Content
- padding: 24px
- max-width: 1400px
- خلفية #F9FAFB

## Phase 3: Pages (3 أيام)

### 3.1 Dashboard
- 4 KPI cards في صف
- Sales pipeline chart
- Recent activity sidebar
- Top performers table

### 3.2 Leads Page
- 3 views: List, Kanban, Calendar
- Kanban بـ drag & drop
- Filters في bar علوي
- Search بـ instant results
- Each lead row: avatar, name, phone, source, status, agent

### 3.3 Lead Profile (3 columns)
- Column 1 (300px): Profile info + Fields + Tags
- Column 2 (flex): Activity timeline
- Column 3 (300px): Quick actions + Related items

### 3.4 Listings Page
- Grid view (default): 3 columns
- List view: table
- Map view: full screen
- Card design زي العقارات في بورتالز

### 3.5 Transactions Page
- Stats bar في الأعلى
- Table مع status filters
- Approval workflow visible

## Phase 4: Components (يوم واحد)

اعمل components موحدة وأعد استخدامها:
- Button (primary, secondary, danger)
- Input (text, select, date)
- Card
- Badge
- Table
- Modal
- Toast
- Dropdown

## Phase 5: Gamification Separation (يوم واحد)

افصل كل عناصر اللعب في tab منفصل:
- نقل XP, Coins, Badges, Quests, Leaderboard
- في الـ CRM الأساسي:
  - فقط XP badge صغير في الكورنر
  - لما اللاعب يكسب نقاط → toast notification صغير
  - مفيش confetti أو ألعاب وسط الشغل

## ملاحظات مهمة

### Don't:
- ❌ متشيلش أي feature موجودة
- ❌ متغيرش الـ APIs
- ❌ متغيرش الـ DB schema
- ❌ متضيفش features جديدة (بس rebrand)

### Do:
- ✅ احفظ كل feature موجودة
- ✅ غير الـ UI فقط
- ✅ خلي الشكل nettle ومريح
- ✅ test على mobile + desktop
- ✅ commit بعد كل phase

## النتيجة المطلوبة
بعد ما تخلص، النظام لازم يحس:
- نظيف زي Pixxi
- منظم زي Pixxi
- سهل التنقل زي Pixxi
- لكن **مع الـ Gamification في tab منفصل**

## بعد كل Phase
قولي:
1. إيه عملت
2. screenshot قبل/بعد
3. هل في مشاكل
```

---

# 📚 مصادر للإلهام

## مواقع شبيهة بـ Pixxi:
- **pixxicrm.com** - المرجع الرسمي
- **bayut.com** - للـ listings design
- **propertyfinder.ae** - للـ search UX
- **dubizzle.com** - للـ filters

## مكتبات UI جاهزة (ممكن تستخدم منها):
- **shadcn/ui** (للـ React) - مجاني
- **Tailwind UI** - مدفوع لكن جودة عالية
- **Radix UI** - components مجانية

## الـ Icons:
- **Heroicons** (heroicons.com) - مجاني
- **Lucide** (lucide.dev) - مجاني
- **Phosphor Icons** - مجاني

---

# 📋 Checklist للتسليم

## التصميم العام
- [ ] الألوان مطابقة للـ palette
- [ ] الخط Inter + Cairo
- [ ] الـ spacing موحد
- [ ] الـ shadows لطيفة (مش قوية)

## الـ Sidebar
- [ ] منظم في 3 sections
- [ ] Active state واضح
- [ ] Badges للأعداد
- [ ] Gamification منفصل

## الـ Top Bar
- [ ] Search bar كبير
- [ ] Notifications يشتغل
- [ ] User menu يفتح

## الـ Pages
- [ ] Dashboard فيه 4 KPIs + charts
- [ ] Leads فيه 3 views
- [ ] Lead Profile 3 columns
- [ ] Listings grid + map
- [ ] Transactions table

## الـ Components
- [ ] Buttons موحدة
- [ ] Inputs موحدة
- [ ] Cards موحدة
- [ ] Modals تفتح smoothly

## الـ Performance
- [ ] Loading states (skeletons)
- [ ] Animations سريعة
- [ ] No lag
- [ ] Mobile responsive

## الـ Gamification
- [ ] منفصل في tab خاص
- [ ] في الـ CRM فقط badge صغير
- [ ] الـ notifications subtle
- [ ] مفيش confetti في وسط الشغل

---

*آخر تحديث: مايو ٢٠٢٦*
*المرجع: pixxicrm.com*
*الهدف: AlSaeb يحس Pixxi 100%*
