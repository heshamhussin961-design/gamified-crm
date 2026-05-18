# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

AlSaeb CRM (a.k.a. "Lead Hunter") — Flask + Supabase backend that turns sales-team CRM actions (WhatsApp, calls, meetings, deals) into an RPG with XP, levels, coins, quests, store, leaderboard, and competitions. Four browser UIs are served from `templates/` (admin SPA, agent PWA, 2D office game, cyberpunk city map); there is **no frontend build step** — everything is vanilla JS + Tailwind CDN + Supabase JS SDK + Phaser 3 CDN. Status and roadmap live in `PROJECT_PLAN.md` (mostly Arabic).

## Commands

```powershell
# install
pip install -r requirements.txt

# run dev server (port 5000)
python app.py

# tests (uses FakeSupabase fixture — never hits network)
pytest                              # all tests
pytest tests/test_phase9.py         # one file
pytest -k "permissions"             # one test by name

# lint (ruff configured in pyproject.toml — line-length 100, ignores E501/E402 for Arabic comments + late load_dotenv)
ruff check .
ruff check --fix .

# docker
docker compose up --build           # gunicorn 4 workers, 8 threads, healthchecked at /api/config

# bulk operations (need .env with SUPABASE_SERVICE_KEY)
python import_leads.py --file عمرو.xlsx           # clean + dedupe Excel → SQL or Supabase
python distribute_leads.py                         # round-robin assign leads from عمرو_leads.json
```

`.env` is required for everything that touches Supabase. See `env.example` for the full list — most importantly `SUPABASE_URL`, `SUPABASE_SERVICE_KEY` (backend), `SUPABASE_ANON_KEY` (exposed to browser via `/api/config`), and the WhatsApp/AI keys (all of which fail gracefully when absent).

## Architecture

### Backend = single Flask file, ~135 routes

`app.py` is one ~3500-line file organized by `# ==================== SECTION ====================` banners. Each section groups related endpoints (LEADS, ACTIONS, QUESTS, LEADERBOARD, STORE, COMPETITIONS, LISTINGS, TRANSACTIONS, BREAK ROOM, CEO VISITS, SQUADS, STORY MODE, BILLING, etc.). When adding endpoints, find the matching banner rather than creating new modules — the project intentionally stays in one file.

### Heavy use of PostgreSQL RPCs (NOT app-side logic)

The "magic" lives in Supabase Postgres functions, not Python. Critical RPCs (defined in `schema_complete.sql`):

- `award_xp_and_coins` — **the only path that mutates XP/coins/level/title.** Never write `UPDATE employees SET total_xp = ...` directly; route everything through this RPC so leveling, title transitions, and side-effects (quest progress trigger) stay consistent.
- `change_lead_status` — state-machine validator for lead status transitions; also writes `lead_status_history`.
- `distribute_leads_to_agents` — single-statement round-robin distribution using `ROW_NUMBER() OVER ... % num_agents` for thousands of leads at once.
- `acquire_lead_lock` / `release_lead_lock` — pessimistic lock with TTL so two agents don't work the same lead.
- `increment_employee_counter` — atomic counter bump (use this instead of `SELECT … then UPDATE` to avoid races on `total_messages` / `total_calls` / `total_deals`).
- `drain_stamina` / `regen_stamina` — game stamina mechanics; blocks actions at 0, regens in break room.
- `update_position` — multiplayer position upsert for the 2D office game.
- `award_badge` — server-side badge award with duplicate prevention.
- `claim_hot_lead` — race-condition safe atomic claim of random hot lead events; first player wins.
- `send_high_five` — social interaction between two players with 5-minute cooldown per pair.
- `generate_daily_highlights` — end-of-day cinematic data: best dealer, most calls, most improved, MVP, team stats.
- `purchase_store_item`, `generate_daily_quests`, `progress_matching_quests`, `refresh_leaderboard`, `refresh_competition_scores`, `finalize_competition`, `check_rate_limit`, `auto_archive_stale_leads`, `gdpr_delete_employee`, `has_permission`.

