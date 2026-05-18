"""
🎮 AlSaeb CRM - Lead Importer
========================================
سكريبت لاستيراد الليدز من ملف إكسل وتنظيفها وإدخالها في Supabase

الاستخدام:
  python import_leads.py --file عمرو.xlsx --supabase-url YOUR_URL --supabase-key YOUR_KEY

  أو بدون Supabase (تصدير SQL):
  python import_leads.py --file عمرو.xlsx --output-sql
"""

import argparse
import json
import re
import sys
from pathlib import Path

try:
    import openpyxl
except ImportError:
    print("❌ pip install openpyxl")
    sys.exit(1)


# ==================== Phone Cleaning ====================

def clean_phone(raw_phone):
    """تنظيف رقم التليفون وتوحيد الفورمات"""
    if not raw_phone:
        return None, None

    phone_str = str(raw_phone).strip()

    # لو فيه أرقام متعددة (مفصولة بـ / أو -)
    if '/' in phone_str:
        phones = phone_str.split('/')
        phone_str = phones[0].strip()  # خد الأول

    # شيل أي حروف أو رموز غير الأرقام و +
    phone_str = re.sub(r'[^\d+]', '', phone_str)

    # شيل الأصفار الزيادة في الأول
    if phone_str.startswith('00'):
        phone_str = phone_str[2:]

    if not phone_str or len(phone_str) < 7:
        return None, None

    # استنتاج كود الدولة
    country_code = detect_country_code(phone_str)

    return phone_str, country_code


def detect_country_code(phone):
    """استنتاج كود الدولة من الرقم"""
    if not phone:
        return None

    # UAE: 971 أو أرقام محلية (05x)
    if phone.startswith('971'):
        return '+971'
    if (phone.startswith('50') or phone.startswith('55') or phone.startswith('56') or
            phone.startswith('52') or phone.startswith('54') or phone.startswith('58')) and len(phone) == 9:
        return '+971'

    # India: 91
    if phone.startswith('91') and len(phone) >= 12:
        return '+91'

    # Saudi: 966
    if phone.startswith('966'):
        return '+966'

    # Qatar: 974
    if phone.startswith('974'):
        return '+974'

    # UK: 44
    if phone.startswith('44'):
        return '+44'

    # US/Canada: 1
    if phone.startswith('1') and len(phone) == 11:
        return '+1'

    # South Africa: 27
    if phone.startswith('27'):
        return '+27'

    # Romania: 38
    if phone.startswith('381'):
        return '+381'

    # Iran: 98
    if phone.startswith('98') and len(phone) >= 12:
        return '+98'

    # Default: اعتبره UAE محلي
    if len(phone) == 9 and phone[0] == '5':
        return '+971'

    return None


# ==================== Project Normalization ====================

PROJECT_MAP = {
    'samana': 'Samana',
    'verdana': 'Verdana',
    'barari': 'Al Barari',
    'albarari': 'Al Barari',
    'silicon': 'Silicon Oasis',
    'slicon oasis': 'Silicon Oasis',
    'silicon oasis': 'Silicon Oasis',
    'massar': 'Massar',
    'binghatti': 'Binghatti',
    'azizi': 'Azizi',
    'damac island': 'DAMAC Island',
    'butterfly': 'Butterfly',
    'riviera': 'Riviera',
    'tiger': 'Tiger',
    'district': 'The District',
    'the district': 'The District',
    'sport city': 'Sport City',
    'taowermina': 'Taormina',
    'ready': 'Ready',
    'offices samana': 'Samana Offices',
    'samana offices': 'Samana Offices',
    'barari offices': 'Al Barari Offices',
    'alsaadyat': 'Reportage Al Saadiyat',
    'new project of reportage': 'Reportage Al Saadiyat',
    'new project of reportage alsaadyat island': 'Reportage Al Saadiyat',
    'new project of reportage on alsaadyat island': 'Reportage Al Saadiyat',
    'project in al reem island': 'Al Reem Island Project',
}


def normalize_project(raw_project):
    """توحيد أسماء المشاريع"""
    if not raw_project:
        return None

    clean = str(raw_project).strip().lower()
    return PROJECT_MAP.get(clean, raw_project.strip().title())


# ==================== Excel Reader ====================

