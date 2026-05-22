# Digital Vikoba

Production-ready offline-first platform for VICOBA/VSLA community savings groups in Tanzania.

## Architecture

```
Flutter Mobile App (Android)
        ↓
Laravel REST API (JWT)
        ↓
Offline Sync Engine + Redis Queue
        ↓
MySQL 8 (InnoDB)
        ↓
Mobile Money APIs + Africa's Talking (SMS/USSD)
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter 3.x (Android-first, encrypted SQLite) |
| Backend | Laravel 12, PHP 8.2+ |
| Database | MySQL 8, InnoDB |
| Cache/Queue | Redis |
| Admin | React + Tailwind + Vite |
| DevOps | Docker Compose, Nginx, GitHub Actions |

## Project Structure

```
Digital-Vicoba/
├── backend/          # Laravel API
├── mobile/           # Flutter app
├── admin/            # React admin dashboard
├── database/schema/  # Raw SQL reference schema
├── nginx/            # Reverse proxy config
└── docker-compose.yml
```

## Quick Start

### Prerequisites

- PHP 8.2+, Composer
- MySQL 8
- Redis
- Flutter 3.x
- Node.js 20+ (admin)

### Backend (Laravel) — XAMPP MySQL

1. Start **Apache** and **MySQL** in the XAMPP Control Panel.
2. Create the database (once):

```bash
# Option A: phpMyAdmin → SQL → run database/scripts/create_mysql_database.sql
# Option B: command line
C:\xampp\mysql\bin\mysql.exe -u root -e "CREATE DATABASE IF NOT EXISTS digital_vicoba CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

3. Configure and migrate:

```bash
cd backend
copy .env.example .env
composer install
php artisan key:generate
```

Ensure `backend/.env` uses MySQL (default in `.env.example`):

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=digital_vicoba
DB_USERNAME=root
DB_PASSWORD=
```

```bash
php artisan migrate:fresh --seed
php artisan serve
```

All API data (users, groups, shares, loans, sync queue, etc.) is stored in **MySQL** `digital_vicoba`, not SQLite.

API base: `http://localhost:8000/api/v1`

**Dev OTP:** `123456` (non-production)

### Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter gen-l10n
flutter run
```

Android emulator API URL: `http://10.0.2.2:8000/api/v1`

### Admin Dashboard

```bash
cd admin
npm install
npm run dev
```

Open: `http://localhost:5173/admin/`

### Docker

```bash
cp .env.example .env
docker compose up -d
```

## API Modules

- `POST /api/v1/auth/*` — Registration, OTP, PIN login, JWT refresh
- `GET/POST /api/v1/groups` — Group management
- `GET/POST /api/v1/groups/{id}/members` — Members
- `POST /api/v1/groups/{id}/shares` — Share purchases
- `POST /api/v1/groups/{id}/contributions` — Savings
- `POST /api/v1/groups/{id}/loans` — Loans (guarantors, voting, disbursement)
- `POST /api/v1/meetings/{id}/attendance` — Meeting attendance
- `POST /api/v1/groups/{id}/share-out/*` — Automated share-out
- `POST /api/v1/sync/push` — Offline sync
- `POST /api/v1/mobile-money/*` — M-Pesa, Airtel, Mixx, HaloPesa
- `POST /api/v1/ussd/callback` — USSD (Africa's Talking)

## Platform split

- **Mobile app** — day-to-day VICOBA group operations: members, governance, meetings, savings, loans, share-out.
- **Web admin (`/admin`)** — platform operators only (Super Admin / Regional Admin): analytics, users, fraud, system settings. No group-level treasurer/secretary workflows.

## Interim chairperson (group founder)

When the first member creates a group, they receive the `provisional_chair` role until `governance_complete` is true. During this period they may register members and run governance setup (elections / leadership assignment). Full chairperson/treasurer/secretary RBAC applies after chairperson, secretary, and treasurer are assigned via `leadership_roles`.

## User Roles

Super Admin, Regional Admin, Provisional Chair, Chairperson, Secretary, Treasurer, Money Counter, Key Holder, Member, Trainer/Field Officer — each with RBAC permissions.

## Offline-First (Mobile)

- Encrypted SQLite via `sqflite_sqlcipher`
- Local sync queue with client IDs (duplicate prevention)
- Background sync on connectivity restore
- Timestamp-based conflict detection + manual resolution

## Localization

- Primary: **Kiswahili** (`sw`)
- Secondary: **English** (`en`)
- Currency: **TZS**

## Security

- JWT access + refresh tokens
- PIN hashing (bcrypt)
- AES-256 encrypted local DB
- Audit logs
- Fraud detection (duplicates, rapid withdrawals, off-hours)
- Multi-signature approvals for sensitive operations

## Mobile Money

Integrated providers (sandbox-ready): M-Pesa, Airtel Money, Mixx by Yas, HaloPesa

## USSD

Dial `14999#` — Swahili menus, max 3 levels (balance, loan status, savings confirmation)

## License

See [LICENSE](LICENSE)
