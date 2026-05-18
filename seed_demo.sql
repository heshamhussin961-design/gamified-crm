-- =====================================================================
-- AlSaeb CRM — DEMO SEED DATA
-- Creates 5 test employees + 50 leads + sample actions for demo/testing
-- Run AFTER schema_complete.sql
-- Safe to re-run (uses ON CONFLICT DO NOTHING)
-- =====================================================================

-- ==================== DEMO EMPLOYEES ====================
-- Note: These use fixed UUIDs so they can be referenced by leads/actions.
-- In production, employees are created via Supabase Auth signup.
-- Passwords are managed by Supabase Auth, not stored here.

INSERT INTO employees (id, email, full_name, role, level, title, total_xp, current_xp, syb_coins, total_deals, total_leads, avatar_color, stamina, max_stamina, status)
VALUES
  ('a0000001-0000-0000-0000-000000000001', 'ahmed@alsaeb.demo', 'أحمد محمد', 'sales_agent', 8, 'Senior Closer', 7500, 500, 320, 15, 120, '#00e5ff', 100, 100, 'working'),
  ('a0000001-0000-0000-0000-000000000002', 'sara@alsaeb.demo', 'سارة خالد', 'sales_agent', 6, 'Lead Hunter', 5200, 200, 180, 8, 95, '#7c4dff', 80, 100, 'working'),
  ('a0000001-0000-0000-0000-000000000003', 'omar@alsaeb.demo', 'عمر حسن', 'sales_agent', 4, 'Rookie Caller', 3100, 100, 90, 3, 60, '#00e676', 60, 100, 'on_break'),
  ('a0000001-0000-0000-0000-000000000004', 'nour@alsaeb.demo', 'نور إبراهيم', 'sales_agent', 10, 'Deal Legend', 9800, 800, 550, 22, 150, '#ff6b35', 100, 100, 'working'),
  ('a0000001-0000-0000-0000-000000000005', 'admin@alsaeb.demo', 'المدير العام', 'admin', 15, 'Office Manager', 15000, 0, 1000, 0, 0, '#ffd700', 100, 100, 'working')
ON CONFLICT (id) DO NOTHING;

-- ==================== DEMO LEADS ====================

