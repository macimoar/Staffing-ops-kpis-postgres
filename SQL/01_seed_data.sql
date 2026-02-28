-- staffing-ops-kpis-postgres : 01_seed_data.sql
-- Generates realistic synthetic staffing pipeline data.
-- Safe to re-run: it truncates tables and reloads.

BEGIN;

-- Clear existing data (respecting FK order)
TRUNCATE TABLE
  placements,
  offers,
  interviews,
  applications,
  jobs,
  candidates
RESTART IDENTITY CASCADE;

-- Make random() reproducible-ish for this session
SELECT setseed(0.4242);

-- =========================
-- Candidates (200) - FIXED
-- =========================
WITH r AS (
  SELECT
    (now() - (random()*INTERVAL '540 days')) AS created_at,
    random() AS rs,   -- source roll
    random() AS rk,   -- skill roll
    random() AS rl,   -- location roll
    LEAST(18.0, GREATEST(0.0, ROUND((random()*10.0)::numeric, 1))) AS years_experience
  FROM generate_series(1, 200)
)
INSERT INTO candidates (created_at, source, primary_skill, location_city, location_state, years_experience)
SELECT
  created_at,
  CASE
    WHEN rs < 0.10 THEN 'referral'
    WHEN rs < 0.45 THEN 'linkedin'
    WHEN rs < 0.65 THEN 'inbound'
    WHEN rs < 0.90 THEN 'job_board'
    WHEN rs < 0.95 THEN 'agency'
    ELSE 'campus'
  END AS source,
  CASE
    WHEN rk < 0.18 THEN 'helpdesk'
    WHEN rk < 0.34 THEN 'sysadmin'
    WHEN rk < 0.46 THEN 'network'
    WHEN rk < 0.60 THEN 'data'
    WHEN rk < 0.72 THEN 'web'
    WHEN rk < 0.82 THEN 'security'
    WHEN rk < 0.92 THEN 'devops'
    ELSE 'qa'
  END AS primary_skill,
  CASE
    WHEN rl < 0.35 THEN 'St. Louis'
    WHEN rl < 0.45 THEN 'St. Charles'
    WHEN rl < 0.55 THEN 'Chesterfield'
    WHEN rl < 0.63 THEN 'Springfield'
    WHEN rl < 0.75 THEN 'Kansas City'
    WHEN rl < 0.83 THEN 'Columbia'
    WHEN rl < 0.93 THEN 'Edwardsville'
    ELSE 'Belleville'
  END AS location_city,
  CASE
    WHEN rl < 0.83 THEN 'MO'  -- first 6 are MO through Columbia
    WHEN rl < 0.93 THEN 'IL'  -- Edwardsville
    ELSE 'IL'                -- Belleville
  END AS location_state,
  years_experience
FROM r;

