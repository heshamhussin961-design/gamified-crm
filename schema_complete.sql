-- =====================================================================
-- AlSaeb CRM — COMPLETE DATABASE SCHEMA
-- Consolidated from: schema.sql → v2 → v3 → v4 → v5 → v6 → v7
-- Safe to run multiple times (IF NOT EXISTS / OR REPLACE / EXCEPTION)
-- Run this ONCE in Supabase Dashboard → SQL Editor → paste → Run
-- =====================================================================

-- ==================== ENUMS ====================
DO $$ BEGIN CREATE TYPE user_role AS ENUM ('admin', 'sales_agent'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE lead_status AS ENUM ('new', 'contacted', 'interested', 'meeting_set', 'negotiation', 'closed_won', 'closed_lost'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE action_type AS ENUM ('call_made', 'whatsapp_sent', 'deal_closed', 'note_added'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Extend enums (v2)
DO $$
BEGIN
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'whatsapp_received'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'call_received';     EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'meeting_booked';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'lead_upgraded';     EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'ai_hint_used';      EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'lead_locked';       EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'lead_unlocked';     EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'status_changed';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'quest_completed';   EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'item_purchased';    EXCEPTION WHEN OTHERS THEN NULL; END;
EXCEPTION WHEN OTHERS THEN NULL;
END$$;

DO $$ BEGIN BEGIN ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'manager'; EXCEPTION WHEN OTHERS THEN NULL; END; EXCEPTION WHEN OTHERS THEN NULL; END$$;

-- =====================================================================
-- CORE TABLES
-- =====================================================================

-- 1. Employees (Players)
CREATE TABLE IF NOT EXISTS employees (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT UNIQUE NOT NULL,
  full_name     TEXT NOT NULL,
  avatar_url    TEXT,
  role          user_role DEFAULT 'sales_agent',
  level         INT DEFAULT 1,
  title         TEXT DEFAULT 'Junior Scraper',
  total_xp      BIGINT DEFAULT 0,
  current_xp    BIGINT DEFAULT 0,
  syb_coins     BIGINT DEFAULT 0,
  total_deals   INT DEFAULT 0,
  total_leads   INT DEFAULT 0,
  is_active     BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- Employees: additional columns
ALTER TABLE employees ADD COLUMN IF NOT EXISTS team_id         UUID;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS team            TEXT;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS total_messages  INT DEFAULT 0;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS total_calls     INT DEFAULT 0;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS last_action_at  TIMESTAMPTZ;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS daily_streak    INT DEFAULT 0;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS archived_at     TIMESTAMPTZ;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS gdpr_deleted_at TIMESTAMPTZ;
-- v7 antigravity columns
DO $$ BEGIN ALTER TABLE employees ADD COLUMN stamina INT DEFAULT 100; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE employees ADD COLUMN max_stamina INT DEFAULT 100; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE employees ADD COLUMN avatar_color TEXT DEFAULT '#3b82f6'; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
-- v8: Lock employee (block login)
DO $$ BEGIN ALTER TABLE employees ADD COLUMN is_locked BOOLEAN DEFAULT false; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE employees ADD COLUMN locked_at TIMESTAMPTZ; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE employees ADD COLUMN locked_reason TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE employees ADD COLUMN last_seen_at TIMESTAMPTZ; EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- ═══════════════════════════════════════════════════════════════
-- v8: Document Archive System
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL,
    description     TEXT,
    file_url        TEXT NOT NULL,           -- Supabase Storage public URL
    file_name       TEXT NOT NULL,
    file_size       BIGINT,
    mime_type       TEXT,
    -- Entity binding (one of these will be set)
    entity_type     TEXT NOT NULL CHECK (entity_type IN ('employee', 'lead', 'transaction', 'property', 'contract', 'general')),
    entity_id       UUID,                    -- nullable for 'general'
    -- Tagging
    category        TEXT,                    -- 'photo', 'contract', 'id', 'invoice', 'other'
    tags            TEXT[],
    -- Audit
    uploaded_by     UUID REFERENCES employees(id) ON DELETE SET NULL,
    uploaded_at     TIMESTAMPTZ DEFAULT now(),
    deleted_at      TIMESTAMPTZ,
    metadata        JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_docs_entity ON documents(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_docs_category ON documents(category);
CREATE INDEX IF NOT EXISTS idx_docs_uploaded_at ON documents(uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_docs_uploaded_by ON documents(uploaded_by);

-- ═══════════════════════════════════════════════════════════════
-- v9: AI Bot System (3 bots — Khaled / Yusuf / Sara)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS bot_conversations (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    whatsapp_number   TEXT NOT NULL,
    current_bot       TEXT NOT NULL DEFAULT 'khaled' CHECK (current_bot IN ('khaled', 'yusuf', 'sara')),
    state             TEXT DEFAULT 'active' CHECK (state IN ('active', 'handed_off', 'rejected', 'closed')),
    customer_name     TEXT,
    customer_data     JSONB DEFAULT '{}'::jsonb,   -- collected info: budget, location, type, etc.
    handed_off_to     UUID REFERENCES employees(id) ON DELETE SET NULL,
    handed_off_at     TIMESTAMPTZ,
    handoff_summary   TEXT,
    created_at        TIMESTAMPTZ DEFAULT now(),
    updated_at        TIMESTAMPTZ DEFAULT now(),
    last_message_at   TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_botconv_phone ON bot_conversations(whatsapp_number);
CREATE INDEX IF NOT EXISTS idx_botconv_state ON bot_conversations(state);
CREATE INDEX IF NOT EXISTS idx_botconv_last ON bot_conversations(last_message_at DESC);

CREATE TABLE IF NOT EXISTS bot_messages (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id   UUID REFERENCES bot_conversations(id) ON DELETE CASCADE,
    role              TEXT NOT NULL CHECK (role IN ('user', 'bot', 'system')),
    bot_name          TEXT,                          -- khaled/yusuf/sara if role='bot'
    content           TEXT NOT NULL,
    created_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_botmsg_conv ON bot_messages(conversation_id, created_at);

CREATE TABLE IF NOT EXISTS job_applications (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    whatsapp_number   TEXT,
    applicant_name    TEXT,
    cv_url            TEXT,
    position_applied  TEXT,
    experience_years  INT,
    expected_salary   NUMERIC(10,2),
    availability      TEXT,
    skills            TEXT,
    ai_evaluation     TEXT,
    ai_score          INT,                          -- 0..100
    is_qualified      BOOLEAN,
    status            TEXT DEFAULT 'pending' CHECK (status IN ('pending','screening','qualified','rejected','hired','archived')),
    forwarded_to      UUID REFERENCES employees(id) ON DELETE SET NULL,
    rejection_reason  TEXT,
    created_at        TIMESTAMPTZ DEFAULT now(),
    updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON job_applications(status);
CREATE INDEX IF NOT EXISTS idx_jobs_phone ON job_applications(whatsapp_number);
DO $$ BEGIN ALTER TABLE employees ADD COLUMN status TEXT DEFAULT 'offline'; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE employees ADD COLUMN professional_mode BOOLEAN DEFAULT false; EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- 2. Projects
CREATE TABLE IF NOT EXISTS projects (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  slug          TEXT UNIQUE NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- 3. Leads
CREATE TABLE IF NOT EXISTS leads (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone           TEXT NOT NULL,
  phone_clean     TEXT NOT NULL,
  name            TEXT,
  project_id      UUID REFERENCES projects(id),
  assigned_to     UUID REFERENCES employees(id),
  status          lead_status DEFAULT 'new',
  source          TEXT,
  imported_from   TEXT,
  country_code    TEXT,
  quality         TEXT DEFAULT 'unknown',
  last_contact_at TIMESTAMPTZ,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE leads ADD COLUMN IF NOT EXISTS contact_count INT DEFAULT 0;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS locked_by     UUID REFERENCES employees(id);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS locked_at     TIMESTAMPTZ;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS lock_expires  TIMESTAMPTZ;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS notes_count   INT DEFAULT 0;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS last_status_change TIMESTAMPTZ;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS lead_score      INT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS score_updated_at TIMESTAMPTZ;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS ai_summary       TEXT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS archived_at      TIMESTAMPTZ;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS email           TEXT;

CREATE INDEX IF NOT EXISTS idx_leads_assigned ON leads(assigned_to) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_leads_email    ON leads(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_phone ON leads(phone_clean);
CREATE INDEX IF NOT EXISTS idx_leads_locked ON leads(locked_by) WHERE locked_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_leads_project ON leads(project_id);
CREATE INDEX IF NOT EXISTS idx_leads_created ON leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_archived ON leads(archived_at) WHERE archived_at IS NULL;

-- 4. Actions Log
CREATE TABLE IF NOT EXISTS actions_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id     UUID NOT NULL REFERENCES employees(id),
  lead_id         UUID REFERENCES leads(id),
  action          action_type NOT NULL,
  xp_earned       INT DEFAULT 0,
  coins_earned    INT DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE actions_log ADD COLUMN IF NOT EXISTS details JSONB DEFAULT '{}'::jsonb;
ALTER TABLE actions_log ADD COLUMN IF NOT EXISTS ref_type TEXT;
ALTER TABLE actions_log ADD COLUMN IF NOT EXISTS ref_id   UUID;

CREATE INDEX IF NOT EXISTS idx_actions_employee ON actions_log(employee_id);
CREATE INDEX IF NOT EXISTS idx_actions_lead ON actions_log(lead_id);

-- 5. Leaderboard
CREATE TABLE IF NOT EXISTS leaderboard (
  employee_id     UUID REFERENCES employees(id),
  rank            INT,
  total_xp        BIGINT DEFAULT 0,
  deals_closed    INT DEFAULT 0,
  updated_at      TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE leaderboard ADD COLUMN IF NOT EXISTS period         TEXT DEFAULT 'all_time';
ALTER TABLE leaderboard ADD COLUMN IF NOT EXISTS period_start   DATE;
ALTER TABLE leaderboard ADD COLUMN IF NOT EXISTS messages_sent  INT DEFAULT 0;
ALTER TABLE leaderboard ADD COLUMN IF NOT EXISTS calls_made     INT DEFAULT 0;
ALTER TABLE leaderboard ADD COLUMN IF NOT EXISTS coins_earned   INT DEFAULT 0;

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints
               WHERE table_name='leaderboard' AND constraint_name='leaderboard_pkey') THEN
        ALTER TABLE leaderboard DROP CONSTRAINT leaderboard_pkey;
    END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END$$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_leaderboard_unique ON leaderboard(employee_id, period);
CREATE INDEX IF NOT EXISTS idx_leaderboard_period_rank ON leaderboard(period, rank);

-- 6. Quests
CREATE TABLE IF NOT EXISTS quests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id     UUID NOT NULL REFERENCES employees(id),
  lead_id         UUID REFERENCES leads(id),
  title           TEXT NOT NULL,
  description     TEXT,
  status          TEXT DEFAULT 'pending',
  xp_reward       INT DEFAULT 0,
  coin_reward     INT DEFAULT 0,
  due_at          TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE quests ADD COLUMN IF NOT EXISTS quest_type       TEXT DEFAULT 'single';
ALTER TABLE quests ADD COLUMN IF NOT EXISTS priority         INT DEFAULT 1;
ALTER TABLE quests ADD COLUMN IF NOT EXISTS target_count     INT DEFAULT 1;
ALTER TABLE quests ADD COLUMN IF NOT EXISTS progress         INT DEFAULT 0;
ALTER TABLE quests ADD COLUMN IF NOT EXISTS bonus_multiplier NUMERIC(4,2) DEFAULT 1.0;
ALTER TABLE quests ADD COLUMN IF NOT EXISTS completed_at     TIMESTAMPTZ;
ALTER TABLE quests ADD COLUMN IF NOT EXISTS action_required  action_type;

CREATE INDEX IF NOT EXISTS idx_quests_employee ON quests(employee_id);

-- =====================================================================
-- ADDITIONAL TABLES
-- =====================================================================

-- Teams
CREATE TABLE IF NOT EXISTS teams (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT UNIQUE NOT NULL,
    slug        TEXT UNIQUE NOT NULL,
    manager_id  UUID REFERENCES employees(id),
    total_xp    BIGINT DEFAULT 0,
    total_deals INT DEFAULT 0,
    color       TEXT DEFAULT '#6366F1',
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS team_members (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id     UUID REFERENCES teams(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    joined_at   TIMESTAMPTZ DEFAULT now(),
    UNIQUE(team_id, employee_id)
);

-- Lead Notes
CREATE TABLE IF NOT EXISTS lead_notes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id     UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id),
    note_text   TEXT NOT NULL,
    is_pinned   BOOLEAN DEFAULT false,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notes_lead ON lead_notes(lead_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_employee ON lead_notes(employee_id);

-- Lead Status History
CREATE TABLE IF NOT EXISTS lead_status_history (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id     UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id),
    old_status  lead_status,
    new_status  lead_status NOT NULL,
    reason      TEXT,
    changed_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_status_history_lead ON lead_status_history(lead_id);

-- WhatsApp Messages
CREATE TABLE IF NOT EXISTS whatsapp_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id         UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    employee_id     UUID REFERENCES employees(id),
    direction       TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    message_text    TEXT,
    message_type    TEXT DEFAULT 'text',
    template_name   TEXT,
    wa_status       TEXT DEFAULT 'sent',
    wa_message_id   TEXT,
    media_url       TEXT,
    created_at      TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_wa_lead ON whatsapp_messages(lead_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wa_employee ON whatsapp_messages(employee_id);

-- Message Templates
CREATE TABLE IF NOT EXISTS message_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    category        TEXT,
    language        TEXT DEFAULT 'ar',
    template_text   TEXT NOT NULL,
    variables       JSONB DEFAULT '[]'::jsonb,
    times_used      INT DEFAULT 0,
    is_active       BOOLEAN DEFAULT true,
    created_by      UUID REFERENCES employees(id),
    created_at      TIMESTAMPTZ DEFAULT now()
);

-- Store Items & Purchases
CREATE TABLE IF NOT EXISTS store_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    description     TEXT,
    item_type       TEXT NOT NULL,
    coin_price      INT NOT NULL CHECK (coin_price >= 0),
    level_required  INT DEFAULT 1,
    stock           INT DEFAULT -1,
    icon            TEXT,
    effect          JSONB DEFAULT '{}'::jsonb,
    is_available    BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS employee_purchases (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id     UUID NOT NULL REFERENCES employees(id),
    item_id         UUID NOT NULL REFERENCES store_items(id),
    coins_spent     INT NOT NULL,
    is_active       BOOLEAN DEFAULT true,
    activated_at    TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_purchases_employee ON employee_purchases(employee_id, is_active);

-- Competitions
CREATE TABLE IF NOT EXISTS competitions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL,
    description     TEXT,
    competition_type TEXT DEFAULT 'team_vs_team',
    metric          TEXT DEFAULT 'total_xp',
    starts_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    ends_at         TIMESTAMPTZ NOT NULL DEFAULT now() + interval '7 days',
    prize_xp        INT DEFAULT 0,
    prize_coins     INT DEFAULT 0,
    status          TEXT DEFAULT 'active',
    winner_team_id  UUID REFERENCES teams(id),
    winner_emp_id   UUID REFERENCES employees(id),
    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS competition_participants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id  UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
    team_id         UUID REFERENCES teams(id),
    employee_id     UUID REFERENCES employees(id),
    score           BIGINT DEFAULT 0,
    rank            INT,
    joined_at       TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_comp_part ON competition_participants(competition_id, score DESC);

-- Activity Feed
CREATE TABLE IF NOT EXISTS activity_feed (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES employees(id),
    event_type  TEXT NOT NULL,
    title       TEXT NOT NULL,
    message     TEXT,
    icon        TEXT,
    is_public   BOOLEAN DEFAULT true,
    metadata    JSONB DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_feed_created ON activity_feed(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feed_employee ON activity_feed(employee_id);

-- Rate Limit Log
CREATE TABLE IF NOT EXISTS rate_limit_log (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES employees(id),
    endpoint    TEXT NOT NULL,
    ip_address  TEXT,
    created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rl_employee_time ON rate_limit_log(employee_id, endpoint, created_at DESC);

-- Admin Audit Log
CREATE TABLE IF NOT EXISTS admin_audit_log (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id     UUID REFERENCES employees(id),
    action       TEXT NOT NULL,
    target_type  TEXT,
    target_id    UUID,
    ip_address   TEXT,
    user_agent   TEXT,
    details      JSONB DEFAULT '{}'::jsonb,
    created_at   TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_admin  ON admin_audit_log(admin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_action ON admin_audit_log(action, created_at DESC);

-- Push Notification Subscriptions (Web Push / VAPID)
CREATE TABLE IF NOT EXISTS push_subscriptions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id   UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    subscription  JSONB NOT NULL,
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_push_sub_emp ON push_subscriptions(employee_id);

-- =====================================================================
-- ORGANIZATIONS & MULTI-TENANCY (v4)
-- =====================================================================

CREATE TABLE IF NOT EXISTS organizations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  slug          text UNIQUE NOT NULL,
  plan          text DEFAULT 'free' CHECK (plan IN ('free','starter','pro','enterprise')),
  seats_limit   int  DEFAULT 5,
  leads_limit   int  DEFAULT 1000,
  is_active     boolean DEFAULT true,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

INSERT INTO organizations (id, name, slug, plan)
VALUES ('00000000-0000-0000-0000-000000000001', 'Default', 'default', 'enterprise')
ON CONFLICT (slug) DO NOTHING;

-- Add org_id to tenant-scoped tables
DO $$
DECLARE t text;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'employees','leads','projects','actions_log','whatsapp_messages',
    'lead_notes','lead_status_history','quests','store_items',
    'activity_feed','leaderboard'
  ]) LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = t) THEN
      EXECUTE format(
        'ALTER TABLE %I ADD COLUMN IF NOT EXISTS organization_id uuid
           REFERENCES organizations(id) ON DELETE CASCADE
           DEFAULT ''00000000-0000-0000-0000-000000000001''', t);
      EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%s_org ON %I(organization_id)', t, t);
    END IF;
  END LOOP;
END $$;

-- Permissions
CREATE TABLE IF NOT EXISTS permissions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text UNIQUE NOT NULL,
  description text
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role         text NOT NULL,
  permission   text NOT NULL REFERENCES permissions(code) ON DELETE CASCADE,
  PRIMARY KEY (role, permission)
);

INSERT INTO permissions (code, description) VALUES
  ('leads.view',        'View leads'),
  ('leads.edit',        'Edit lead details'),
  ('leads.assign',      'Assign/reassign leads'),
  ('leads.archive',     'Archive old leads'),
  ('leads.delete',      'Hard delete a lead'),
  ('actions.log',       'Log actions (call, whatsapp, meeting)'),
  ('deals.close',       'Close a deal'),
  ('store.buy',         'Purchase from store'),
  ('store.manage',      'Add/edit store items'),
  ('quests.manage',     'Create/assign quests'),
  ('team.view',         'View team members'),
  ('team.manage',       'Add/remove team members'),
  ('billing.view',      'View subscription & invoices'),
  ('billing.manage',    'Change subscription plan'),
  ('audit.view',        'View admin audit log'),
  ('gdpr.delete',       'GDPR right-to-delete')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role, permission) VALUES
  ('agent', 'leads.view'), ('agent', 'leads.edit'),
  ('agent', 'actions.log'), ('agent', 'deals.close'),
  ('agent', 'store.buy'),   ('agent', 'team.view'),
  ('manager', 'leads.view'),   ('manager', 'leads.edit'),
  ('manager', 'leads.assign'), ('manager', 'leads.archive'),
  ('manager', 'actions.log'),  ('manager', 'deals.close'),
  ('manager', 'store.buy'),    ('manager', 'team.view'),
  ('manager', 'team.manage'),  ('manager', 'quests.manage'),
  ('manager', 'audit.view'),
  ('admin', 'leads.view'),     ('admin', 'leads.edit'),
  ('admin', 'leads.assign'),   ('admin', 'leads.archive'),
  ('admin', 'leads.delete'),   ('admin', 'actions.log'),
  ('admin', 'deals.close'),    ('admin', 'store.buy'),
  ('admin', 'store.manage'),   ('admin', 'quests.manage'),
  ('admin', 'team.view'),      ('admin', 'team.manage'),
  ('admin', 'billing.view'),   ('admin', 'billing.manage'),
  ('admin', 'audit.view'),     ('admin', 'gdpr.delete')
ON CONFLICT DO NOTHING;

-- Billing
CREATE TABLE IF NOT EXISTS subscriptions (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  stripe_customer_id     text,
  stripe_subscription_id text UNIQUE,
  plan                   text NOT NULL DEFAULT 'free',
  status                 text NOT NULL DEFAULT 'active'
                           CHECK (status IN ('trialing','active','past_due','canceled','incomplete')),
  current_period_end     timestamptz,
  cancel_at_period_end   boolean DEFAULT false,
  created_at             timestamptz DEFAULT now(),
  updated_at             timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_subs_org ON subscriptions(organization_id);

CREATE TABLE IF NOT EXISTS stripe_events (
  id           text PRIMARY KEY,
  type         text NOT NULL,
  payload      jsonb NOT NULL,
  received_at  timestamptz DEFAULT now(),
  processed_at timestamptz
);

-- MFA Audit
CREATE TABLE IF NOT EXISTS mfa_audit (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL,
  event         text NOT NULL,
  factor_type   text,
  ip            inet,
  user_agent    text,
  created_at    timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_mfa_audit_user ON mfa_audit(user_id, created_at DESC);

-- =====================================================================
-- REAL ESTATE TABLES (v6)
-- =====================================================================

-- Owners
CREATE TABLE IF NOT EXISTS owners (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  name          text NOT NULL,
  phone         text,
  email         text,
  type          text DEFAULT 'individual' CHECK (type IN ('individual', 'company')),
  nationality   text,
  passport_id   text,
  company_name  text,
  notes         text,
  agent_id      uuid REFERENCES employees(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_owners_phone ON owners(phone);

-- Listings
CREATE TABLE IF NOT EXISTS listings (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  title           text NOT NULL,
  description     text,
  property_type   text DEFAULT 'apartment',
  listing_type    text DEFAULT 'sale' CHECK (listing_type IN ('sale', 'rent')),
  price           numeric(15,2),
  currency        text DEFAULT 'AED',
  area_sqft       numeric(10,2),
  bedrooms        int,
  bathrooms       int,
  location        text,
  city            text DEFAULT 'Dubai',
  district        text,
  building_name   text,
  lat             numeric(10,7),
  lng             numeric(10,7),
  status          text DEFAULT 'available' CHECK (status IN ('available','reserved','sold','rented','off_market')),
  owner_id        uuid REFERENCES owners(id) ON DELETE SET NULL,
  agent_id        uuid REFERENCES employees(id) ON DELETE SET NULL,
  project_id      uuid REFERENCES projects(id) ON DELETE SET NULL,
  images          jsonb DEFAULT '[]',
  features        jsonb DEFAULT '{}',
  permit_number   text,
  reference_number text,
  floor_number    int,
  parking_spots   int DEFAULT 0,
  furnished       text DEFAULT 'unfurnished',
  view_type       text
);
CREATE INDEX IF NOT EXISTS idx_listings_status ON listings(status);
CREATE INDEX IF NOT EXISTS idx_listings_type ON listings(listing_type);
CREATE INDEX IF NOT EXISTS idx_listings_owner ON listings(owner_id);
CREATE INDEX IF NOT EXISTS idx_listings_agent ON listings(agent_id);

-- Off-Plan Projects
CREATE TABLE IF NOT EXISTS offplan_projects (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  name          text NOT NULL,
  developer     text,
  location      text,
  city          text DEFAULT 'Dubai',
  handover_date date,
  total_units   int DEFAULT 0,
  sold_units    int DEFAULT 0,
  price_from    numeric(15,2),
  price_to      numeric(15,2),
  status        text DEFAULT 'upcoming' CHECK (status IN ('upcoming','active','sold_out','handed_over')),
  description   text,
  images        jsonb DEFAULT '[]',
  brochure_url  text,
  payment_plan  jsonb DEFAULT '{}',
  amenities     jsonb DEFAULT '[]'
);

-- Transactions
CREATE TABLE IF NOT EXISTS transactions (
  id                uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now(),
  listing_id        uuid REFERENCES listings(id) ON DELETE SET NULL,
  lead_id           uuid REFERENCES leads(id) ON DELETE SET NULL,
  owner_id          uuid REFERENCES owners(id) ON DELETE SET NULL,
  agent_id          uuid REFERENCES employees(id) ON DELETE SET NULL,
  type              text DEFAULT 'sale' CHECK (type IN ('sale', 'rent')),
  amount            numeric(15,2) NOT NULL DEFAULT 0,
  currency          text DEFAULT 'AED',
  commission_rate   numeric(5,2) DEFAULT 2.00,
  commission_amount numeric(15,2) DEFAULT 0,
  status            text DEFAULT 'pending' CHECK (status IN ('pending','approved','completed','cancelled')),
  contract_date     date,
  completion_date   date,
  approved_by       uuid REFERENCES employees(id) ON DELETE SET NULL,
  approved_at       timestamptz,
  notes             text
);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_agent ON transactions(agent_id);
CREATE INDEX IF NOT EXISTS idx_transactions_listing ON transactions(listing_id);

-- ═══════════════════════════════════════════════════════════════
-- v8: Transactions extended details (property + person + broker)
-- ═══════════════════════════════════════════════════════════════

-- Property details (extra fields on transactions for the specific property in this deal)
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN property_type TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN property_title TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN property_address TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN property_size NUMERIC(10,2); EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN property_bedrooms INT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN property_bathrooms INT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN property_furnished BOOLEAN; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN property_emirate TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Person/Party details (who is the other party — owner/buyer/tenant)
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN party_role TEXT CHECK (party_role IN ('owner', 'buyer', 'tenant', 'seller', 'landlord')); EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN party_name TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN party_phone TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN party_email TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN party_id_number TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN party_nationality TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Broker / counter-party company details
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN broker_company TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN broker_agent_name TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN broker_phone TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN broker_email TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN broker_license TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE transactions ADD COLUMN broker_commission_split NUMERIC(5,2); EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Workflows
CREATE TABLE IF NOT EXISTS workflows (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  type          text DEFAULT 'general',
  entity_id     uuid,
  entity_type   text,
  requested_by  uuid REFERENCES employees(id) ON DELETE SET NULL,
  approved_by   uuid REFERENCES employees(id) ON DELETE SET NULL,
  status        text DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  notes         text,
  response_notes text,
  responded_at  timestamptz
);
CREATE INDEX IF NOT EXISTS idx_workflows_status ON workflows(status);

-- Lead Rotation Rules
CREATE TABLE IF NOT EXISTS lead_rotation_rules (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at    timestamptz DEFAULT now(),
  name          text NOT NULL,
  active        boolean DEFAULT true,
  source_filter jsonb DEFAULT '{}',
  agents        jsonb DEFAULT '[]',
  method        text DEFAULT 'round_robin' CHECK (method IN ('round_robin','weighted','random')),
  current_index int DEFAULT 0
);

-- Custom Fields
CREATE TABLE IF NOT EXISTS custom_fields (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at    timestamptz DEFAULT now(),
  entity_type   text NOT NULL CHECK (entity_type IN ('lead','listing','owner','transaction')),
  field_name    text NOT NULL,
  field_label   text NOT NULL,
  field_type    text DEFAULT 'text' CHECK (field_type IN ('text','number','date','select','checkbox','textarea')),
  options       jsonb DEFAULT '[]',
  required      boolean DEFAULT false,
  active        boolean DEFAULT true,
  sort_order    int DEFAULT 0,
  UNIQUE(entity_type, field_name)
);

CREATE TABLE IF NOT EXISTS custom_field_values (
  id        uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  field_id  uuid REFERENCES custom_fields(id) ON DELETE CASCADE,
  entity_id uuid NOT NULL,
  value     text,
  UNIQUE(field_id, entity_id)
);
CREATE INDEX IF NOT EXISTS idx_cfv_entity ON custom_field_values(entity_id);
CREATE INDEX IF NOT EXISTS idx_cfv_field ON custom_field_values(field_id);

-- KPI Targets
CREATE TABLE IF NOT EXISTS kpi_targets (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at    timestamptz DEFAULT now(),
  agent_id      uuid REFERENCES employees(id) ON DELETE CASCADE,
  metric        text NOT NULL,
  target_value  numeric(12,2) DEFAULT 0,
  current_value numeric(12,2) DEFAULT 0,
  period        text DEFAULT 'monthly' CHECK (period IN ('daily','weekly','monthly','quarterly')),
  start_date    date DEFAULT CURRENT_DATE,
  end_date      date
);

-- =====================================================================
-- GAME TABLES (v7 — Antigravity)
-- =====================================================================

-- Positions (multiplayer)
CREATE TABLE IF NOT EXISTS positions (
  user_id    UUID PRIMARY KEY REFERENCES employees(id) ON DELETE CASCADE,
  x          INT NOT NULL DEFAULT 640,
  y          INT NOT NULL DEFAULT 860,
  direction  TEXT DEFAULT 'down',
  scene      TEXT DEFAULT 'office',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Badges
CREATE TABLE IF NOT EXISTS badges (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT UNIQUE NOT NULL,
  description TEXT NOT NULL,
  icon        TEXT NOT NULL,
  criteria    JSONB NOT NULL DEFAULT '{}',
  rarity      TEXT DEFAULT 'common',
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_badges (
  user_id   UUID REFERENCES employees(id) ON DELETE CASCADE,
  badge_id  UUID REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, badge_id)
);

-- Hot Lead Events (random golden leads that spawn on desks)
CREATE TABLE IF NOT EXISTS hot_lead_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  desk_index  INT NOT NULL,
  xp_reward   INT NOT NULL DEFAULT 100,
  spawned_by  UUID REFERENCES employees(id),
  claimed_by  UUID REFERENCES employees(id),
  claimed_at  TIMESTAMPTZ,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_hot_lead_events_active ON hot_lead_events (expires_at) WHERE claimed_by IS NULL;

-- High Fives (social interactions between players)
CREATE TABLE IF NOT EXISTS high_fives (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user   UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  to_user     UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_high_fives_pair ON high_fives (from_user, to_user, created_at);

-- Power Hours (manager-triggered XP boost events)
CREATE TABLE IF NOT EXISTS power_hours (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type        TEXT NOT NULL CHECK (type IN ('happy_hour', 'lightning_round', 'sniper_mode')),
  multiplier  NUMERIC DEFAULT 2,
  duration    INT NOT NULL DEFAULT 60,
  started_by  UUID REFERENCES employees(id),
  started_at  TIMESTAMPTZ DEFAULT now(),
  ends_at     TIMESTAMPTZ NOT NULL,
  is_active   BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Daily Highlights (end-of-day cinematic records)
CREATE TABLE IF NOT EXISTS daily_highlights (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  highlight_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  best_dealer     JSONB DEFAULT '{}',
  most_calls      JSONB DEFAULT '{}',
  most_improved   JSONB DEFAULT '{}',
  daily_mvp       JSONB DEFAULT '{}',
  team_stats      JSONB DEFAULT '{}',
  generated_by    UUID REFERENCES employees(id),
  created_at      TIMESTAMPTZ DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_highlights_date ON daily_highlights (highlight_date);

-- =====================================================================
-- FUNCTIONS / RPCs
-- =====================================================================

-- XP & Coins (the only path that mutates XP/coins/level)
DROP FUNCTION IF EXISTS award_xp_and_coins(UUID, INT, INT, action_type, UUID);
DROP FUNCTION IF EXISTS award_xp_and_coins(UUID, INT, INT, TEXT, TEXT, UUID);

CREATE OR REPLACE FUNCTION award_xp_and_coins(
    p_employee_id UUID,
    p_xp          INT,
    p_coins       INT,
    p_reason      TEXT DEFAULT NULL,
    p_ref_type    TEXT DEFAULT NULL,
    p_ref_id      UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_rec         RECORD;
    v_new_xp      BIGINT;
    v_new_level   INT;
    v_leveled_up  BOOLEAN := false;
    v_new_title   TEXT;
BEGIN
    SELECT level, total_xp, title INTO v_rec
    FROM employees WHERE id = p_employee_id FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'employee_not_found');
    END IF;

    UPDATE employees SET
        total_xp       = total_xp + p_xp,
        current_xp     = current_xp + p_xp,
        syb_coins      = syb_coins + p_coins,
        last_action_at = now(),
        updated_at     = now()
    WHERE id = p_employee_id
    RETURNING total_xp INTO v_new_xp;

    IF v_new_xp < 15000 THEN
        v_new_level := (v_new_xp / 1000) + 1;
    ELSE
        v_new_level := 15 + FLOOR(SQRT((v_new_xp - 15000) / 1500.0))::INT;
    END IF;

    IF v_new_level > v_rec.level THEN
        v_leveled_up := true;
        v_new_title := CASE
            WHEN v_new_level < 5  THEN 'Junior Scraper'
            WHEN v_new_level < 10 THEN 'Lead Hunter'
            WHEN v_new_level < 15 THEN 'Elite Hunter'
            WHEN v_new_level < 25 THEN 'Sales Boss'
            ELSE 'Legend'
        END;

        UPDATE employees SET level = v_new_level, title = v_new_title
        WHERE id = p_employee_id;

        INSERT INTO activity_feed (employee_id, event_type, title, message, icon, metadata)
        VALUES (p_employee_id, 'level_up', 'Level ' || v_new_level || ' reached!',
                'صعد لمستوى جديد: ' || v_new_title, '🎉',
                jsonb_build_object('new_level', v_new_level, 'new_title', v_new_title));
    END IF;

    RETURN jsonb_build_object(
        'success', true, 'xp_added', p_xp, 'coins_added', p_coins,
        'total_xp', v_new_xp, 'new_level', v_new_level,
        'leveled_up', v_leveled_up, 'new_title', COALESCE(v_new_title, v_rec.title)
    );
END;
$$ LANGUAGE plpgsql;

-- Atomic counter increment
CREATE OR REPLACE FUNCTION increment_employee_counter(
  p_employee_id uuid, p_counter text, p_delta int DEFAULT 1
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_counter = 'total_messages' THEN
    UPDATE employees SET total_messages = COALESCE(total_messages,0) + p_delta WHERE id = p_employee_id;
  ELSIF p_counter = 'total_deals' THEN
    UPDATE employees SET total_deals = COALESCE(total_deals,0) + p_delta WHERE id = p_employee_id;
  ELSIF p_counter = 'total_calls' THEN
    UPDATE employees SET total_calls = COALESCE(total_calls,0) + p_delta WHERE id = p_employee_id;
  ELSE
    RAISE EXCEPTION 'unknown counter: %', p_counter;
  END IF;
END $$;

-- Lead locking
CREATE OR REPLACE FUNCTION acquire_lead_lock(
    p_lead_id UUID, p_employee_id UUID, p_duration_minutes INT DEFAULT 15
) RETURNS JSONB AS $$
DECLARE v_lead RECORD;
BEGIN
    SELECT id, assigned_to, locked_by, lock_expires INTO v_lead FROM leads WHERE id = p_lead_id FOR UPDATE;
    IF NOT FOUND THEN RETURN jsonb_build_object('error', 'lead_not_found'); END IF;
    IF v_lead.assigned_to IS DISTINCT FROM p_employee_id THEN
        RETURN jsonb_build_object('error', 'not_assigned_to_you');
    END IF;
    IF v_lead.locked_by IS NOT NULL AND v_lead.locked_by <> p_employee_id AND v_lead.lock_expires > now() THEN
        RETURN jsonb_build_object('error', 'already_locked', 'locked_by', v_lead.locked_by, 'expires_at', v_lead.lock_expires);
    END IF;
    UPDATE leads SET locked_by = p_employee_id, locked_at = now(),
        lock_expires = now() + (p_duration_minutes || ' minutes')::interval WHERE id = p_lead_id;
    RETURN jsonb_build_object('success', true, 'lead_id', p_lead_id,
        'expires_at', now() + (p_duration_minutes || ' minutes')::interval);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION release_lead_lock(p_lead_id UUID, p_employee_id UUID)
RETURNS JSONB AS $$
BEGIN
    UPDATE leads SET locked_by = NULL, locked_at = NULL, lock_expires = NULL
    WHERE id = p_lead_id AND locked_by = p_employee_id;
    IF NOT FOUND THEN RETURN jsonb_build_object('error', 'not_lock_holder'); END IF;
    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql;

-- Lead status transition validator
CREATE OR REPLACE FUNCTION change_lead_status(
    p_lead_id UUID, p_employee_id UUID, p_new_status lead_status, p_reason TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE v_old lead_status; v_valid BOOLEAN := false;
BEGIN
    SELECT status INTO v_old FROM leads WHERE id = p_lead_id FOR UPDATE;
    IF NOT FOUND THEN RETURN jsonb_build_object('error', 'lead_not_found'); END IF;
    v_valid := CASE
        WHEN v_old = p_new_status THEN false
        WHEN p_new_status = 'closed_lost' THEN true
        WHEN v_old = 'new'          AND p_new_status IN ('contacted','closed_lost') THEN true
        WHEN v_old = 'contacted'    AND p_new_status IN ('interested','closed_lost') THEN true
        WHEN v_old = 'interested'   AND p_new_status IN ('meeting_set','negotiation','closed_lost') THEN true
        WHEN v_old = 'meeting_set'  AND p_new_status IN ('negotiation','closed_won','closed_lost') THEN true
        WHEN v_old = 'negotiation'  AND p_new_status IN ('closed_won','closed_lost') THEN true
        ELSE false
    END;
    IF NOT v_valid THEN
        RETURN jsonb_build_object('error', 'invalid_transition', 'from', v_old, 'to', p_new_status);
    END IF;
    UPDATE leads SET status = p_new_status, last_status_change = now(), updated_at = now() WHERE id = p_lead_id;
    INSERT INTO lead_status_history (lead_id, employee_id, old_status, new_status, reason)
    VALUES (p_lead_id, p_employee_id, v_old, p_new_status, p_reason);
    RETURN jsonb_build_object('success', true, 'from', v_old, 'to', p_new_status);
END;
$$ LANGUAGE plpgsql;

-- Store purchase
CREATE OR REPLACE FUNCTION purchase_store_item(p_employee_id UUID, p_item_id UUID)
RETURNS JSONB AS $$
DECLARE v_item RECORD; v_emp RECORD; v_purchase_id UUID; v_expires TIMESTAMPTZ;
BEGIN
    SELECT * INTO v_item FROM store_items WHERE id = p_item_id AND is_available = true;
    IF NOT FOUND THEN RETURN jsonb_build_object('error', 'item_unavailable'); END IF;
    SELECT level, syb_coins INTO v_emp FROM employees WHERE id = p_employee_id FOR UPDATE;
    IF v_emp.level < v_item.level_required THEN
        RETURN jsonb_build_object('error', 'level_too_low', 'required', v_item.level_required, 'your_level', v_emp.level);
    END IF;
    IF v_emp.syb_coins < v_item.coin_price THEN
        RETURN jsonb_build_object('error', 'insufficient_coins', 'need', v_item.coin_price, 'you_have', v_emp.syb_coins);
    END IF;
    IF v_item.stock = 0 THEN RETURN jsonb_build_object('error', 'out_of_stock'); END IF;
    UPDATE employees SET syb_coins = syb_coins - v_item.coin_price WHERE id = p_employee_id;
    IF v_item.stock > 0 THEN UPDATE store_items SET stock = stock - 1 WHERE id = p_item_id; END IF;
    IF (v_item.effect->>'duration_hours') IS NOT NULL THEN
        v_expires := now() + ((v_item.effect->>'duration_hours')::INT || ' hours')::interval;
    END IF;
    INSERT INTO employee_purchases (employee_id, item_id, coins_spent, activated_at, expires_at)
    VALUES (p_employee_id, p_item_id, v_item.coin_price, now(), v_expires)
    RETURNING id INTO v_purchase_id;
    INSERT INTO activity_feed (employee_id, event_type, title, message, icon, metadata)
    VALUES (p_employee_id, 'item_purchased', 'اشترى: ' || v_item.name,
            'صرف ' || v_item.coin_price || ' عملة', v_item.icon,
            jsonb_build_object('item_id', p_item_id, 'purchase_id', v_purchase_id));
    RETURN jsonb_build_object('success', true, 'purchase_id', v_purchase_id,
        'coins_spent', v_item.coin_price, 'expires_at', v_expires);
END;
$$ LANGUAGE plpgsql;

-- Lead distribution (round-robin)
CREATE OR REPLACE FUNCTION distribute_leads_to_agents(p_project_id UUID DEFAULT NULL, p_limit INT DEFAULT 1000)
RETURNS JSONB AS $$
DECLARE v_agent_ids UUID[]; v_num_agents INT; v_updated_count INT := 0;
BEGIN
    SELECT ARRAY_AGG(id) INTO v_agent_ids FROM employees WHERE role = 'sales_agent' AND is_active = true;
    v_num_agents := array_length(v_agent_ids, 1);
    IF v_num_agents IS NULL OR v_num_agents = 0 THEN
        RETURN jsonb_build_object('error', 'No active agents found');
    END IF;
    WITH leads_to_assign AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as row_num
        FROM leads WHERE assigned_to IS NULL AND is_active = true
        AND (p_project_id IS NULL OR project_id = p_project_id) LIMIT p_limit
    )
    UPDATE leads l SET assigned_to = v_agent_ids[((sub.row_num - 1) % v_num_agents) + 1], updated_at = now()
    FROM leads_to_assign sub WHERE l.id = sub.id;
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RETURN jsonb_build_object('success', true, 'leads_assigned', v_updated_count, 'agents_involved', v_num_agents);
END;
$$ LANGUAGE plpgsql;

-- Lead assign (admin)
CREATE OR REPLACE FUNCTION assign_lead_to(p_lead_id UUID, p_employee_id UUID, p_admin_id UUID)
RETURNS JSONB AS $$
DECLARE v_old UUID;
BEGIN
    SELECT assigned_to INTO v_old FROM leads WHERE id = p_lead_id FOR UPDATE;
    IF NOT FOUND THEN RETURN jsonb_build_object('error', 'lead_not_found'); END IF;
    UPDATE leads SET assigned_to = p_employee_id, locked_by = NULL, locked_at = NULL,
        lock_expires = NULL, updated_at = now() WHERE id = p_lead_id;
    INSERT INTO admin_audit_log (admin_id, action, target_type, target_id, details)
    VALUES (p_admin_id, 'lead_reassign', 'lead', p_lead_id, jsonb_build_object('from', v_old, 'to', p_employee_id));
    RETURN jsonb_build_object('success', true, 'lead_id', p_lead_id, 'from', v_old, 'to', p_employee_id);
END;
$$ LANGUAGE plpgsql;

-- Leaderboard refresh
CREATE OR REPLACE FUNCTION refresh_leaderboard(p_period TEXT DEFAULT 'weekly')
RETURNS INT AS $$
DECLARE v_start TIMESTAMPTZ; v_count INT;
BEGIN
    v_start := CASE p_period
        WHEN 'daily' THEN date_trunc('day', now())
        WHEN 'weekly' THEN date_trunc('week', now())
        WHEN 'monthly' THEN date_trunc('month', now())
        ELSE '1970-01-01'::TIMESTAMPTZ
    END;
    DELETE FROM leaderboard WHERE period = p_period;
    INSERT INTO leaderboard (employee_id, period, period_start, total_xp, deals_closed,
         messages_sent, calls_made, coins_earned, rank, updated_at)
    SELECT a.employee_id, p_period, v_start::DATE, COALESCE(SUM(a.xp_earned), 0),
        COUNT(*) FILTER (WHERE a.action = 'deal_closed'),
        COUNT(*) FILTER (WHERE a.action = 'whatsapp_sent'),
        COUNT(*) FILTER (WHERE a.action = 'call_made'),
        COALESCE(SUM(a.coins_earned), 0),
        RANK() OVER (ORDER BY COALESCE(SUM(a.xp_earned), 0) DESC), now()
    FROM actions_log a WHERE a.created_at >= v_start GROUP BY a.employee_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Daily quests generator
CREATE OR REPLACE FUNCTION generate_daily_quests() RETURNS INT AS $$
DECLARE v_agent RECORD; v_created INT := 0;
BEGIN
    FOR v_agent IN SELECT id FROM employees WHERE role = 'sales_agent' AND is_active = true LOOP
        IF EXISTS (SELECT 1 FROM quests WHERE employee_id = v_agent.id
            AND created_at >= date_trunc('day', now()) AND quest_type = 'daily') THEN CONTINUE; END IF;
        INSERT INTO quests (employee_id, title, description, quest_type, target_count, xp_reward, coin_reward, priority, action_required, due_at) VALUES
        (v_agent.id, 'The Morning Rush', 'ابعت 20 رسالة قبل الساعة 12 ظهراً', 'daily', 20, 150, 15, 3, 'whatsapp_sent', date_trunc('day', now()) + interval '12 hours'),
        (v_agent.id, 'Phone Warrior', 'اعمل 10 مكالمات النهاردة', 'daily', 10, 200, 20, 2, 'call_made', date_trunc('day', now()) + interval '23 hours'),
        (v_agent.id, 'Deal Chaser', 'اقفل صفقة واحدة على الأقل', 'daily', 1, 500, 50, 3, 'deal_closed', date_trunc('day', now()) + interval '23 hours');
        v_created := v_created + 3;
    END LOOP;
    RETURN v_created;
END;
$$ LANGUAGE plpgsql;

-- Quest auto-progress trigger
CREATE OR REPLACE FUNCTION progress_matching_quests() RETURNS TRIGGER AS $$
DECLARE v_q RECORD;
BEGIN
    FOR v_q IN SELECT * FROM quests WHERE employee_id = NEW.employee_id AND status = 'pending'
        AND action_required = NEW.action AND (due_at IS NULL OR due_at > now()) LOOP
        UPDATE quests SET progress = progress + 1,
            status = CASE WHEN progress + 1 >= target_count THEN 'completed' ELSE 'pending' END,
            completed_at = CASE WHEN progress + 1 >= target_count THEN now() ELSE completed_at END
        WHERE id = v_q.id;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_progress_quests ON actions_log;
CREATE TRIGGER trg_progress_quests AFTER INSERT ON actions_log FOR EACH ROW EXECUTE FUNCTION progress_matching_quests();

-- Big deal feed trigger
CREATE OR REPLACE FUNCTION feed_on_big_deal() RETURNS TRIGGER AS $$
DECLARE v_deal_value NUMERIC; v_emp RECORD;
BEGIN
    IF NEW.action = 'deal_closed' THEN
        v_deal_value := COALESCE((NEW.details->>'deal_value')::NUMERIC, 0);
        SELECT full_name INTO v_emp FROM employees WHERE id = NEW.employee_id;
        INSERT INTO activity_feed (employee_id, event_type, title, message, icon, metadata)
        VALUES (NEW.employee_id, 'deal_closed', (v_emp.full_name || ' قفل صفقة! 🎯'),
            'قيمة الصفقة: ' || v_deal_value || ' - XP: ' || NEW.xp_earned,
            CASE WHEN v_deal_value > 500000 THEN '🚀' WHEN v_deal_value > 100000 THEN '🔥' ELSE '💰' END, NEW.details);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_feed_big_deal ON actions_log;
CREATE TRIGGER trg_feed_big_deal AFTER INSERT ON actions_log FOR EACH ROW EXECUTE FUNCTION feed_on_big_deal();

-- Team XP sync trigger
CREATE OR REPLACE FUNCTION sync_team_xp() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.team_id IS NOT NULL AND NEW.total_xp IS DISTINCT FROM OLD.total_xp THEN
        UPDATE teams SET total_xp = total_xp + (NEW.total_xp - OLD.total_xp) WHERE id = NEW.team_id;
    END IF;
    IF NEW.team_id IS NOT NULL AND NEW.total_deals IS DISTINCT FROM OLD.total_deals THEN
        UPDATE teams SET total_deals = total_deals + (NEW.total_deals - OLD.total_deals) WHERE id = NEW.team_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_team_xp ON employees;
CREATE TRIGGER trg_sync_team_xp AFTER UPDATE ON employees FOR EACH ROW EXECUTE FUNCTION sync_team_xp();

-- Rate limit check
CREATE OR REPLACE FUNCTION check_rate_limit(p_employee_id UUID, p_endpoint TEXT, p_max_per_min INT DEFAULT 60)
RETURNS BOOLEAN AS $$
DECLARE v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count FROM rate_limit_log
    WHERE employee_id = p_employee_id AND endpoint = p_endpoint AND created_at > now() - interval '1 minute';
    INSERT INTO rate_limit_log (employee_id, endpoint) VALUES (p_employee_id, p_endpoint);
    RETURN v_count < p_max_per_min;
END;
$$ LANGUAGE plpgsql;

-- Competition scoring
CREATE OR REPLACE FUNCTION refresh_competition_scores(p_comp_id UUID) RETURNS JSONB AS $$
DECLARE v_comp RECORD;
BEGIN
    SELECT * INTO v_comp FROM competitions WHERE id = p_comp_id;
    IF NOT FOUND THEN RETURN jsonb_build_object('error', 'competition_not_found'); END IF;
    UPDATE competition_participants cp SET score = COALESCE((
        SELECT SUM(CASE v_comp.metric
            WHEN 'total_xp' THEN a.xp_earned
            WHEN 'deals_closed' THEN CASE WHEN a.action='deal_closed' THEN 1 ELSE 0 END
            WHEN 'messages_sent' THEN CASE WHEN a.action='whatsapp_sent' THEN 1 ELSE 0 END ELSE 0 END)
        FROM actions_log a WHERE a.employee_id = cp.employee_id
        AND a.created_at BETWEEN v_comp.starts_at AND LEAST(v_comp.ends_at, now())), 0)
    WHERE cp.competition_id = p_comp_id AND cp.employee_id IS NOT NULL;
    UPDATE competition_participants cp SET score = COALESCE((
        SELECT SUM(CASE v_comp.metric
            WHEN 'total_xp' THEN a.xp_earned
            WHEN 'deals_closed' THEN CASE WHEN a.action='deal_closed' THEN 1 ELSE 0 END
            WHEN 'messages_sent' THEN CASE WHEN a.action='whatsapp_sent' THEN 1 ELSE 0 END ELSE 0 END)
        FROM actions_log a JOIN employees e ON e.id = a.employee_id
        WHERE e.team_id = cp.team_id
        AND a.created_at BETWEEN v_comp.starts_at AND LEAST(v_comp.ends_at, now())), 0)
    WHERE cp.competition_id = p_comp_id AND cp.team_id IS NOT NULL;
    WITH ranked AS (SELECT id, RANK() OVER (ORDER BY score DESC) AS r FROM competition_participants WHERE competition_id = p_comp_id)
    UPDATE competition_participants cp SET rank = ranked.r FROM ranked WHERE cp.id = ranked.id;
    RETURN jsonb_build_object('success', true, 'competition_id', p_comp_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION finalize_competition(p_comp_id UUID) RETURNS JSONB AS $$
DECLARE v_comp RECORD; v_winner RECORD;
BEGIN
    SELECT * INTO v_comp FROM competitions WHERE id = p_comp_id FOR UPDATE;
    IF NOT FOUND OR v_comp.status <> 'active' THEN
        RETURN jsonb_build_object('error', 'competition_not_active');
    END IF;
    PERFORM refresh_competition_scores(p_comp_id);
    SELECT * INTO v_winner FROM competition_participants WHERE competition_id = p_comp_id ORDER BY score DESC LIMIT 1;
    IF v_winner.employee_id IS NOT NULL THEN
        PERFORM award_xp_and_coins(v_winner.employee_id, v_comp.prize_xp, v_comp.prize_coins, 'فوز في ' || v_comp.title, 'competition', p_comp_id);
    ELSIF v_winner.team_id IS NOT NULL THEN
        PERFORM award_xp_and_coins(e.id,
            v_comp.prize_xp / GREATEST((SELECT COUNT(*) FROM employees WHERE team_id = v_winner.team_id),1),
            v_comp.prize_coins / GREATEST((SELECT COUNT(*) FROM employees WHERE team_id = v_winner.team_id),1),
            'فوز الفريق في ' || v_comp.title, 'competition', p_comp_id)
        FROM employees e WHERE e.team_id = v_winner.team_id;
    END IF;
    UPDATE competitions SET status = 'finished', winner_team_id = v_winner.team_id, winner_emp_id = v_winner.employee_id WHERE id = p_comp_id;
    RETURN jsonb_build_object('success', true, 'winner_employee', v_winner.employee_id, 'winner_team', v_winner.team_id, 'score', v_winner.score);
END;
$$ LANGUAGE plpgsql;

-- Expired locks cleanup
CREATE OR REPLACE FUNCTION release_expired_locks() RETURNS INT AS $$
DECLARE v_count INT;
BEGIN
    UPDATE leads SET locked_by = NULL, locked_at = NULL, lock_expires = NULL
    WHERE lock_expires < now() AND locked_by IS NOT NULL;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Permission check
CREATE OR REPLACE FUNCTION has_permission(p_role text, p_permission text)
RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT EXISTS (SELECT 1 FROM role_permissions WHERE role = p_role AND permission = p_permission);
$$;

-- GDPR delete
CREATE OR REPLACE FUNCTION gdpr_delete_employee(p_user_id uuid) RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_exists boolean;
BEGIN
  SELECT EXISTS (SELECT 1 FROM employees WHERE id = p_user_id) INTO v_exists;
  IF NOT v_exists THEN RETURN json_build_object('success', false, 'error', 'employee_not_found'); END IF;
  UPDATE employees SET full_name = '[deleted]', email = concat('deleted+', id::text, '@gdpr.local'),
    avatar_url = NULL, is_active = false, archived_at = now(), gdpr_deleted_at = now() WHERE id = p_user_id;
  RETURN json_build_object('success', true, 'deleted_at', now());
END $$;

-- Auto-archive stale leads
CREATE OR REPLACE FUNCTION auto_archive_stale_leads(p_days int DEFAULT 365) RETURNS int LANGUAGE plpgsql AS $$
DECLARE v_count int;
BEGIN
  WITH u AS (UPDATE leads SET archived_at = now(), is_active = false
     WHERE archived_at IS NULL AND status IN ('closed_won','closed_lost')
     AND updated_at < now() - make_interval(days => p_days) RETURNING 1)
  SELECT count(*) INTO v_count FROM u;
  RETURN v_count;
END $$;

-- Org-scoped helper
CREATE OR REPLACE FUNCTION current_user_org() RETURNS uuid LANGUAGE sql STABLE AS $$
  SELECT organization_id FROM employees WHERE id = auth.uid() LIMIT 1
$$;

-- Pipeline stats (DROP first — return type changed from JSONB to TABLE)
DROP FUNCTION IF EXISTS get_pipeline_stats();
CREATE OR REPLACE FUNCTION get_pipeline_stats()
RETURNS TABLE(status TEXT, count BIGINT) LANGUAGE sql STABLE AS $$
  SELECT leads.status, count(*)::BIGINT FROM leads GROUP BY leads.status;
$$;

-- DB table counts
CREATE OR REPLACE FUNCTION get_table_counts()
RETURNS TABLE(table_name TEXT, row_count BIGINT) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT t.tablename::TEXT, (xpath('/row/cnt/text()',
    query_to_xml(format('SELECT count(*) AS cnt FROM %I.%I', t.schemaname, t.tablename), false, true, ''))
  )[1]::TEXT::BIGINT FROM pg_tables t WHERE t.schemaname = 'public' ORDER BY t.tablename;
END $$;

-- Listing reference number
CREATE OR REPLACE FUNCTION generate_listing_ref() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.reference_number IS NULL THEN
    NEW.reference_number := 'SYB-' || to_char(now(), 'YYMMDD') || '-' || substring(NEW.id::text, 1, 4);
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_listing_ref ON listings;
CREATE TRIGGER trg_listing_ref BEFORE INSERT ON listings FOR EACH ROW EXECUTE FUNCTION generate_listing_ref();

-- Updated_at trigger
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

DO $$ BEGIN CREATE TRIGGER set_updated_at BEFORE UPDATE ON listings FOR EACH ROW EXECUTE FUNCTION set_updated_at(); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TRIGGER set_updated_at BEFORE UPDATE ON owners FOR EACH ROW EXECUTE FUNCTION set_updated_at(); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TRIGGER set_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at(); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TRIGGER set_updated_at BEFORE UPDATE ON offplan_projects FOR EACH ROW EXECUTE FUNCTION set_updated_at(); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TRIGGER set_updated_at BEFORE UPDATE ON workflows FOR EACH ROW EXECUTE FUNCTION set_updated_at(); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Stamina RPCs (v7)
CREATE OR REPLACE FUNCTION drain_stamina(p_employee_id UUID, p_amount INT)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_current INT; v_new INT;
BEGIN
  SELECT stamina INTO v_current FROM employees WHERE id = p_employee_id;
  IF v_current IS NULL THEN RETURN jsonb_build_object('ok', false, 'error', 'employee not found'); END IF;
  IF v_current < p_amount THEN RETURN jsonb_build_object('ok', false, 'error', 'not enough stamina', 'stamina', v_current); END IF;
  v_new := GREATEST(0, v_current - p_amount);
  UPDATE employees SET stamina = v_new, updated_at = now() WHERE id = p_employee_id;
  RETURN jsonb_build_object('ok', true, 'stamina', v_new, 'drained', p_amount);
END; $$;

CREATE OR REPLACE FUNCTION regen_stamina(p_employee_id UUID, p_amount INT)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_current INT; v_max INT; v_new INT;
BEGIN
  SELECT stamina, max_stamina INTO v_current, v_max FROM employees WHERE id = p_employee_id;
  IF v_current IS NULL THEN RETURN jsonb_build_object('ok', false, 'error', 'employee not found'); END IF;
  v_new := LEAST(COALESCE(v_max, 100), v_current + p_amount);
  UPDATE employees SET stamina = v_new, updated_at = now() WHERE id = p_employee_id;
  RETURN jsonb_build_object('ok', true, 'stamina', v_new, 'regen', p_amount);
END; $$;

-- Position update (multiplayer)
CREATE OR REPLACE FUNCTION update_position(p_user_id UUID, p_x INT, p_y INT, p_direction TEXT DEFAULT 'down')
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO positions (user_id, x, y, direction, updated_at)
  VALUES (p_user_id, p_x, p_y, p_direction, now())
  ON CONFLICT (user_id) DO UPDATE SET x = p_x, y = p_y, direction = p_direction, updated_at = now();
END; $$;

-- Badge award
CREATE OR REPLACE FUNCTION award_badge(p_user_id UUID, p_badge_name TEXT)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_badge_id UUID;
BEGIN
  SELECT id INTO v_badge_id FROM badges WHERE name = p_badge_name;
  IF v_badge_id IS NULL THEN RETURN jsonb_build_object('ok', false, 'error', 'badge not found'); END IF;
  INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id) ON CONFLICT DO NOTHING;
  RETURN jsonb_build_object('ok', true, 'badge', p_badge_name);
END; $$;

-- Claim Hot Lead (race-condition safe — first claim wins)
CREATE OR REPLACE FUNCTION claim_hot_lead(p_user_id UUID, p_event_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_row hot_lead_events%ROWTYPE;
BEGIN
  -- Atomic update: only succeeds if unclaimed and not expired
  UPDATE hot_lead_events
     SET claimed_by = p_user_id, claimed_at = now()
   WHERE id = p_event_id AND claimed_by IS NULL AND expires_at > now()
  RETURNING * INTO v_row;

  IF v_row.id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'already_claimed_or_expired');
  END IF;

  RETURN jsonb_build_object('ok', true, 'xp_reward', v_row.xp_reward, 'desk_index', v_row.desk_index);
END; $$;

-- Send High Five (with 5-minute cooldown per pair)
CREATE OR REPLACE FUNCTION send_high_five(p_from UUID, p_to UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_last TIMESTAMPTZ;
BEGIN
  IF p_from = p_to THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'cannot_high_five_self');
  END IF;

  -- Check cooldown (5 min between same pair in either direction)
  SELECT MAX(created_at) INTO v_last
    FROM high_fives
   WHERE (from_user = p_from AND to_user = p_to)
      OR (from_user = p_to AND to_user = p_from);

  IF v_last IS NOT NULL AND v_last > now() - INTERVAL '5 minutes' THEN
    RETURN jsonb_build_object('ok', false, 'reason', 'cooldown', 'retry_after', EXTRACT(EPOCH FROM (v_last + INTERVAL '5 minutes' - now()))::INT);
  END IF;

  INSERT INTO high_fives (from_user, to_user) VALUES (p_from, p_to);
  RETURN jsonb_build_object('ok', true);
END; $$;

-- Generate Daily Highlights snapshot
CREATE OR REPLACE FUNCTION generate_daily_highlights(p_admin_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE
  v_best_dealer   JSONB;
  v_most_calls    JSONB;
  v_most_improved JSONB;
  v_mvp           JSONB;
  v_team          JSONB;
  v_today         DATE := CURRENT_DATE;
BEGIN
  -- Best dealer: highest deal value today
  SELECT jsonb_build_object('employee_id', e.id, 'name', e.full_name, 'value',
         COALESCE(SUM((a.details->>'deal_value')::NUMERIC), 0))
    INTO v_best_dealer
    FROM actions_log a JOIN employees e ON a.employee_id = e.id
   WHERE a.created_at::DATE = v_today AND a.action = 'deal_closed'
   GROUP BY e.id, e.full_name
   ORDER BY COALESCE(SUM((a.details->>'deal_value')::NUMERIC), 0) DESC LIMIT 1;

  -- Most calls today
  SELECT jsonb_build_object('employee_id', e.id, 'name', e.full_name, 'count', COUNT(*))
    INTO v_most_calls
    FROM actions_log a JOIN employees e ON a.employee_id = e.id
   WHERE a.created_at::DATE = v_today AND a.action = 'call_made'
   GROUP BY e.id, e.full_name
   ORDER BY COUNT(*) DESC LIMIT 1;

  -- Most improved: biggest XP gain today
  SELECT jsonb_build_object('employee_id', e.id, 'name', e.full_name, 'xp_gained', COALESCE(SUM(a.xp_earned), 0))
    INTO v_most_improved
    FROM actions_log a JOIN employees e ON a.employee_id = e.id
   WHERE a.created_at::DATE = v_today
   GROUP BY e.id, e.full_name
   ORDER BY COALESCE(SUM(a.xp_earned), 0) DESC LIMIT 1;

  -- MVP: highest combined score (XP + coins)
  SELECT jsonb_build_object('employee_id', e.id, 'name', e.full_name,
         'xp', COALESCE(SUM(a.xp_earned), 0), 'coins', COALESCE(SUM(a.coins_earned), 0))
    INTO v_mvp
    FROM actions_log a JOIN employees e ON a.employee_id = e.id
   WHERE a.created_at::DATE = v_today
   GROUP BY e.id, e.full_name
   ORDER BY (COALESCE(SUM(a.xp_earned), 0) + COALESCE(SUM(a.coins_earned), 0)) DESC LIMIT 1;

  -- Team totals
  SELECT jsonb_build_object(
    'total_calls', COUNT(*) FILTER (WHERE action = 'call_made'),
    'total_deals', COUNT(*) FILTER (WHERE action = 'deal_closed'),
    'total_xp', COALESCE(SUM(xp_earned), 0),
    'total_coins', COALESCE(SUM(coins_earned), 0))
    INTO v_team
    FROM actions_log WHERE created_at::DATE = v_today;

  INSERT INTO daily_highlights (highlight_date, best_dealer, most_calls, most_improved, daily_mvp, team_stats, generated_by)
  VALUES (v_today,
    COALESCE(v_best_dealer, '{}'), COALESCE(v_most_calls, '{}'),
    COALESCE(v_most_improved, '{}'), COALESCE(v_mvp, '{}'),
    COALESCE(v_team, '{}'), p_admin_id)
  ON CONFLICT (highlight_date) DO UPDATE SET
    best_dealer = EXCLUDED.best_dealer, most_calls = EXCLUDED.most_calls,
    most_improved = EXCLUDED.most_improved, daily_mvp = EXCLUDED.daily_mvp,
    team_stats = EXCLUDED.team_stats, generated_by = EXCLUDED.generated_by;

  RETURN jsonb_build_object('ok', true, 'best_dealer', COALESCE(v_best_dealer, '{}'),
    'most_calls', COALESCE(v_most_calls, '{}'), 'most_improved', COALESCE(v_most_improved, '{}'),
    'daily_mvp', COALESCE(v_mvp, '{}'), 'team_stats', COALESCE(v_team, '{}'));
END; $$;

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
ALTER TABLE leads           ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_notes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE quests          ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_purchases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS agent_own_leads ON leads;
CREATE POLICY agent_own_leads ON leads FOR SELECT USING (assigned_to = auth.uid());
DROP POLICY IF EXISTS agent_own_notes ON lead_notes;
CREATE POLICY agent_own_notes ON lead_notes FOR ALL USING (
    employee_id = auth.uid() OR lead_id IN (SELECT id FROM leads WHERE assigned_to = auth.uid()));
DROP POLICY IF EXISTS agent_own_msgs ON whatsapp_messages;
CREATE POLICY agent_own_msgs ON whatsapp_messages FOR ALL USING (
    employee_id = auth.uid() OR lead_id IN (SELECT id FROM leads WHERE assigned_to = auth.uid()));
DROP POLICY IF EXISTS agent_own_quests ON quests;
CREATE POLICY agent_own_quests ON quests FOR ALL USING (employee_id = auth.uid());
DROP POLICY IF EXISTS agent_own_purchases ON employee_purchases;
CREATE POLICY agent_own_purchases ON employee_purchases FOR ALL USING (employee_id = auth.uid());

-- Enable RLS on all tables
DO $$ BEGIN
  ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;
  ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;
  ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
  ALTER TABLE owners ENABLE ROW LEVEL SECURITY;
  ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
  ALTER TABLE offplan_projects ENABLE ROW LEVEL SECURITY;
  ALTER TABLE workflows ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lead_rotation_rules ENABLE ROW LEVEL SECURITY;
  ALTER TABLE custom_fields ENABLE ROW LEVEL SECURITY;
  ALTER TABLE custom_field_values ENABLE ROW LEVEL SECURITY;
  ALTER TABLE kpi_targets ENABLE ROW LEVEL SECURITY;
  ALTER TABLE store_items ENABLE ROW LEVEL SECURITY;
  ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
  ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
  ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;
END $$;

-- Service role bypass policies
DO $$
DECLARE t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'activity_feed','admin_audit_log','listings','owners','transactions',
    'offplan_projects','workflows','lead_rotation_rules','custom_fields',
    'custom_field_values','kpi_targets','store_items','employee_purchases',
    'teams','team_members','competitions','lead_notes','lead_status_history',
    'whatsapp_messages','message_templates','rate_limit_log','competition_participants',
    'hot_lead_events','high_fives','power_hours','daily_highlights'
  ]) LOOP
    BEGIN
      EXECUTE format('CREATE POLICY "service_all_%s" ON %I FOR ALL USING (true) WITH CHECK (true)', t, t);
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END LOOP;
END $$;

-- =====================================================================
-- SEED DATA
-- =====================================================================

-- Store items
INSERT INTO store_items (name, description, item_type, coin_price, level_required, icon, effect) VALUES
 ('XP Booster x2 (1h)',  'ضاعف الـ XP لمدة ساعة',     'boost',  50,  2, '⚡',  '{"xp_multiplier":2,  "duration_hours":1}'),
 ('XP Booster x3 (30m)', 'ضاعف الـ XP x3 لنصف ساعة', 'boost',  120, 5, '🔥', '{"xp_multiplier":3,  "duration_hours":0.5}'),
 ('Golden Badge',        'شارة ذهبية دائمة',         'badge',  500, 10,'🏆', '{"permanent":true}'),
 ('Premium Avatar',      'افاتار بريميوم',           'avatar', 300, 5, '👑', '{"permanent":true}'),
 ('Day Off Voucher',     'يوم إجازة مدفوع',          'real_reward', 2000, 15, '🎫', '{}')
ON CONFLICT DO NOTHING;

-- Badges
INSERT INTO badges (name, description, icon, criteria, rarity) VALUES
  ('first_blood',  'First closed deal',              '🏆', '{"type":"deals_closed","count":1}',    'common'),
  ('centurion',    '100 calls in one day',            '📞', '{"type":"daily_calls","count":100}',   'rare'),
  ('whale_hunter', 'Closed deal worth 100k+',         '🐋', '{"type":"deal_value","min":100000}',   'legendary'),
  ('marathon',     'Worked 8 hours straight',          '🏃', '{"type":"work_hours","count":8}',      'rare'),
  ('team_player',  'Helped close team target',         '🤝', '{"type":"team_target","count":1}',     'uncommon'),
  ('speed_demon',  '10 calls in 30 minutes',           '⚡', '{"type":"speed_calls","count":10}',    'rare'),
  ('perfectionist','100% conversion in a day',         '💎', '{"type":"daily_conversion","pct":100}','legendary'),
  ('early_bird',   'Logged in before 7am',             '🌅', '{"type":"early_login","hour":7}',      'uncommon'),
  ('night_owl',    'Worked past 10pm',                 '🦉', '{"type":"late_work","hour":22}',       'uncommon'),
  ('streak_7',     'Met daily target 7 days in a row', '🔥', '{"type":"streak","days":7}',           'rare'),
  ('hot_hands',    'Claimed 5 Hot Leads',              '🔥', '{"type":"hot_leads_claimed","count":5}','uncommon'),
  ('social_star',  'Gave 50 High Fives',               '🙌', '{"type":"high_fives_given","count":50}','rare'),
  ('power_player', 'Closed deal during Power Hour',    '⚡', '{"type":"power_hour_deal","count":1}', 'uncommon')
ON CONFLICT (name) DO NOTHING;

-- ==================== ATTENDANCE (Check-in / Check-out) ====================

CREATE TABLE IF NOT EXISTS attendance (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id     UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date            DATE NOT NULL DEFAULT CURRENT_DATE,
    check_in        TIMESTAMPTZ,
    check_out       TIMESTAMPTZ,
    hours_worked    NUMERIC(5,2),
    status          TEXT DEFAULT 'present' CHECK (status IN ('present','late','absent','half_day','remote')),
    notes           TEXT,
    -- GPS fields
    latitude        NUMERIC(10,7),
    longitude       NUMERIC(10,7),
    gps_verified    BOOLEAN DEFAULT false,
    gps_distance_m  NUMERIC(8,1),
    created_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(employee_id, date)
);
-- Safe ALTER for GPS columns (in case table was created without them)
DO $$ BEGIN ALTER TABLE attendance ADD COLUMN latitude       NUMERIC(10,7);       EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE attendance ADD COLUMN longitude      NUMERIC(10,7);       EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE attendance ADD COLUMN gps_verified   BOOLEAN DEFAULT false; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE attendance ADD COLUMN gps_distance_m NUMERIC(8,1);        EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Outbound webhooks table
CREATE TABLE IF NOT EXISTS webhooks (
    id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    url        TEXT NOT NULL,
    events     TEXT[] NOT NULL DEFAULT ARRAY['*'],
    secret     TEXT DEFAULT '',
    is_active  BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE webhooks ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
    CREATE POLICY webhooks_admin ON webhooks FOR ALL USING (
        EXISTS (SELECT 1 FROM employees WHERE id = auth.uid() AND role = 'admin')
    );
    EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_attendance_employee ON attendance(employee_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date     ON attendance(date);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
    CREATE POLICY attendance_self ON attendance FOR SELECT USING (employee_id = auth.uid());
    EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
    CREATE POLICY attendance_insert ON attendance FOR INSERT WITH CHECK (employee_id = auth.uid());
    EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
    CREATE POLICY attendance_admin ON attendance FOR ALL USING (
        EXISTS (SELECT 1 FROM employees WHERE id = auth.uid() AND role IN ('admin','manager'))
    );
    EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Extend action_type enum for attendance
DO $$ BEGIN
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'check_in';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TYPE action_type ADD VALUE IF NOT EXISTS 'check_out'; EXCEPTION WHEN OTHERS THEN NULL; END;
EXCEPTION WHEN OTHERS THEN NULL;
END$$;

-- =====================================================================
-- AD CAMPAIGNS (الإعلانات)
-- =====================================================================

CREATE TABLE IF NOT EXISTS ad_campaigns (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id          UUID REFERENCES projects(id),
    name                TEXT NOT NULL,
    platform            TEXT NOT NULL CHECK (platform IN (
        'facebook','google','instagram','tiktok','snapchat',
        'twitter','linkedin','youtube','sms','email','other'
    )),
    platform_campaign_id TEXT,          -- ID من منصة الإعلان
    status              TEXT DEFAULT 'active' CHECK (status IN ('draft','active','paused','ended')),
    budget              NUMERIC(12,2) DEFAULT 0,
    spent               NUMERIC(12,2) DEFAULT 0,
    currency            TEXT DEFAULT 'AED',
    start_date          DATE,
    end_date            DATE,
    target_audience     TEXT,
    ad_content          JSONB DEFAULT '{}',  -- العنوان + الوصف + رابط الصورة
    impressions         INT DEFAULT 0,
    clicks              INT DEFAULT 0,
    utm_source          TEXT,
    utm_medium          TEXT,
    utm_campaign        TEXT,
    notes               TEXT,
    created_by          UUID REFERENCES employees(id),
    created_at          TIMESTAMPTZ DEFAULT now(),
    updated_at          TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ad_campaigns_project  ON ad_campaigns(project_id);
CREATE INDEX IF NOT EXISTS idx_ad_campaigns_platform ON ad_campaigns(platform);
CREATE INDEX IF NOT EXISTS idx_ad_campaigns_status   ON ad_campaigns(status);

ALTER TABLE ad_campaigns ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
    CREATE POLICY ad_campaigns_admin ON ad_campaigns FOR ALL USING (
        EXISTS (SELECT 1 FROM employees WHERE id = auth.uid() AND role IN ('admin','manager'))
    );
    EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
    CREATE POLICY ad_campaigns_read ON ad_campaigns FOR SELECT USING (true);
    EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ربط الليدز بالإعلانات + UTM tracking
ALTER TABLE leads ADD COLUMN IF NOT EXISTS ad_campaign_id UUID REFERENCES ad_campaigns(id);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS utm_source     TEXT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS utm_medium     TEXT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS utm_campaign   TEXT;
CREATE INDEX IF NOT EXISTS idx_leads_ad_campaign ON leads(ad_campaign_id) WHERE ad_campaign_id IS NOT NULL;

-- ==================== AD CAMPAIGN WEBHOOK COLUMNS ====================
-- webhook_key: API key for generic webhook lead ingestion
-- facebook_page_id / facebook_form_id: match incoming Facebook leadgen events
-- auto_assign: round-robin assign incoming webhook leads to agents
DO $$ BEGIN ALTER TABLE ad_campaigns ADD COLUMN webhook_key        TEXT UNIQUE;          EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ad_campaigns ADD COLUMN facebook_page_id   TEXT;                 EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ad_campaigns ADD COLUMN facebook_form_id   TEXT;                 EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ad_campaigns ADD COLUMN auto_assign        BOOLEAN DEFAULT false; EXCEPTION WHEN duplicate_column THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ad_campaigns ADD COLUMN webhook_leads_count INT DEFAULT 0;       EXCEPTION WHEN duplicate_column THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_ad_campaigns_webhook_key ON ad_campaigns(webhook_key) WHERE webhook_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ad_campaigns_fb_page     ON ad_campaigns(facebook_page_id) WHERE facebook_page_id IS NOT NULL;

-- =====================================================================
-- DONE. All tables, RPCs, triggers, RLS, and seed data in one file.
-- =====================================================================