INSERT INTO leads (id, name, phone, email, status, source, assigned_to, quality, notes_count, contact_count, created_at)
VALUES
  -- Ahmed's leads (15)
  (gen_random_uuid(), 'محمد علي', '+201001000001', 'mali@test.com', 'new', 'facebook', 'a0000001-0000-0000-0000-000000000001', 'warm', 0, 0, now() - interval '2 days'),
  (gen_random_uuid(), 'فاطمة أحمد', '+201001000002', 'fatma@test.com', 'contacted', 'google', 'a0000001-0000-0000-0000-000000000001', 'hot', 1, 2, now() - interval '3 days'),
  (gen_random_uuid(), 'خالد سعيد', '+201001000003', 'khaled@test.com', 'interested', 'referral', 'a0000001-0000-0000-0000-000000000001', 'hot', 2, 5, now() - interval '5 days'),
  (gen_random_uuid(), 'ليلى حسين', '+201001000004', NULL, 'meeting_set', 'cold_call', 'a0000001-0000-0000-0000-000000000001', 'warm', 3, 3, now() - interval '1 day'),
  (gen_random_uuid(), 'يوسف كمال', '+201001000005', 'youssef@test.com', 'negotiation', 'website', 'a0000001-0000-0000-0000-000000000001', 'hot', 4, 8, now() - interval '7 days'),
  (gen_random_uuid(), 'ريم محمود', '+201001000006', NULL, 'closed_won', 'facebook', 'a0000001-0000-0000-0000-000000000001', 'hot', 5, 10, now() - interval '10 days'),
  (gen_random_uuid(), 'عادل فريد', '+201001000007', 'adel@test.com', 'new', 'google', 'a0000001-0000-0000-0000-000000000001', 'cold', 0, 0, now()),
  (gen_random_uuid(), 'منى عبدالله', '+201001000008', NULL, 'contacted', 'referral', 'a0000001-0000-0000-0000-000000000001', 'warm', 1, 1, now() - interval '1 day'),
  (gen_random_uuid(), 'حسام الدين', '+201001000009', 'hossam@test.com', 'new', 'facebook', 'a0000001-0000-0000-0000-000000000001', 'warm', 0, 0, now()),
  (gen_random_uuid(), 'سمير جمال', '+201001000010', NULL, 'interested', 'cold_call', 'a0000001-0000-0000-0000-000000000001', 'hot', 2, 4, now() - interval '4 days'),

  -- Sara's leads (12)
  (gen_random_uuid(), 'هدى سالم', '+201002000001', 'huda@test.com', 'new', 'google', 'a0000001-0000-0000-0000-000000000002', 'warm', 0, 0, now()),
  (gen_random_uuid(), 'طارق محمد', '+201002000002', NULL, 'contacted', 'facebook', 'a0000001-0000-0000-0000-000000000002', 'hot', 1, 3, now() - interval '2 days'),
  (gen_random_uuid(), 'أمل حسن', '+201002000003', 'amal@test.com', 'interested', 'website', 'a0000001-0000-0000-0000-000000000002', 'hot', 3, 6, now() - interval '4 days'),
  (gen_random_uuid(), 'كريم عادل', '+201002000004', NULL, 'meeting_set', 'referral', 'a0000001-0000-0000-0000-000000000002', 'warm', 2, 4, now() - interval '1 day'),
  (gen_random_uuid(), 'سلمى خالد', '+201002000005', 'salma@test.com', 'new', 'google', 'a0000001-0000-0000-0000-000000000002', 'cold', 0, 0, now()),
  (gen_random_uuid(), 'ياسر حمدي', '+201002000006', NULL, 'closed_won', 'facebook', 'a0000001-0000-0000-0000-000000000002', 'hot', 4, 9, now() - interval '8 days'),
  (gen_random_uuid(), 'رنا سعيد', '+201002000007', 'rana@test.com', 'contacted', 'cold_call', 'a0000001-0000-0000-0000-000000000002', 'warm', 1, 2, now() - interval '2 days'),
  (gen_random_uuid(), 'وليد أحمد', '+201002000008', NULL, 'new', 'website', 'a0000001-0000-0000-0000-000000000002', 'warm', 0, 0, now()),
  (gen_random_uuid(), 'نادية فوزي', '+201002000009', 'nadia@test.com', 'interested', 'google', 'a0000001-0000-0000-0000-000000000002', 'hot', 2, 5, now() - interval '3 days'),
  (gen_random_uuid(), 'حسين مصطفى', '+201002000010', NULL, 'negotiation', 'referral', 'a0000001-0000-0000-0000-000000000002', 'hot', 3, 7, now() - interval '6 days'),
  (gen_random_uuid(), 'دينا يوسف', '+201002000011', 'dina@test.com', 'new', 'facebook', 'a0000001-0000-0000-0000-000000000002', 'cold', 0, 0, now()),
  (gen_random_uuid(), 'مروان خالد', '+201002000012', NULL, 'contacted', 'cold_call', 'a0000001-0000-0000-0000-000000000002', 'warm', 1, 1, now() - interval '1 day'),

  -- Omar's leads (10)
  (gen_random_uuid(), 'آية محمود', '+201003000001', 'aya@test.com', 'new', 'facebook', 'a0000001-0000-0000-0000-000000000003', 'warm', 0, 0, now()),
  (gen_random_uuid(), 'بلال حسن', '+201003000002', NULL, 'contacted', 'google', 'a0000001-0000-0000-0000-000000000003', 'warm', 1, 2, now() - interval '2 days'),
  (gen_random_uuid(), 'جنا سالم', '+201003000003', 'jana@test.com', 'new', 'website', 'a0000001-0000-0000-0000-000000000003', 'cold', 0, 0, now()),
  (gen_random_uuid(), 'داليا أحمد', '+201003000004', NULL, 'interested', 'referral', 'a0000001-0000-0000-0000-000000000003', 'hot', 2, 4, now() - interval '3 days'),
  (gen_random_uuid(), 'إسلام فاروق', '+201003000005', 'islam@test.com', 'new', 'cold_call', 'a0000001-0000-0000-0000-000000000003', 'warm', 0, 0, now()),
  (gen_random_uuid(), 'فيروز حمدي', '+201003000006', NULL, 'contacted', 'facebook', 'a0000001-0000-0000-0000-000000000003', 'warm', 1, 1, now() - interval '1 day'),
  (gen_random_uuid(), 'غادة يوسف', '+201003000007', 'ghada@test.com', 'new', 'google', 'a0000001-0000-0000-0000-000000000003', 'cold', 0, 0, now()),
  (gen_random_uuid(), 'هاني محمد', '+201003000008', NULL, 'closed_won', 'referral', 'a0000001-0000-0000-0000-000000000003', 'hot', 3, 7, now() - interval '6 days'),
  (gen_random_uuid(), 'إيمان خالد', '+201003000009', 'iman@test.com', 'meeting_set', 'website', 'a0000001-0000-0000-0000-000000000003', 'hot', 2, 3, now() - interval '2 days'),
  (gen_random_uuid(), 'جابر سعيد', '+201003000010', NULL, 'new', 'facebook', 'a0000001-0000-0000-0000-000000000003', 'warm', 0, 0, now()),

  -- Nour's leads (13)
  (gen_random_uuid(), 'كوثر محمد', '+201004000001', 'kawthar@test.com', 'closed_won', 'google', 'a0000001-0000-0000-0000-000000000004', 'hot', 5, 12, now() - interval '14 days'),
  (gen_random_uuid(), 'لطفي أحمد', '+201004000002', NULL, 'closed_won', 'referral', 'a0000001-0000-0000-0000-000000000004', 'hot', 4, 10, now() - interval '12 days'),
  (gen_random_uuid(), 'ماجد حسن', '+201004000003', 'maged@test.com', 'negotiation', 'facebook', 'a0000001-0000-0000-0000-000000000004', 'hot', 3, 8, now() - interval '5 days'),
  (gen_random_uuid(), 'نبيلة سالم', '+201004000004', NULL, 'meeting_set', 'website', 'a0000001-0000-0000-0000-000000000004', 'warm', 2, 5, now() - interval '3 days'),
  (gen_random_uuid(), 'أسامة فريد', '+201004000005', 'osama@test.com', 'interested', 'cold_call', 'a0000001-0000-0000-0000-000000000004', 'hot', 2, 4, now() - interval '4 days'),
  (gen_random_uuid(), 'بسمة حمدي', '+201004000006', NULL, 'contacted', 'google', 'a0000001-0000-0000-0000-000000000004', 'warm', 1, 2, now() - interval '2 days'),
  (gen_random_uuid(), 'قاسم يوسف', '+201004000007', 'qasem@test.com', 'new', 'facebook', 'a0000001-0000-0000-0000-000000000004', 'warm', 0, 0, now()),
  (gen_random_uuid(), 'رشا محمود', '+201004000008', NULL, 'closed_won', 'referral', 'a0000001-0000-0000-0000-000000000004', 'hot', 4, 11, now() - interval '9 days'),
  (gen_random_uuid(), 'شريف أحمد', '+201004000009', 'sherif@test.com', 'negotiation', 'website', 'a0000001-0000-0000-0000-000000000004', 'hot', 3, 6, now() - interval '4 days'),
  (gen_random_uuid(), 'تامر خالد', '+201004000010', NULL, 'interested', 'google', 'a0000001-0000-0000-0000-000000000004', 'warm', 2, 3, now() - interval '2 days'),
  (gen_random_uuid(), 'أميرة سعيد', '+201004000011', 'amira@test.com', 'new', 'cold_call', 'a0000001-0000-0000-0000-000000000004', 'cold', 0, 0, now()),
  (gen_random_uuid(), 'وائل حسن', '+201004000012', NULL, 'contacted', 'facebook', 'a0000001-0000-0000-0000-000000000004', 'warm', 1, 1, now() - interval '1 day'),
  (gen_random_uuid(), 'ياسمين فوزي', '+201004000013', 'yasmin@test.com', 'closed_won', 'referral', 'a0000001-0000-0000-0000-000000000004', 'hot', 5, 13, now() - interval '11 days')