-- =========================
-- Jobs (60)
-- =========================
WITH jt AS (
  SELECT ARRAY['contract','contract_to_hire','perm'] AS job_types,
         ARRAY[0.55,0.25,0.20] AS jw,
         ARRAY[
           'Gateway Health','Midwest Manufacturing','RiverCity Bank','Archway Logistics',
           'Show-Me Retail','Prairie Insurance','Metro Public Services','Cardinal Tech'
         ] AS clients
),
skill_titles AS (
  SELECT * FROM (VALUES
    ('helpdesk', ARRAY['Help Desk Technician','IT Support Specialist','Desktop Support Technician'], 55),
    ('sysadmin', ARRAY['Systems Administrator','Windows Administrator','Junior SysAdmin'], 80),
    ('network',  ARRAY['Network Technician','Network Administrator','NOC Analyst'], 75),
    ('data',     ARRAY['Data Analyst','SQL Analyst','Reporting Analyst'], 75),
    ('web',      ARRAY['Web Developer','Front-End Developer','Full-Stack Developer'], 85),
    ('security', ARRAY['Security Analyst','SOC Analyst','IAM Analyst'], 90),
    ('devops',   ARRAY['DevOps Engineer','Cloud Engineer','Site Reliability Engineer'], 105),
    ('qa',       ARRAY['QA Analyst','Test Engineer','Automation QA (Junior)'], 65)
  ) AS t(skill, titles, base_bill)
),
locs AS (
  SELECT ARRAY[
    'St. Louis|MO','St. Charles|MO','Chesterfield|MO','Springfield|MO',
    'Kansas City|MO','Columbia|MO','Edwardsville|IL','Belleville|IL'
  ] AS locs
),
j AS (
  SELECT
    now() - (random()*INTERVAL '360 days') AS created_at,
    (SELECT clients[1 + floor(random()*array_length(clients,1))::int] FROM jt) AS client_name,
    st.skill AS skill,
    st.titles[1 + floor(random()*array_length(st.titles,1))::int] AS job_title,
    (SELECT job_types[
      1 + (random() < jw[1])::int*0
        + (random() >= jw[1] AND random() < (jw[1]+jw[2]))::int*1
        + (random() >= (jw[1]+jw[2]))::int*2
    ] FROM jt) AS job_type,
    split_part((SELECT locs[1 + floor(random()*array_length(locs,1))::int] FROM locs), '|', 1) AS location_city,
    split_part((SELECT locs[1 + floor(random()*array_length(locs,1))::int] FROM locs), '|', 2) AS location_state,
    (CURRENT_DATE + (floor(random()*60)::int))::date AS target_start_date,
    (ARRAY['open','on_hold','filled','canceled'])[1 + floor(random()*4)::int] AS status,
    st.base_bill
  FROM generate_series(1, 60)
  JOIN LATERAL (
    SELECT * FROM skill_titles
    ORDER BY random()
    LIMIT 1
  ) st ON true
)
INSERT INTO jobs (created_at, client_name, job_title, job_type, location_city, location_state, target_start_date, status, bill_rate)
SELECT
  created_at,
  client_name,
  job_title,
  job_type,
  location_city,
  location_state,
  target_start_date,
  CASE
    WHEN status = 'filled' AND random() < 0.25 THEN 'open'  -- keep some filled jobs still open (realistic messiness)
    ELSE status
  END,
  CASE
    WHEN job_type = 'perm' THEN NULL
    ELSE ROUND( GREATEST(35, (base_bill + (random()*20 - 10)))::numeric, 2)
  END AS bill_rate
FROM j;

-- =========================
-- Applications (450 distinct candidate-job pairs)
-- =========================
-- Create candidate-job pair candidates, then sample distinct pairs.
CREATE TEMP TABLE tmp_app_pairs AS
SELECT c.candidate_id, j.job_id
FROM candidates c
CROSS JOIN jobs j
ORDER BY random()
LIMIT 450;

-- Insert applications
INSERT INTO applications (candidate_id, job_id, applied_at, stage, rejected_at, rejection_reason)
SELECT
  p.candidate_id,
  p.job_id,
  -- applied_at between job.created_at and job.created_at + 60 days
  (jobs.created_at + (random()*INTERVAL '60 days')) AS applied_at,
  -- stage distribution
  CASE
    WHEN random() < 0.18 THEN 'applied'
    WHEN random() < 0.34 THEN 'screened'
    WHEN random() < 0.48 THEN 'submitted'
    WHEN random() < 0.64 THEN 'interviewing'
    WHEN random() < 0.74 THEN 'offered'
    WHEN random() < 0.82 THEN 'placed'
    WHEN random() < 0.98 THEN 'rejected'
    ELSE 'withdrawn'
  END AS stage,
  NULL::timestamptz AS rejected_at,
  NULL::text AS rejection_reason
FROM tmp_app_pairs p
JOIN jobs ON jobs.job_id = p.job_id;

-- Add rejected metadata consistently
UPDATE applications
SET rejected_at = applied_at + (random()*INTERVAL '20 days'),
    rejection_reason = (ARRAY['not_a_fit','no_response','rate_mismatch','client_declined','failed_screen','withdrew'])
                        [1 + floor(random()*6)::int]
WHERE stage IN ('rejected','withdrawn');

-- =========================
-- Interviews (for some applications)
-- =========================
INSERT INTO interviews (application_id, scheduled_at, interview_type, result)
SELECT
  a.application_id,
  a.applied_at + (INTERVAL '1 day' * (1 + floor(random()*14)::int)) + (random()*INTERVAL '1 day') AS scheduled_at,
  (ARRAY['phone','video','onsite'])[1 + floor(random()*3)::int] AS interview_type,
  CASE
    WHEN random() < 0.45 THEN 'pass'
    WHEN random() < 0.80 THEN 'fail'
    WHEN random() < 0.90 THEN 'no_show'
    ELSE 'pending'
  END AS result
FROM applications a
WHERE a.stage IN ('interviewing','offered','placed')
   OR random() < 0.25;

