# Performance Evaluation System

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Frontend-Flutter%203.x-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Backend-Node.js%20Express-339933?logo=node.js)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/Database-Supabase%20PostgreSQL-4169E1?logo=postgresql)](https://supabase.com)
[![Swagger](https://img.shields.io/badge/API_Docs-OpenAPI_3.0-85EA2D?logo=swagger)](http://localhost:5000/api/docs)

A production-inspired, scalable, and maintainable **Multi-Tenant Performance Evaluation System** built with **Flutter** (Mobile & Web), **Node.js / Express.js** (REST API), and **Supabase PostgreSQL** (Relational Database).

The system serves multiple client companies through a single universal login portal with complete multi-tenant data isolation. It dynamically models both multi-tier corporate hierarchies and flat startup reporting structures, standardizes monthly evaluations around 5 fixed performance dimensions, tracks HR compliance in real time, and provides employee score trend analytics.

---

## Features

- **Multi-Company Support**: Serves multiple client organizations independently within a unified infrastructure.
- **Single Login Page**: All users authenticate on the exact same login screen using only **Email** and **Password**. Company context is automatically derived from the database user record upon login.
- **Employee Portal**: Personalized dashboard displaying current month feedback, 5-parameter ratings, historical review timeline, and month-over-month score trend graphs.
- **Manager Portal**: Dashboard tracking direct report progress, interactive team roster search/filter, and a 5-parameter feedback form supporting draft saves and finalized submissions.
- **HR Dashboard**: Organization-wide compliance tracking dashboard with total employee counts, completed review ratios, manager progress bars, and `fl_chart` completion donut charts.
- **Monthly Performance Evaluations**: Time-bound review cycles (`YYYY-MM`) enforcing one finalized evaluation per employee per month.
- **Five Fixed Evaluation Parameters**: Standardized evaluation metrics across 5 fixed dimensions:
  1. *Quality of Work*
  2. *Productivity & Efficiency*
  3. *Communication & Teamwork*
  4. *Problem Solving & Initiative*
  5. *Ownership & Reliability*
- **Evaluation History**: Read-only timeline of all past submitted reviews.
- **Score Trend Charts**: Interactive visual charts tracking progress across parameter scores over time.
- **JWT Authentication**: Stateless, secure authorization encoding user claims (`userId`, `companyId`, `role`, `email`).
- **Role-Based Access Control (RBAC)**: Fine-grained access control for `EMPLOYEE`, `MANAGER`, and `HR` roles.
- **Swagger API Documentation**: Interactive OpenAPI 3.0 documentation mounted at `/api/docs`.
- **Automated Seed Data**: Out-of-the-box data seeding script for Ashoka Textiles and Bright Path Consulting pilot scenarios.

---

## Architecture

The system follows a clean, decoupled architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Client App                       │
│  (Single Universal Login, Employee Portal, Manager, HR)     │
└──────────────────────────────┬──────────────────────────────┘
                               │  HTTPS (REST API / JSON + JWT)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   Express.js Backend API                    │
│   ├── Security Middlewares (Helmet, CORS, Rate Limiter)     │
│   ├── JWT Auth & Tenant Scoping Guard (req.tenantId)        │
│   ├── Layered Controllers & Domain Services                 │
│   └── Parameterized SQL Repositories                        │
└──────────────────────────────┬──────────────────────────────┘
                               │  PostgreSQL Connection Pool (pg)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Supabase PostgreSQL Database                │
│   ├── 6 Normalized 3NF Relational Entities                  │
│   └── Composite Tenant & Analytics Database Indexes         │
└──────────────────────────────┬──────────────────────────────┘
```

---

## Project Structure

```
performance-evaluation-system/
├── backend/
│   ├── server.js               # Express HTTP server entry point
│   ├── package.json            # Node.js dependencies & scripts
│   ├── .env.example            # Environment variables template
│   └── src/
│       ├── app.js              # Express application configuration & routes
│       ├── config/             # DB connection pool & Swagger OpenAPI spec
│       ├── constants/          # Role definitions & 5 parameter codes
│       ├── controllers/        # Thin HTTP request controllers
│       ├── middleware/         # Auth, Tenant, Role & Error middlewares
│       ├── repositories/       # Parameterized SQL database queries
│       ├── routes/             # API route declarations
│       ├── seed/               # Database schema SQL & seed script
│       ├── services/           # Domain business logic
│       ├── utils/              # Custom AppError & response formatters
│       └── validators/         # express-validator payload schemas
│
├── frontend/
│   ├── pubspec.yaml            # Flutter dependencies & assets config
│   └── lib/
│       ├── main.dart           # Flutter application entry point
│       ├── core/
        │   ├── config/         # App constants & Material 3 theme
        │   ├── models/         # User DTO entity
        │   ├── providers/      # Auth, Employee, Manager, HR state providers
        │   ├── routes/         # GoRouter route declarations
        │   ├── services/       # ApiClient (Dio) & StorageService
        │   └── widgets/        # Shared AppBar, Drawer, Loading & Error widgets
        └── screens/            # Application view screens
│
└── docs/                       # Architectural diagrams & design documentation
```

---

## Database Design

The database schema is structured into **6 normalized relational entities (3NF)**:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. COMPANIES             - Multi-Tenant Isolation Root      │
│ 2. USERS                 - Accounts & Reporting Hierarchy    │
│ 3. EVALUATION_CYCLES     - Monthly Time Boundaries          │
│ 4. EVALUATION_PARAMETERS - Master 5 Fixed Metric Definitions│
│ 5. EVALUATIONS           - Monthly Feedback Header Record   │
│ 6. EVALUATION_SCORES     - Parameter Score & Written Comment│
└─────────────────────────────────────────────────────────────┘
```

### Hierarchy Modeling
The `users` table utilizes an **adjacency-list self-referencing relationship (`manager_id`)** to dynamically support any organizational structure without schema modifications:

1. **Ashoka Textiles Scenario** (Multi-Tier Chain):
   - COO: `manager_id = NULL`
   - Rohan (VP): `manager_id = COO.id`
   - Priya (Manager): `manager_id = Rohan.id`
   - 6 Employees: `manager_id = Priya.id`
2. **Bright Path Consulting Scenario** (Flat Structure):
   - Founder: `manager_id = NULL`
   - 8 Employees: `manager_id = Founder.id`

---

## Authentication

- **Single Login Page**: Users authenticate using only `email` and `password`. The backend queries the database, verifies the password hash via `bcrypt`, and automatically resolves the user's `company_id`.
- **JWT Authorization**: Upon login, the server issues a signed JWT containing `id`, `companyId`, `role`, and `email`. The client stores the token in `SharedPreferences` and automatically attaches `Authorization: Bearer <token>` to every request via Dio interceptors.
- **Multi-Tenant Isolation**: Express middleware extracts `req.tenantId = decoded.companyId`. Every database repository query appends `WHERE company_id = req.tenantId` to ensure complete logical data separation.
- **Role-Based Access Control**:
  - `EMPLOYEE`: Accesses personal dashboard, feedback history, and score trends.
  - `MANAGER`: Evaluates assigned direct reports, saves drafts, and submits reviews.
  - `HR`: Read-only access to company compliance metrics and manager progress.

---

## Setup

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install Node.js dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file based on `.env.example`:
   ```bash
   cp .env.example .env
   ```
4. Run the database schema initialization and seed script:
   ```bash
   npm run seed
   ```
5. Start the API server in development mode:
   ```bash
   npm run dev
   ```

### Frontend Setup
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Install Flutter packages:
   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```
3. Launch the application:
   ```bash
   flutter run -d chrome  # Web Target
   # or
   flutter run            # Mobile / Desktop Target
   ```

---

## Environment Variables

The backend relies on the following environment variables (documented in `backend/.env.example`):

| Variable | Description | Default / Example Value |
| :--- | :--- | :--- |
| `PORT` | HTTP Server Listening Port | `5000` |
| `NODE_ENV` | Environment Runtime Mode | `development` |
| `DATABASE_URL` | Supabase / PostgreSQL Connection String | `postgresql://postgres:pass@host:6543/postgres` |
| `JWT_SECRET` | Secret key for signing JWT tokens | `super_secret_jwt_key_32chars` |
| `JWT_EXPIRES_IN` | Token validity duration | `24h` |
| `CORS_ORIGIN` | Allowed Cross-Origin Origins | `*` |

---

## API Documentation

Interactive OpenAPI 3.0 documentation is served directly by the Express backend using Swagger UI:

- **Swagger UI Endpoint**: [http://localhost:5000/api/docs](http://localhost:5000/api/docs)
- **Raw OpenAPI Specification**: [http://localhost:5000/api/docs/json](http://localhost:5000/api/docs/json)
- **Health Check Endpoint**: [http://localhost:5000/api/health](http://localhost:5000/api/health)

---

## Seed Data

Running `npm run seed` initializes database tables, master parameters, review cycles, and provisions two pre-seeded pilot companies:

Default password for **ALL** pre-seeded accounts: **`Password123!`**

### Ashoka Textiles (`ashoka-textiles`)
- **HR Admin**: `hr@ashoka.com`
- **COO**: `coo@ashoka.com`
- **VP Operations**: `rohan@ashoka.com` (Reports to COO)
- **Plant Manager**: `priya@ashoka.com` (Reports to Rohan, manages 6 employees)
- **Employees**: `aarav@ashoka.com`, `ananya@ashoka.com`, `dev@ashoka.com`, `ishaan@ashoka.com`, `kavya@ashoka.com`, `meera@ashoka.com`

### Bright Path Consulting (`bright-path`)
- **HR Admin**: `hr@brightpath.com`
- **Founder**: `founder@brightpath.com` (Manages 8 employees directly)
- **Employees**: `aditi@brightpath.com`, `arjun@brightpath.com`, `bhavya@brightpath.com`, `deepa@brightpath.com`, `harsh@brightpath.com`, `niharika@brightpath.com`, `rahul@brightpath.com`, `sneha@brightpath.com`

---

## Assumptions

1. **Single Company Context**: Every employee belongs to exactly one company tenant.
2. **Single Direct Manager**: Every employee has exactly one immediate direct manager (`manager_id`), except top-level executive leaders who have no manager (`manager_id = NULL`).
3. **One Monthly Evaluation**: Direct managers submit exactly one finalized evaluation per direct report per monthly cycle (`YYYY-MM`).
4. **Fixed 5 Parameters**: All tenant companies utilize the 5 standardized performance parameters for this assignment scope.
5. **HR Read-Only Oversight**: HR personnel have read-only access to company-wide compliance metrics and manager submission completion statuses.

---

## Future Improvements

- **Configurable Parameters per Tenant**: Enable custom evaluation parameter templates per company.
- **Quarterly & Annual Reviews**: Support non-monthly review cadences.
- **360-Degree Feedback**: Support Peer and Self-evaluations alongside Manager reviews.
- **Automated Email Reminders**: Cron background worker triggering email reminders to managers with pending reviews.
- **Push Notifications**: Real-time push alerts when new evaluation feedback is published.

---

## Screenshots

| Login Screen | Employee Portal | Manager Portal |
| :---: | :---: | :---: |
| *(Single Login View)* | *(Score Trends & History)* | *(5-Parameter Review Form)* |

| HR Compliance Dashboard | Manager Progress List | Read-Only Feedback Sheet |
| :---: | :---: | :---: |
| *(Completion Donut Chart)* | *(Linear Progress Bars)* | *(5-Parameter Ratings)* |

---

## License

This project was developed as an educational technical take-home assignment. Distributed under the MIT License.