def read_excel(file_path):
    """قراءة ملف الإكسل واستخراج الليدز"""
    wb = openpyxl.load_workbook(file_path, read_only=True)
    ws = wb.active

    leads = []
    seen_phones = set()
    skipped = 0
    duplicates = 0

    for row in ws.iter_rows(values_only=True):
        name_raw, phone_raw, project_raw = (
            row[0] if len(row) > 0 else None,
            row[1] if len(row) > 1 else None,
            row[2] if len(row) > 2 else None,
        )

        # لازم يكون في رقم
        if not phone_raw:
            skipped += 1
            continue

        phone_clean, country_code = clean_phone(phone_raw)

        if not phone_clean:
            skipped += 1
            continue

        # تشيك التكرار
        if phone_clean in seen_phones:
            duplicates += 1
            continue
        seen_phones.add(phone_clean)

        # تنظيف الاسم
        name = None
        if name_raw:
            name = str(name_raw).strip()
            # تجاهل الأسماء اللي هي مجرد ملاحظات
            if name.lower() in ['dv', 'انحليزي', '']:
                name = None
            elif name:
                name = name.title()

        # تنظيف المشروع
        project = normalize_project(project_raw)

        leads.append({
            'phone': str(phone_raw).strip(),
            'phone_clean': phone_clean,
            'name': name,
            'country_code': country_code,
            'project': project,
            'source': 'excel_import',
            'imported_from': Path(file_path).name,
        })

    wb.close()
    return leads, skipped, duplicates


# ==================== SQL Generator ====================

def generate_sql(leads, projects):
    """توليد SQL للإدخال"""
    sql_lines = []

    sql_lines.append("-- ==================== Import Projects ====================\n")
    for proj_name in sorted(projects):
        slug = re.sub(r'[^a-z0-9]+', '_', proj_name.lower()).strip('_')
        sql_lines.append(
            f"INSERT INTO projects (name, slug, status) "
            f"VALUES ('{proj_name}', '{slug}', 'active') "
            f"ON CONFLICT (slug) DO NOTHING;"
        )

    sql_lines.append("\n-- ==================== Import Leads ====================\n")
    for lead in leads:
        name_sql = f"'{lead['name']}'" if lead['name'] else 'NULL'
        country_sql = f"'{lead['country_code']}'" if lead['country_code'] else 'NULL'
        project_sub = 'NULL'
        if lead['project']:
            slug = re.sub(r'[^a-z0-9]+', '_', lead['project'].lower()).strip('_')
            project_sub = f"(SELECT id FROM projects WHERE slug = '{slug}')"

        sql_lines.append(
            f"INSERT INTO leads (phone, phone_clean, name, country_code, project_id, source, imported_from) "
            f"VALUES ('{lead['phone']}', '{lead['phone_clean']}', {name_sql}, {country_sql}, "
            f"{project_sub}, 'excel_import', '{lead['imported_from']}') "
            f"ON CONFLICT DO NOTHING;"
        )

    return '\n'.join(sql_lines)


# ==================== Supabase Uploader ====================

def upload_to_supabase(leads, projects, supabase_url, supabase_key, ad_tags=None):
    """رفع الداتا مباشرة على Supabase"""
    try:
        from supabase import create_client
    except ImportError:
        print("❌ pip install supabase")
        sys.exit(1)

    client = create_client(supabase_url, supabase_key)

    # 1. أدخل المشاريع
    print("📁 إدخال المشاريع...")
    project_ids = {}
    for proj_name in projects:
        slug = re.sub(r'[^a-z0-9]+', '_', proj_name.lower()).strip('_')
        result = client.table('projects').upsert({
            'name': proj_name,
            'slug': slug,
            'status': 'active'
        }, on_conflict='slug').execute()

        if result.data:
            project_ids[proj_name] = result.data[0]['id']
            print(f"  ✅ {proj_name}")

    # 2. أدخل الليدز
    print(f"\n📱 إدخال {len(leads)} ليد...")
    batch_size = 50
    inserted = 0

    for i in range(0, len(leads), batch_size):
        batch = leads[i:i + batch_size]
        records = []

        for lead in batch:
            record = {
                'phone': lead['phone'],
                'phone_clean': lead['phone_clean'],
                'name': lead['name'],
                'country_code': lead['country_code'],
                'source': lead['source'],
                'imported_from': lead['imported_from'],
                'status': 'new',
                'quality': 'cold',
            }

            if lead['project'] and lead['project'] in project_ids:
                record['project_id'] = project_ids[lead['project']]

            # ربط بإعلان + UTM
            if ad_tags:
                for k in ('ad_campaign_id', 'utm_source', 'utm_medium', 'utm_campaign'):
                    if ad_tags.get(k):
                        record[k] = ad_tags[k]

            records.append(record)

        try:
            result = client.table('leads').insert(records).execute()
            inserted += len(result.data) if result.data else 0
            print(f"  📦 Batch {i // batch_size + 1}: {len(records)} leads")
        except Exception as e:
            print(f"  ❌ Batch error: {e}")

    return inserted