-- Optional second interview for some that passed the first
INSERT INTO interviews (application_id, scheduled_at, interview_type, result)
SELECT
  i.application_id,
  i.scheduled_at + (INTERVAL '1 day' * (3 + floor(random()*10)::int)) AS scheduled_at,
  (ARRAY['video','onsite'])[1 + floor(random()*2)::int] AS interview_type,
  CASE
    WHEN random() < 0.55 THEN 'pass'
    WHEN random() < 0.90 THEN 'fail'
    ELSE 'pending'
  END AS result
FROM interviews i
WHERE i.result = 'pass'
  AND random() < 0.30;

-- =========================
-- Offers (some apps, more likely if interview pass)
-- =========================
WITH app_pass AS (
  SELECT
    a.application_id,
    bool_or(i.result = 'pass') AS has_pass
  FROM applications a
  LEFT JOIN interviews i ON i.application_id = a.application_id
  GROUP BY a.application_id
)
INSERT INTO offers (application_id, offered_at, offer_rate, result)
SELECT
  a.application_id,
  a.applied_at + (INTERVAL '1 day' * (5 + floor(random()*25)::int)) AS offered_at,
  -- offer_rate based on candidate skill-ish
ROUND(
  (
    CASE c.primary_skill
      WHEN 'helpdesk' THEN 24 + random()*10
      WHEN 'qa'       THEN 26 + random()*12
      WHEN 'network'  THEN 30 + random()*14
      WHEN 'sysadmin' THEN 32 + random()*16
      WHEN 'data'     THEN 30 + random()*18
      WHEN 'web'      THEN 34 + random()*20
      WHEN 'security' THEN 36 + random()*22
      WHEN 'devops'   THEN 42 + random()*26
      ELSE 28 + random()*12
    END
  )::numeric,
  2
) AS offer_rate,
  CASE
    WHEN a.stage = 'placed' THEN 'accepted'
    WHEN random() < 0.55 THEN 'accepted'
    WHEN random() < 0.90 THEN 'declined'
    WHEN random() < 0.95 THEN 'rescinded'
    ELSE 'pending'
  END AS result
FROM applications a
JOIN candidates c ON c.candidate_id = a.candidate_id
JOIN app_pass ap ON ap.application_id = a.application_id
WHERE a.stage IN ('offered','placed')
   OR (ap.has_pass AND random() < 0.35);

-- =========================
-- Placements (subset of accepted offers)
-- =========================
WITH accepted AS (
  SELECT o.application_id, o.offer_rate
  FROM offers o
  WHERE o.result = 'accepted'
),
job_info AS (
  SELECT
    a.application_id,
    a.applied_at::date AS applied_date,
    j.job_type,
    j.bill_rate AS job_bill_rate
  FROM applications a
  JOIN jobs j ON j.job_id = a.job_id
)
INSERT INTO placements (application_id, start_date, end_date, pay_rate, bill_rate, status)
SELECT
  ac.application_id,
  (ji.applied_date + (14 + floor(random()*32)::int))::date AS start_date,
  CASE
    WHEN random() < 0.70 THEN NULL
    ELSE (ji.applied_date + (14 + floor(random()*32)::int) + (7 + floor(random()*160)::int))::date
  END AS end_date,
  ROUND(ac.offer_rate::numeric, 2) AS pay_rate,
ROUND(
  (
    CASE
      WHEN ji.job_type = 'perm' OR ji.job_bill_rate IS NULL
        THEN ac.offer_rate * (1.20 + random()*0.25)
      ELSE
        GREATEST(
          ji.job_bill_rate,
          ac.offer_rate * (1.10 + random()*0.15)
        )
    END
  )::numeric,
  2
) AS bill_rate,
  CASE
    WHEN random() < 0.70 THEN 'active'
    WHEN random() < 0.90 THEN 'ended'
    ELSE 'terminated'
  END AS status
FROM accepted ac
JOIN job_info ji ON ji.application_id = ac.application_id
WHERE random() < 0.65;  -- not every accepted offer becomes a placement

-- Make placement end_date consistent with status
UPDATE placements
SET status = 'active', end_date = NULL
WHERE end_date IS NULL;

UPDATE placements
SET status = CASE WHEN status = 'active' THEN 'ended' ELSE status END
WHERE end_date IS NOT NULL;

DROP TABLE IF EXISTS tmp_app_pairs;

COMMIT;

-- Quick counts
SELECT
  (SELECT count(*) FROM candidates)   AS candidates,
  (SELECT count(*) FROM jobs)         AS jobs,
  (SELECT count(*) FROM applications) AS applications,
  (SELECT count(*) FROM interviews)   AS interviews,
  (SELECT count(*) FROM offers)       AS offers,
  (SELECT count(*) FROM placements)   AS placements;
