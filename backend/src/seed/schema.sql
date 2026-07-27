-- PostgreSQL Schema for Performance Evaluation Tool
-- Multi-Tenant Architecture with Row-Level Isolation

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. COMPANIES
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. USERS
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL CHECK (role IN ('HR', 'MANAGER', 'EMPLOYEE')),
  manager_id UUID REFERENCES users(id) ON DELETE SET NULL,
  job_title VARCHAR(150),
  department VARCHAR(150),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_company_email UNIQUE (company_id, email),
  CONSTRAINT chk_no_self_manager CHECK (id <> manager_id)
);

-- 3. EVALUATION CYCLES
CREATE TABLE IF NOT EXISTS evaluation_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  cycle_code VARCHAR(20) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_company_cycle UNIQUE (company_id, cycle_code)
);

-- 4. EVALUATION PARAMETERS
CREATE TABLE IF NOT EXISTS evaluation_parameters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  display_order INTEGER NOT NULL UNIQUE CHECK (display_order BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. EVALUATIONS
CREATE TABLE IF NOT EXISTS evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES evaluation_cycles(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  manager_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SUBMITTED')),
  summary_comment TEXT,
  submitted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_company_cycle_employee UNIQUE (company_id, cycle_id, employee_id),
  CONSTRAINT chk_no_self_review CHECK (employee_id <> manager_id)
);

-- 6. EVALUATION SCORES
CREATE TABLE IF NOT EXISTS evaluation_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluation_id UUID NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE,
  parameter_id UUID NOT NULL REFERENCES evaluation_parameters(id) ON DELETE RESTRICT,
  score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  comment TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_eval_parameter UNIQUE (evaluation_id, parameter_id)
);

-- 7. PROJECT TEAMS
CREATE TABLE IF NOT EXISTS project_teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50),
  description TEXT,
  lead_manager_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 8. PROJECT TEAM MEMBERS
CREATE TABLE IF NOT EXISTS project_team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES project_teams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_team_user UNIQUE (team_id, user_id)
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_users_tenant_manager ON users(company_id, manager_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_hr_tracker ON evaluations(company_id, cycle_id, status, manager_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_employee_history ON evaluations(company_id, employee_id, cycle_id);
CREATE INDEX IF NOT EXISTS idx_scores_agg_trends ON evaluation_scores(evaluation_id, parameter_id, score);
CREATE INDEX IF NOT EXISTS idx_project_teams_tenant ON project_teams(company_id);
