/* ═══════════════════════════════════════════════════════════
   AL SAEB CRM — i18n (Arabic / English)
   Usage:
     <element data-i18n="key">عربي default</element>
     <input data-i18n-placeholder="key" placeholder="..."/>
     <element data-i18n-title="key" title="..."/>
   Then call: applyI18n();
   Toggle: setLang('en') | setLang('ar')
   ═══════════════════════════════════════════════════════════ */

const I18N = {
  ar: {
    // ─── Navigation ───
    nav_dashboard: 'لوحة التحكم',
    nav_leads: 'الليدز',
    nav_listings: 'العقارات',
    nav_owners: 'الملاك',
    nav_transactions: 'العمليات',
    nav_offplan: 'مشاريع قيد الإنشاء',
    nav_projects: 'المشاريع',
    nav_ads: 'الإعلانات',
    nav_team: 'الفريق',
    nav_attendance: 'الحضور',
    nav_monthly_attendance: 'الحضور الشهري',
    nav_webhooks: 'وصلات الربط',
    nav_leaderboard: 'لوحة الشرف',
    nav_feed: 'النشاطات',
    nav_audit: 'سجل الأدمن',
    nav_rotation: 'التوزيع',
    nav_workflow: 'سير العمل',
    nav_kpi: 'مؤشرات الأداء',
    nav_map: 'الخريطة',
    nav_customfields: 'الحقول المخصصة',
    nav_database: 'قاعدة البيانات',
    nav_distribute: 'توزيع الليدز',
    nav_game_events: 'أحداث اللعبة',
    // ─── Common ───
    home: 'الرئيسية',
    settings: 'إعدادات',
    logout: 'خروج',
    login: 'دخول',
    save: 'حفظ',
    cancel: 'إلغاء',
    delete: 'حذف',
    edit: 'تعديل',
    add: 'إضافة',
    search: 'بحث',
    filter: 'تصفية',
    close: 'إغلاق',
    confirm: 'تأكيد',
    yes: 'نعم',
    no: 'لا',
    loading: 'جاري التحميل...',
    no_data: 'لا توجد بيانات',
    actions: 'إجراءات',
    name: 'الاسم',
    email: 'الإيميل',
    phone: 'الموبايل',
    role: 'الدور',
    status: 'الحالة',
    created_at: 'تاريخ الإنشاء',
    updated_at: 'آخر تحديث',
    notes: 'ملاحظات',
    description: 'الوصف',
    type: 'النوع',
    price: 'السعر',
    quantity: 'الكمية',
    total: 'الإجمالي',
    date: 'التاريخ',
    time: 'الوقت',
    today: 'اليوم',
    yesterday: 'أمس',
    week: 'الأسبوع',
    month: 'الشهر',
    year: 'السنة',
    welcome: 'أهلاً',
    overview: 'نظرة عامة',
    admin_panel: 'لوحة تحكم الأدمن',
    employee_page: 'صفحة الموظف',
    password: 'كلمة السر',
    forgot_password: 'نسيت كلمة السر؟',
    // ─── Agent UI ───
    level: 'مستوى',
    xp: 'XP',
    coins: 'عملات',
    energy: 'طاقة',
    stamina: 'الطاقة',
    streak: 'متواصل',
    days_in_row: 'يوم متواصل',
    claim_bonus: 'استلم',
    daily_bonus: 'بونص يومي',
    check_in: 'وصلت',
    check_out: 'انصراف',
    attendance_log: 'تسجيل الحضور',
    arrival_logged: 'سجل وصولك للمكتب',
    quests: 'مهمات',
    your_quests_today: 'مهماتك اليوم',
    new_whatsapp: 'رسائل واتساب جديدة',
    no_new_messages: 'لا يوجد رسائل جديدة',
    your_rank: 'ترتيبك',
    badges: 'الشارات',
    notifications: 'الإشعارات',
    clear_all: 'مسح الكل',
    no_notifications: 'لا يوجد إشعارات',
    work_time: 'وقت العمل',
    deals: 'الصفقات',
    deal: 'صفقة',
    calls: 'مكالمات',
    call: 'مكالمة',
    messages: 'رسائل',
    message: 'رسالة',
    today_msgs: 'رسالة اليوم',
    today_calls: 'مكالمة اليوم',
    today_deals: 'صفقة اليوم',
    professional_mode: 'الوضع الاحترافي',
    game_mode: 'وضع اللعبة',
    // ─── Status labels ───
    status_new: 'جديد',
    status_contacted: 'تم التواصل',
    status_interested: 'مهتم',
    status_meeting_set: 'اجتماع محدد',
    status_negotiation: 'تفاوض',
    status_closed_won: 'فاز 🏆',
    status_closed_lost: 'خسارة',
    // ─── Leads ───
    leads: 'الليدز',
    add_lead: 'إضافة ليد',
    lead_name: 'اسم الليد',
    lead_phone: 'الموبايل',
    lead_source: 'المصدر',
    lead_assigned_to: 'المسؤول',
    lead_status: 'الحالة',
    import_excel: 'استيراد Excel',
    export_excel: 'تصدير Excel',
    // ─── Theme toggle ───
    theme_dark: 'الوضع الداكن',
    theme_light: 'الوضع الفاتح',
    lang_arabic: 'العربية',
    lang_english: 'English',
    // ─── Misc agent ───
    back_to_crm: '← CRM',
    back: 'رجوع',
    games: 'الألعاب',
    map: 'الخريطة',
    store: 'المتجر',
    // ─── Modal ───
    crm_modal: 'CRM',
    leaderboard: 'لوحة المتصدرين',
    break_room: 'غرفة الاستراحة',
    rest_recharge: 'استريح، اشحن طاقتك',
    return_to_work: 'عودة للعمل',
    // ─── Map / Tower ───
    map_tower_title: 'برج النجاح',
    map_current_xp: 'XP حالي',
    map_xp_for_next: 'XP للمستوى القادم',
    map_coin_label: 'عملة',
    map_deal_label: 'صفقة',
    map_milestone_label: 'محطة',
    map_next_milestone: 'المحطة القادمة',
    map_help_title: '🏢 برج AL SAEB — رحلتك للقمة',
    map_help_text: 'كل ما تكسب XP، بتتقدم خطوة في البرج وتفتح محطة جديدة بإسم منطقة من دبي. كل محطة بتديك لقب جديد + كافأة. اضغط على أي محطة لتعرف تفاصيلها.',
    map_legend_unlocked: 'مفتوحة',
    map_legend_current: 'الحالية',
    map_legend_locked: 'مقفولة',
    go_to_car: 'روح لمحطتي',
    map_claim_reward: '🎁 احصل على الكافأة',
    map_claimed: '✅ تم الاستلام',
    map_status_unlocked: '✅ مفتوحة',
    map_status_current: '🎯 الحالية',
    map_status_locked: '🔒 مقفولة',
    map_district: 'المنطقة',
    map_level_req: 'المستوى المطلوب',
    map_xp_req: 'XP المطلوب',
    map_streets: '🛣️ الشوارع',
    map_cafes: '☕ كافيهات ومطاعم',
    map_rewards: '🎁 الكافآت',
    map_xp_bonus: 'XP بونس',
    map_coins_reward: 'عملات',
    map_branches_title: '🎯 فروع المهارة',
    map_branches_subtitle: 'أكمل فرع وخد كافأة إضافية',
    map_branch_calls: 'سيد المكالمات',
    map_branch_whatsapp: 'ساحر الواتساب',
    map_branch_meetings: 'محترف الاجتماعات',
    map_branch_big_deals: 'صائد الصفقات الكبيرة',
    map_branch_calls_desc: 'اعمل 10 مكالمات',
    map_branch_whatsapp_desc: 'ابعت 50 رسالة',
    map_branch_meetings_desc: 'احجز 20 اجتماع',
    map_branch_big_deals_desc: 'اقفل صفقة بقيمة 1 مليون+',
    map_claim_success: '🏆 تم استلام الكافأة!',
    map_claim_failed: 'فشل استلام الكافأة',
    map_already_claimed: 'تم الاستلام مسبقاً',
    map_not_eligible: 'لسه ما وصلتش الـ XP المطلوب',
    map_not_completed: 'لسه ما اكتملش',
  },
  en: {
    // ─── Navigation ───
    nav_dashboard: 'Dashboard',
    nav_leads: 'Leads',
    nav_listings: 'Listings',
    nav_owners: 'Owners',
    nav_transactions: 'Transactions',
    nav_offplan: 'Off-plan',
    nav_projects: 'Projects',
    nav_ads: 'Ads',
    nav_team: 'Team',
    nav_attendance: 'Attendance',
    nav_monthly_attendance: 'Monthly Attendance',
    nav_webhooks: 'Webhooks',
    nav_leaderboard: 'Leaderboard',
    nav_feed: 'Activity Feed',
    nav_audit: 'Audit Log',
    nav_rotation: 'Lead Rotation',
    nav_workflow: 'Workflow',
    nav_kpi: 'KPI',
    nav_map: 'Map',
    nav_customfields: 'Custom Fields',
    nav_database: 'Database',
    nav_distribute: 'Distribute Leads',
    nav_game_events: 'Game Events',
    // ─── Common ───
    home: 'Home',
    settings: 'Settings',
    logout: 'Logout',
    login: 'Login',
    save: 'Save',
    cancel: 'Cancel',
    delete: 'Delete',
    edit: 'Edit',
    add: 'Add',
    search: 'Search',
    filter: 'Filter',
    close: 'Close',
    confirm: 'Confirm',
    yes: 'Yes',
    no: 'No',
    loading: 'Loading...',
    no_data: 'No data',
    actions: 'Actions',
    name: 'Name',
    email: 'Email',
    phone: 'Phone',
    role: 'Role',
    status: 'Status',
    created_at: 'Created',
    updated_at: 'Updated',
    notes: 'Notes',
    description: 'Description',
    type: 'Type',
    price: 'Price',
    quantity: 'Quantity',
    total: 'Total',
    date: 'Date',
    time: 'Time',
    today: 'Today',
    yesterday: 'Yesterday',
    week: 'Week',
    month: 'Month',
    year: 'Year',
    welcome: 'Welcome',
    overview: 'Overview',
    admin_panel: 'Admin Panel',
    employee_page: 'Employee Page',
    password: 'Password',
    forgot_password: 'Forgot password?',
    // ─── Agent UI ───
    level: 'Level',
    xp: 'XP',
    coins: 'Coins',
    energy: 'Energy',
    stamina: 'Stamina',
    streak: 'streak',
    days_in_row: 'day streak',
    claim_bonus: 'Claim',
    daily_bonus: 'Daily bonus',
    check_in: 'Check in',
    check_out: 'Check out',
    attendance_log: 'Attendance',
    arrival_logged: 'Log your office arrival',
    quests: 'Quests',
    your_quests_today: 'Your quests today',
    new_whatsapp: 'New WhatsApp messages',
    no_new_messages: 'No new messages',
    your_rank: 'Your Rank',
    badges: 'Badges',
    notifications: 'Notifications',
    clear_all: 'Clear all',
    no_notifications: 'No notifications',
    work_time: 'Work time',
    deals: 'Deals',
    deal: 'Deal',
    calls: 'Calls',
    call: 'Call',
    messages: 'Messages',
    message: 'Message',
    today_msgs: 'Today messages',
    today_calls: 'Today calls',
    today_deals: 'Today deals',
    professional_mode: 'Professional Mode',
    game_mode: 'Game Mode',
    // ─── Status labels ───
    status_new: 'New',
    status_contacted: 'Contacted',
    status_interested: 'Interested',
    status_meeting_set: 'Meeting Set',
    status_negotiation: 'Negotiation',
    status_closed_won: 'Closed Won 🏆',
    status_closed_lost: 'Closed Lost',
    // ─── Leads ───
    leads: 'Leads',
    add_lead: 'Add Lead',
    lead_name: 'Lead Name',
    lead_phone: 'Phone',
    lead_source: 'Source',
    lead_assigned_to: 'Assigned to',
    lead_status: 'Status',
    import_excel: 'Import Excel',
    export_excel: 'Export Excel',
    // ─── Theme toggle ───
    theme_dark: 'Dark Mode',
    theme_light: 'Light Mode',
    lang_arabic: 'العربية',
    lang_english: 'English',
    // ─── Misc agent ───
    back_to_crm: 'CRM →',
    back: 'Back',
    games: 'Games',
    map: 'Map',
    store: 'Store',
    // ─── Modal ───
    crm_modal: 'CRM',
    leaderboard: 'Leaderboard',
    break_room: 'Break Room',
    rest_recharge: 'Rest, recharge your energy',
    return_to_work: 'Return to work',
    // ─── Map / Tower ───
    map_tower_title: 'Tower of Success',
    map_current_xp: 'XP',
    map_xp_for_next: 'XP for next level',
    map_coin_label: 'coins',
    map_deal_label: 'deals',
    map_milestone_label: 'station',
    map_next_milestone: 'NEXT MILESTONE',
    map_help_title: '🏢 AL SAEB Tower — Your Journey to the Top',
    map_help_text: 'As you earn XP, you climb the tower and unlock new stations named after Dubai districts. Each station grants a new title plus rewards. Tap any station to see details.',
    map_legend_unlocked: 'unlocked',
    map_legend_current: 'current',
    map_legend_locked: 'locked',
    go_to_car: 'Go to my station',
    map_claim_reward: '🎁 Claim Reward',
    map_claimed: '✅ Claimed',
    map_status_unlocked: '✅ Unlocked',
    map_status_current: '🎯 Current',
    map_status_locked: '🔒 Locked',
    map_district: 'District',
    map_level_req: 'Level Required',
    map_xp_req: 'XP Required',
    map_streets: '🛣️ Streets',
    map_cafes: '☕ Cafes & Restaurants',
    map_rewards: '🎁 Rewards',
    map_xp_bonus: 'XP Bonus',
    map_coins_reward: 'coins',
    map_branches_title: '🎯 Skill Branches',
    map_branches_subtitle: 'Master a branch for a bonus reward',
    map_branch_calls: 'Master Caller',
    map_branch_whatsapp: 'WhatsApp Wizard',
    map_branch_meetings: 'Meeting Pro',
    map_branch_big_deals: 'Big Deal Closer',
    map_branch_calls_desc: 'Make 10 calls',
    map_branch_whatsapp_desc: 'Send 50 messages',
    map_branch_meetings_desc: 'Book 20 meetings',
    map_branch_big_deals_desc: 'Close a 1M+ deal',
    map_claim_success: '🏆 Reward claimed!',
    map_claim_failed: 'Failed to claim reward',
    map_already_claimed: 'Already claimed',
    map_not_eligible: 'Not enough XP yet',
    map_not_completed: 'Not yet completed',
  },
};