ON CONFLICT DO NOTHING;

-- ==================== DEMO ACTIONS LOG ====================
-- Sample actions for today so dashboard has data

INSERT INTO actions_log (employee_id, action, xp_earned, coins_earned, details, created_at)
VALUES
  -- Ahmed — 5 calls, 2 WhatsApps, 1 deal
  ('a0000001-0000-0000-0000-000000000001', 'call_made', 15, 0, '{"outcome":"answered","duration_seconds":120}', now() - interval '6 hours'),
  ('a0000001-0000-0000-0000-000000000001', 'call_made', 15, 0, '{"outcome":"answered","duration_seconds":90}', now() - interval '5 hours'),
  ('a0000001-0000-0000-0000-000000000001', 'call_made', 15, 0, '{"outcome":"no_answer"}', now() - interval '4 hours'),
  ('a0000001-0000-0000-0000-000000000001', 'call_made', 30, 0, '{"outcome":"answered","duration_seconds":180}', now() - interval '3 hours'),
  ('a0000001-0000-0000-0000-000000000001', 'call_made', 15, 0, '{"outcome":"voicemail"}', now() - interval '2 hours'),
  ('a0000001-0000-0000-0000-000000000001', 'whatsapp_sent', 10, 0, '{"message_preview":"مرحبا..."}', now() - interval '5 hours'),
  ('a0000001-0000-0000-0000-000000000001', 'whatsapp_sent', 10, 0, '{"message_preview":"شكرا..."}', now() - interval '3 hours'),
  ('a0000001-0000-0000-0000-000000000001', 'deal_closed', 500, 50, '{"deal_value":75000}', now() - interval '1 hour'),

  -- Sara — 8 calls, 1 deal
  ('a0000001-0000-0000-0000-000000000002', 'call_made', 15, 0, '{"outcome":"answered","duration_seconds":60}', now() - interval '7 hours'),
  ('a0000001-0000-0000-0000-000000000002', 'call_made', 15, 0, '{"outcome":"answered","duration_seconds":45}', now() - interval '6 hours'),
  ('a0000001-0000-0000-0000-000000000002', 'call_made', 15, 0, '{"outcome":"no_answer"}', now() - interval '5 hours'),
  ('a0000001-0000-0000-0000-000000000002', 'call_made', 30, 0, '{"outcome":"answered","duration_seconds":200}', now() - interval '4 hours'),
  ('a0000001-0000-0000-0000-000000000002', 'call_made', 15, 0, '{"outcome":"answered","duration_seconds":75}', now() - interval '4 hours'),
  ('a0000001-0000-0000-0000-000000000002', 'call_made', 15, 0, '{"outcome":"callback"}', now() - interval '3 hours'),
  ('a0000001-0000-0000-0000-000000000002', 'call_made', 15, 0, '{"outcome":"answered","duration_seconds":55}', now() - interval '2 hours'),
  ('a0000001-0000-0000-0000-000000000002', 'call_made', 15, 0, '{"outcome":"no_answer"}', now() - interval '1 hour'),
  ('a0000001-0000-0000-0000-000000000002', 'deal_closed', 750, 75, '{"deal_value":250000}', now() - interval '30 minutes'),

  -- Omar — 3 calls
  ('a0000001-0000-0000-0000-000000000003', 'call_made', 15, 0, '{"outcome":"answered","duration_seconds":30}', now() - interval '3 hours'),
  ('a0000001-0000-0000-0000-000000000003', 'call_made', 15, 0, '{"outcome":"no_answer"}', now() - interval '2 hours'),
  ('a0000001-0000-0000-0000-000000000003', 'whatsapp_sent', 10, 0, '{"message_preview":"مساء الخير..."}', now() - interval '1 hour'),

  -- Nour — 6 calls, 3 deals (top performer)
  ('a0000001-0000-0000-0000-000000000004', 'call_made', 30, 0, '{"outcome":"answered","duration_seconds":150}', now() - interval '7 hours'),
  ('a0000001-0000-0000-0000-000000000004', 'call_made', 30, 0, '{"outcome":"answered","duration_seconds":120}', now() - interval '6 hours'),
  ('a0000001-0000-0000-0000-000000000004', 'call_made', 15, 0, '{"outcome":"no_answer"}', now() - interval '5 hours'),
  ('a0000001-0000-0000-0000-000000000004', 'deal_closed', 500, 50, '{"deal_value":80000}', now() - interval '4 hours'),
  ('a0000001-0000-0000-0000-000000000004', 'call_made', 30, 0, '{"outcome":"answered","duration_seconds":180}', now() - interval '3 hours'),
  ('a0000001-0000-0000-0000-000000000004', 'deal_closed', 1000, 100, '{"deal_value":500000}', now() - interval '2 hours'),
  ('a0000001-0000-0000-0000-000000000004', 'call_made', 15, 0, '{"outcome":"answered","duration_seconds":90}', now() - interval '1 hour'),
  ('a0000001-0000-0000-0000-000000000004', 'deal_closed', 1500, 150, '{"deal_value":1200000}', now() - interval '30 minutes'),
  ('a0000001-0000-0000-0000-000000000004', 'call_made', 15, 0, '{"outcome":"callback"}', now() - interval '15 minutes')