Schema is a single consolidated file: `schema_complete.sql` (safe to re-run — uses `IF NOT EXISTS` / `OR REPLACE` / `EXCEPTION` blocks). To reset the database, run `schema_DROP_ALL.sql` first, then `schema_complete.sql`. For demo data, run `seed_demo.sql` after schema (5 employees, 50 leads, sample actions).

### Auth & RBAC decorators (compose them in this order)

Defined in `app.py` lines ~104-186. Stack on each endpoint:

```python
@app.route(...)
@check_role(['admin'])                  # 1. role check (calls @require_auth internally)
@audit_log('action_name', 'target')     # 2. logs to admin_audit_log AFTER the handler runs
@rate_limit('endpoint_key', max_per_min=30)  # alternative: rate-limit instead of role-check
def handler(...): ...
```

Auth is Supabase JWT via `Authorization: Bearer <token>`. The decorator attaches `request.user_id` and `request.user`. `@audit_log` reads `kwargs` (looks for `project_id`, `team_id`, `comp_id`, `lead_id`, `user_id`) to determine the audit target — so name path params consistently.

### Frontends (no build step)

- `templates/admin.html` — admin SPA (Tailwind + Supabase JS SDK loaded from CDN). Professional dark theme.
- `templates/agent.html` — sales-agent PWA (manifest in `static/manifest.json`, service worker in `static/sw.js`). Professional dark theme.
- `templates/game.html` — 2D office game (Phaser 3 CDN). Grid-based movement, CRM modal, stamina, multiplayer, badges, Hot Leads, High Fives, Power Hours, Daily Highlights cinematic, mobile touch D-pad, **V2: Cosmetics Shop, Villain System, CEO Boss Visits, Interactive Break Room (coffee machine + mini-game), Squads/Alliances**.
- `templates/map.html` — cyberpunk city journey map. SVG neon city with 20 unique landmark buildings, 120+ procedural background buildings, neon signs, street lamps, stars, car avatar driven by XP progress.

The browser uses Supabase RLS via the **anon key** (served from `/api/config`); the backend uses the **service key**. Never leak the service key to the client.

### AI & WhatsApp clients

`ai_client.py` — `analyze_lead(lead, messages)` is the single entry point. Provider priority: `ANTHROPIC_API_KEY` → `OPENAI_API_KEY` → heuristic `_fallback`. Anthropic call uses prompt caching (`cache_control: ephemeral` on the system prompt). Default Anthropic model is `claude-haiku-4-5-20251001`. Always returns the same JSON shape: `{suggestion, lead_score, sentiment, recommended_action, recommended_template}`.

`whatsapp_client.py` — wraps Meta Graph API. **All methods fail gracefully** when credentials are missing, returning `{ok: False, skipped: True}` so the CRM stays usable in dev. Don't add `if WHATSAPP_TOKEN:` guards in callers — the client already does this.

### Tests use a FakeSupabase fixture

`tests/conftest.py` defines `FakeSupabase`, a fluent stub for the Supabase Python SDK that records calls and returns scripted data. The `client` fixture stubs `supabase.auth.get_user` to always return `test-user-id`. The `admin_supabase` fixture additionally sets the employee role to `admin` so `@check_role` passes. No tests hit the real database. When adding endpoints, write tests in this style — assert on `fake_supabase.calls()` and `fake_supabase.rpc_calls()` instead of network responses.

## Conventions

- **XP/coins/counters** — always go through the matching RPC (`award_xp_and_coins`, `increment_employee_counter`). Direct table updates will desync gamification side-effects. Call `get_power_hour_multiplier()` before awarding XP in action endpoints — it returns the active Power Hour multiplier (or 1.0).
- **Action logging** — endpoints that earn XP also insert a row into `actions_log` with `action`, `xp_earned`, `coins_earned`, `details` (JSONB). The `progress_matching_quests` trigger reads from this table.
- **Response shape** — use `success_response(data, message, status)` and `error_response(message, status)` helpers (defined ~line 191) for consistency. They wrap everything with `status`/`message`/`timestamp`.
- **Arabic in code** — comments, log messages, and user-facing strings are often Arabic. Ruff `E501` (long lines) is ignored because of this; preserve Arabic strings exactly.
- **`load_dotenv()` runs before `import ai_client` / `import whatsapp_client`** — that's why `E402` is globally ignored. Don't reorder these top-of-file imports.