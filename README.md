<p align="center">
  <img src="https://img.shields.io/badge/Flask-Backend-blue?style=for-the-badge&logo=flask" />
  <img src="https://img.shields.io/badge/Supabase-Database-3ECF8E?style=for-the-badge&logo=supabase" />
  <img src="https://img.shields.io/badge/WhatsApp-API-25D366?style=for-the-badge&logo=whatsapp" />
  <img src="https://img.shields.io/badge/AI-Claude%20%7C%20OpenAI-FF6600?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Phaser%203-Game%20Engine-yellow?style=for-the-badge" />
</p>

# AlSaeb CRM - Lead Hunter

> A gamified CRM system that transforms daily sales operations into an RPG experience with XP, levels, coins, quests, leaderboards, and competitions.

**Live:** [https://al-saeb-crm.online](https://al-saeb-crm.online)

---

## Overview

AlSaeb CRM (a.k.a. "Lead Hunter") is a full-featured Customer Relationship Management system designed for real estate sales teams. It combines professional CRM functionality with RPG-style gamification to boost team productivity and engagement.

### Key Features

**CRM Core:**
- Lead management with full lifecycle tracking (New > Contacted > Interested > Meeting > Negotiation > Won/Lost)
- WhatsApp Business API integration (send/receive messages directly from CRM)
- AI-powered lead analysis and suggestions (Claude / OpenAI)
- Excel import/export with duplicate detection
- Automated lead distribution (Round Robin)
- Real-time notifications (sound, vibration, browser push)
- Campaign & ads management with webhooks
- Attendance tracking with GPS geofencing
- PDF reports generation

**Gamification Engine:**
- XP & Coins system for every sales action
- Level progression with titles
- Daily quests with rewards
- Leaderboards (weekly/monthly)
- Achievement badges
- Store to spend coins
- Competitions between agents
- Squads/Alliances
- Power Hours (XP multipliers)
- Hot Lead events (race to claim)
- High Fives (social interactions)
- Daily Highlights cinematic
- Stamina system with break room recovery

**4 Browser-Based UIs:**
- **Admin Panel** (`/admin`) - Full management dashboard with KPIs, analytics, team management
- **Agent PWA** (`/agent`) - Mobile-first sales agent interface with real-time WhatsApp chat
- **2D Office Game** (`/game`) - Phaser 3 multiplayer office with CRM integration
- **NEON CITY Map** (`/map`) - Cyberpunk city journey map with 5 zones, 20 landmarks, fog of war

**Real Estate Module:**
- Property listings management
- Owner database with Excel import
- Transactions & commission tracking
- Off-plan project management
- Viewing requests & approvals

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Flask (Python) - Single file architecture (~5000 lines) |
| Database | Supabase (PostgreSQL) with 20+ RPCs |
| Auth | Supabase JWT + Row Level Security |
| WhatsApp | Meta Business API + Webhooks |
| AI | Anthropic Claude / OpenAI (with fallback) |
| Frontend | Vanilla JS + Tailwind CDN + Supabase JS SDK |
| Game Engine | Phaser 3 CDN |
| Hosting | Ubuntu 22.04 + Gunicorn + Nginx + SSL |
| Payments | Stripe (optional) |

---

## Security (9/10)

| Protection | Status |
|-----------|--------|
| HTTPS/SSL (Let's Encrypt) | Enforced |
| JWT Authentication | All endpoints |
| RBAC (Admin/Manager/Agent) | Enforced |
| SQL Injection | Protected (Supabase SDK) |
| XSS | Protected (escaping + headers) |
| CSRF | Protected (JWT + custom headers) |
| CORS | Whitelisted origins only |
| Rate Limiting | Fail-closed |
| Security Headers | HSTS, X-Frame-Options, X-Content-Type-Options |
| Webhook Verification | HMAC-SHA256 |
| File Upload | 10MB limit + extension validation |
| Token Refresh | Auto-refresh via Supabase SDK |
| Audit Logging | All admin actions logged |

---

## Quick Start

### Prerequisites
- Python 3.10+
- Supabase project (free tier works)
- `.env` file (see `env.example`)

### Installation

```bash
# Clone
git clone https://github.com/heshamhussin961-design/gamified-crm.git
cd gamified-crm

# Install dependencies
pip install -r requirements.txt

# Setup database
# Run schema_complete.sql in Supabase SQL Editor
# Optionally run seed_demo.sql for demo data

# Configure environment
cp env.example .env
# Edit .env with your Supabase keys

# Run
python app.py
```

### Docker

```bash
docker compose up --build
```

### Production Deployment

```bash
# Gunicorn (4 workers, 8 threads)
gunicorn app:app -w 4 --threads 8 -b 0.0.0.0:5003

# With Nginx reverse proxy + Certbot SSL
```

---

## Commands

```bash
# Development server
python app.py

# Tests (uses FakeSupabase - no network)
pytest
pytest tests/test_phase9.py
pytest -k "permissions"

# Lint
ruff check .
ruff check --fix .

# Import leads from Excel
python import_leads.py --file leads.xlsx

# Distribute leads to agents
python distribute_leads.py
```

---

## Project Structure

```
gamified-crm/
  app.py                  # Flask backend (~5000 lines, ~170 routes)
  ai_client.py            # AI analysis (Claude/OpenAI/fallback)
  whatsapp_client.py      # WhatsApp Business API wrapper
  schema_complete.sql     # Full database schema (safe to re-run)
  schema_DROP_ALL.sql     # Database reset script
  seed_demo.sql           # Demo data (5 employees, 50 leads)
  requirements.txt        # Python dependencies
  Dockerfile              # Production Docker image
  docker-compose.yml      # Docker Compose config
  env.example             # Environment variables template
  templates/
    admin.html            # Admin SPA
    agent.html            # Agent PWA
    game.html             # 2D Office Game (Phaser 3)
    map.html              # NEON CITY Journey Map
  static/
    manifest.json         # PWA manifest
    sw.js                 # Service worker
    icon-*.png            # App icons
  tests/
    conftest.py           # FakeSupabase fixture
    test_phase*.py        # Test suites
  USER_GUIDE.md           # Complete user guide (Arabic)
  PROJECT_PLAN.md         # Roadmap (Arabic)
```

---

## Database Architecture

The database uses **PostgreSQL RPCs** for critical operations:

| RPC | Purpose |
|-----|---------|
| `award_xp_and_coins` | Single path for XP/coins/level mutations |
| `change_lead_status` | State machine validator for lead transitions |
| `distribute_leads_to_agents` | Round-robin bulk distribution |
| `acquire_lead_lock` / `release_lead_lock` | Pessimistic locking with TTL |
| `increment_employee_counter` | Atomic counter updates |
| `purchase_store_item` | Transactional store purchases |
| `check_rate_limit` | Per-user rate limiting |
| `claim_hot_lead` | Race-condition safe atomic claim |
| `generate_daily_highlights` | End-of-day cinematic data |

---

## API Endpoints

The backend serves ~170 routes organized by section:

- **Auth** - Login, signup, password reset, 2FA
- **Leads** - CRUD, import, distribute, lock, status transitions
- **Actions** - WhatsApp, calls, meetings, deals, notes
- **Gamification** - XP, quests, leaderboard, badges, store, competitions
- **Game** - Positions, stamina, break room, hot leads, high fives, power hours
- **Admin** - Employees, teams, KPIs, analytics, audit log
- **Real Estate** - Listings, owners, transactions, off-plan
- **WhatsApp** - Send/receive messages, webhook handler
- **AI** - Lead analysis, weekly reports
- **Ads** - Campaigns, webhooks, lead capture

---

## Screenshots

| Admin Dashboard | Agent Mobile | 2D Office Game | NEON CITY Map |
|:-:|:-:|:-:|:-:|
| KPIs, Analytics, Team Management | Leads, Chat, Quests, XP | Multiplayer Office with CRM | Cyberpunk Journey Map |

---

## License

Copyright (c) 2026 **Hesham Hussin** - All Rights Reserved.

This software is proprietary. See [LICENSE](LICENSE) for details.

---

## Author

**Hesham Hussin**
- GitHub: [@heshamhussin961-design](https://github.com/heshamhussin961-design)
- Project: AlSaeb Construction CRM

---

<p align="center">
  <strong>AlSaeb CRM</strong> - Turn your sales team into heroes
</p>