ON CONFLICT DO NOTHING;

-- ==================== DEMO BADGES EARNED ====================

INSERT INTO user_badges (user_id, badge_id, earned_at)
SELECT 'a0000001-0000-0000-0000-000000000001', id, now() - interval '5 days'
FROM badges WHERE name = 'first_blood'
ON CONFLICT DO NOTHING;

INSERT INTO user_badges (user_id, badge_id, earned_at)
SELECT 'a0000001-0000-0000-0000-000000000004', id, now() - interval '3 days'
FROM badges WHERE name = 'first_blood'
ON CONFLICT DO NOTHING;

INSERT INTO user_badges (user_id, badge_id, earned_at)
SELECT 'a0000001-0000-0000-0000-000000000004', id, now() - interval '1 day'
FROM badges WHERE name = 'whale_hunter'
ON CONFLICT DO NOTHING;

INSERT INTO user_badges (user_id, badge_id, earned_at)
SELECT 'a0000001-0000-0000-0000-000000000002', id, now() - interval '2 days'
FROM badges WHERE name = 'first_blood'
ON CONFLICT DO NOTHING;

-- ==================== DEMO POSITIONS ====================

INSERT INTO positions (user_id, x, y, direction, scene)
VALUES
  ('a0000001-0000-0000-0000-000000000001', 10, 12, 'down', 'office'),
  ('a0000001-0000-0000-0000-000000000002', 16, 12, 'right', 'office'),
  ('a0000001-0000-0000-0000-000000000003', 4, 24, 'down', 'office'),
  ('a0000001-0000-0000-0000-000000000004', 22, 17, 'up', 'office')
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================================
-- DONE. Demo data ready. 5 employees, 50 leads, 30 actions, 4 badges.
-- =====================================================================