# ==================== Main ====================

def main():
    parser = argparse.ArgumentParser(description='🎮 AlSaeb CRM - Lead Importer')
    parser.add_argument('--file', required=True, help='ملف الإكسل')
    parser.add_argument('--supabase-url', help='Supabase URL')
    parser.add_argument('--supabase-key', help='Supabase Service Key')
    parser.add_argument('--output-sql', action='store_true', help='صدّر كـ SQL بدل Supabase')
    parser.add_argument('--output-json', action='store_true', help='صدّر كـ JSON')
    parser.add_argument('--ad-campaign-id', help='UUID إعلان لربطه بالليدز المستوردة')
    parser.add_argument('--utm-source', help='UTM source tag')
    parser.add_argument('--utm-medium', help='UTM medium tag')
    parser.add_argument('--utm-campaign', help='UTM campaign tag')
    args = parser.parse_args()

    print("🎮 AlSaeb CRM - Lead Importer")
    print("=" * 50)

    # قراءة الملف
    print(f"\n📂 قراءة الملف: {args.file}")
    leads, skipped, duplicates = read_excel(args.file)

    # استخراج المشاريع الفريدة
    projects = set()
    for lead in leads:
        if lead['project']:
            projects.add(lead['project'])

    # إحصائيات
    with_name = sum(1 for lead in leads if lead['name'])
    with_project = sum(1 for lead in leads if lead['project'])
    uae = sum(1 for lead in leads if lead['country_code'] == '+971')
    india = sum(1 for lead in leads if lead['country_code'] == '+91')
    saudi = sum(1 for lead in leads if lead['country_code'] == '+966')

    print("\n📊 النتائج:")
    print(f"  ✅ ليدز صالحة: {len(leads)}")
    print(f"  ⏭️  متخطاة (بدون رقم): {skipped}")
    print(f"  🔄 مكررة: {duplicates}")
    print(f"  👤 بأسماء: {with_name}")
    print(f"  🏗️  بمشاريع: {with_project}")
    print(f"  🇦🇪 UAE: {uae}")
    print(f"  🇮🇳 India: {india}")
    print(f"  🇸🇦 Saudi: {saudi}")
    print(f"  🏗️  مشاريع فريدة: {len(projects)}")

    for proj in sorted(projects):
        count = sum(1 for lead in leads if lead['project'] == proj)
        print(f"     - {proj}: {count} leads")

    # التصدير
    if args.output_sql:
        sql = generate_sql(leads, projects)
        output_path = Path(args.file).stem + '_import.sql'
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(sql)
        print(f"\n💾 SQL محفوظ في: {output_path}")

    elif args.output_json:
        output_path = Path(args.file).stem + '_leads.json'
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(leads, f, ensure_ascii=False, indent=2)
        print(f"\n💾 JSON محفوظ في: {output_path}")

    elif args.supabase_url and args.supabase_key:
        ad_tags = {
            'ad_campaign_id': args.ad_campaign_id,
            'utm_source': args.utm_source,
            'utm_medium': args.utm_medium,
            'utm_campaign': args.utm_campaign,
        }
        inserted = upload_to_supabase(leads, projects, args.supabase_url, args.supabase_key, ad_tags)
        print(f"\n🚀 تم إدخال {inserted} ليد في Supabase!")

    else:
        print("\n⚠️  حدد طريقة التصدير: --output-sql أو --output-json أو --supabase-url + --supabase-key")


if __name__ == '__main__':
    main()
