-- staffing-ops-kpis-postgres : 00_schema.sql
-- Safe to re-run:
--   Drops tables in dependency order, then recreates.

BEGIN;

-- Drop in dependency order
DROP TABLE IF EXISTS placements;
DROP TABLE IF EXISTS offers;
DROP TABLE IF EXISTS interviews;
DROP TABLE IF EXISTS applications;
DROP TABLE IF EXISTS jobs;
DROP TABLE IF EXISTS candidates;

-- =========================
-- Candidates
-- =========================
CREATE TABLE candidates (
  candidate_id      BIGSERIAL PRIMARY KEY,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  source            TEXT NOT NULL,            -- referral, linkedin, inbound, etc.
  primary_skill     TEXT NOT NULL,            -- helpdesk, sysadmin, data, web, etc.
  location_city     TEXT,
  location_state    TEXT,
  years_experience  NUMERIC(4,1) NOT NULL DEFAULT 0 CHECK (years_experience >= 0)
);

-- =========================
-- Jobs
-- =========================
CREATE TABLE jobs (
  job_id            BIGSERIAL PRIMARY KEY,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  client_name       TEXT NOT NULL,
  job_title         TEXT NOT NULL,
  job_type          TEXT NOT NULL,            -- contract, contract_to_hire, perm
  location_city     TEXT,
  location_state    TEXT,
  target_start_date DATE,
  status            TEXT NOT NULL DEFAULT 'open',  -- open, on_hold, filled, canceled
  bill_rate         NUMERIC(10,2) CHECK (bill_rate IS NULL OR bill_rate >= 0)
);

-- =========================
-- Applications (candidate ↔ job)
-- =========================
CREATE TABLE applications (
  application_id     BIGSERIAL PRIMARY KEY,
  candidate_id       BIGINT NOT NULL REFERENCES candidates(candidate_id) ON DELETE CASCADE,
  job_id             BIGINT NOT NULL REFERENCES jobs(job_id) ON DELETE CASCADE,
  applied_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  stage              TEXT NOT NULL DEFAULT 'applied',
  rejected_at        TIMESTAMPTZ,
  rejection_reason   TEXT,
  CONSTRAINT uq_app_candidate_job UNIQUE (candidate_id, job_id),
  CONSTRAINT chk_rejected_fields_consistent CHECK (
    (rejected_at IS NULL AND rejection_reason IS NULL)
    OR
    (rejected_at IS NOT NULL)
  )
);

-- =========================
-- Interviews
-- =========================
CREATE TABLE interviews (
  interview_id     BIGSERIAL PRIMARY KEY,
  application_id   BIGINT NOT NULL REFERENCES applications(application_id) ON DELETE CASCADE,
  scheduled_at     TIMESTAMPTZ NOT NULL,
  interview_type   TEXT NOT NULL,        -- phone, video, onsite
  result           TEXT NOT NULL DEFAULT 'pending'  -- pass, fail, no_show, pending
);

-- =========================
-- Offers
-- =========================
CREATE TABLE offers (
  offer_id        BIGSERIAL PRIMARY KEY,
  application_id  BIGINT NOT NULL REFERENCES applications(application_id) ON DELETE CASCADE,
  offered_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  offer_rate      NUMERIC(10,2) CHECK (offer_rate IS NULL OR offer_rate >= 0),
  result          TEXT NOT NULL DEFAULT 'pending'   -- accepted, declined, rescinded, pending
);

-- =========================
-- Placements
-- =========================
CREATE TABLE placements (
  placement_id    BIGSERIAL PRIMARY KEY,
  application_id  BIGINT NOT NULL REFERENCES applications(application_id) ON DELETE CASCADE,
  start_date      DATE NOT NULL,
  end_date        DATE,
  pay_rate        NUMERIC(10,2) NOT NULL CHECK (pay_rate >= 0),
  bill_rate       NUMERIC(10,2) NOT NULL CHECK (bill_rate >= 0),
  status          TEXT NOT NULL DEFAULT 'active',  -- active, ended, terminated
  CONSTRAINT chk_end_after_start CHECK (end_date IS NULL OR end_date >= start_date),
  CONSTRAINT chk_bill_ge_pay CHECK (bill_rate >= pay_rate)
);

-- =========================
-- Helpful indexes for KPI queries
-- =========================
CREATE INDEX idx_candidates_created_at     ON candidates(created_at);
CREATE INDEX idx_jobs_created_at           ON jobs(created_at);
CREATE INDEX idx_jobs_status               ON jobs(status);
CREATE INDEX idx_apps_job_id               ON applications(job_id);
CREATE INDEX idx_apps_candidate_id         ON applications(candidate_id);
CREATE INDEX idx_apps_applied_at           ON applications(applied_at);
CREATE INDEX idx_interviews_application_id ON interviews(application_id);
CREATE INDEX idx_interviews_scheduled_at   ON interviews(scheduled_at);
CREATE INDEX idx_offers_application_id     ON offers(application_id);
CREATE INDEX idx_offers_offered_at         ON offers(offered_at);
CREATE INDEX idx_placements_application_id ON placements(application_id);
CREATE INDEX idx_placements_start_date     ON placements(start_date);
CREATE INDEX idx_placements_status         ON placements(status);

COMMIT;
