-- =====================================================================
-- DROP EVERYTHING — Run this FIRST, then run schema_complete.sql
-- WARNING: This deletes ALL data. Only use on fresh setup.
-- =====================================================================

-- 1. Drop all triggers
DO $$ DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public')
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I CASCADE', r.trigger_name, r.event_object_table);
  END LOOP;
END $$;

-- 2. Drop all functions
DO $$ DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT ns.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args
            FROM pg_proc p JOIN pg_namespace ns ON p.pronamespace = ns.oid
            WHERE ns.nspname = 'public')
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE', r.nspname, r.proname, r.args);
  END LOOP;
END $$;

-- 3. Drop all tables (order matters for foreign keys, CASCADE handles it)
DO $$ DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
  LOOP
    EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', r.tablename);
  END LOOP;
END $$;

-- 4. Drop all custom types/enums
DO $$ DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT typname FROM pg_type t JOIN pg_namespace n ON t.typnamespace = n.oid
            WHERE n.nspname = 'public' AND t.typtype = 'e')
  LOOP
    EXECUTE format('DROP TYPE IF EXISTS %I CASCADE', r.typname);
  END LOOP;
END $$;

-- Done. Now run schema_complete.sql