// Get current language (defaults to Arabic)
function getLang() {
  return localStorage.getItem('alsaeb_lang') || 'ar';
}

// Translate a single key
function t(key, lang) {
  lang = lang || getLang();
  return (I18N[lang] && I18N[lang][key]) || (I18N.ar[key]) || key;
}

// Apply translations to all elements with data-i18n* attributes
function applyI18n(lang) {
  lang = lang || getLang();
  const dict = I18N[lang] || I18N.ar;
  // Text content
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (dict[key]) el.textContent = dict[key];
  });
  // Placeholder
  document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
    const key = el.getAttribute('data-i18n-placeholder');
    if (dict[key]) el.setAttribute('placeholder', dict[key]);
  });
  // Title attribute
  document.querySelectorAll('[data-i18n-title]').forEach(el => {
    const key = el.getAttribute('data-i18n-title');
    if (dict[key]) el.setAttribute('title', dict[key]);
  });
  // Aria-label
  document.querySelectorAll('[data-i18n-aria]').forEach(el => {
    const key = el.getAttribute('data-i18n-aria');
    if (dict[key]) el.setAttribute('aria-label', dict[key]);
  });
  // Direction
  document.documentElement.setAttribute('lang', lang);
  document.documentElement.setAttribute('dir', lang === 'en' ? 'ltr' : 'rtl');
}

function setLang(lang) {
  if (lang !== 'ar' && lang !== 'en') return;
  localStorage.setItem('alsaeb_lang', lang);
  applyI18n(lang);
  // Update lang toggle button text
  const btn = document.getElementById('lang-toggle-label');
  if (btn) btn.textContent = lang === 'ar' ? 'EN' : 'ع';
  // Fire event so the app can re-render dynamic content
  window.dispatchEvent(new CustomEvent('langchange', { detail: { lang } }));
}

function toggleLang() {
  setLang(getLang() === 'ar' ? 'en' : 'ar');
}

// Apply immediately on script load to avoid flash
(function() {
  const lang = getLang();
  document.documentElement.setAttribute('lang', lang);
  document.documentElement.setAttribute('dir', lang === 'en' ? 'ltr' : 'rtl');
})();

document.addEventListener('DOMContentLoaded', () => {
  applyI18n();
  const btn = document.getElementById('lang-toggle-label');
  if (btn) btn.textContent = getLang() === 'ar' ? 'EN' : 'ع';
});

// Expose globals
window.t = t;
window.applyI18n = applyI18n;
window.setLang = setLang;
window.toggleLang = toggleLang;
window.getLang = getLang;
