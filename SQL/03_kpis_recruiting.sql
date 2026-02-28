-- =========================
-- RECRUITING KPI QUERIES
-- staffing analytics
-- =========================


-- =====================================
-- 1) CANDIDATES BY SOURCE
-- =====================================
SELECT
  source,
  COUNT(*) AS candidates
FROM candidates
GROUP BY source
ORDER BY candidates DESC;



-- =====================================
-- 2) CANDIDATE SOURCE → PLACEMENT CONVERSION
-- (How effective each source is at producing placements)
-- =====================================
WITH src_counts AS (
  SELECT
    c.source,
    COUNT(DISTINCT c.candidate_id) AS candidates_total,
    COUNT(DISTINCT p.placement_id) AS placements
  FROM candidates c
  LEFT JOIN applications a ON a.candidate_id = c.candidate_id
  LEFT JOIN offers o ON o.application_id = a.application_id AND o.result = 'accepted'
  LEFT JOIN placements p ON p.application_id = a.application_id
  GROUP BY c.source
)
SELECT
  source,
  candidates_total,
  placements,
  ROUND((placements::numeric / NULLIF(candidates_total, 0))::numeric, 4) AS placement_rate_per_candidate
FROM src_counts
ORDER BY placement_rate_per_candidate DESC, placements DESC;



-- =====================================
-- 3) SOURCE PERFORMANCE BY SKILL
-- (Source → placements, grouped by primary_skill)
-- =====================================
WITH x AS (
  SELECT
    c.source,
    c.primary_skill,
    COUNT(DISTINCT c.candidate_id) AS candidates,
    COUNT(DISTINCT p.placement_id) AS placements
  FROM candidates c
  LEFT JOIN applications a ON a.candidate_id = c.candidate_id
  LEFT JOIN placements p ON p.application_id = a.application_id
  GROUP BY c.source, c.primary_skill
)
SELECT
  source,
  primary_skill,
  candidates,
  placements,
  ROUND((placements::numeric / NULLIF(candidates, 0))::numeric, 4) AS placement_rate
FROM x
WHERE candidates >= 5
ORDER BY placement_rate DESC, placements DESC;



-- =====================================
-- 4) INTERVIEW RESULTS OVERVIEW
-- =====================================
SELECT
  result,
  COUNT(*) AS interviews
FROM interviews
GROUP BY result
ORDER BY interviews DESC;



-- =====================================
-- 5) INTERVIEW NO-SHOW RATE
-- =====================================
SELECT
  ROUND(
    (COUNT(*) FILTER (WHERE result = 'no_show')::numeric / NULLIF(COUNT(*), 0))::numeric,
    4
  ) AS no_show_rate
FROM interviews;



-- =====================================
-- 6) INTERVIEW PASS RATE (of completed interviews)
-- =====================================
SELECT
  ROUND(
    (COUNT(*) FILTER (WHERE result = 'pass')::numeric /
      NULLIF(COUNT(*) FILTER (WHERE result IN ('pass','fail','no_show')), 0)
    )::numeric,
    4
  ) AS pass_rate_completed
FROM interviews;



-- =====================================
-- 7) OFFER ACCEPTANCE RATE BY SKILL
-- =====================================
WITH offer_skill AS (
  SELECT
    c.primary_skill,
    o.result
  FROM offers o
  JOIN applications a ON a.application_id = o.application_id
  JOIN candidates c ON c.candidate_id = a.candidate_id
)
SELECT
  primary_skill,
  COUNT(*) AS offers,
  COUNT(*) FILTER (WHERE result = 'accepted') AS accepted,
  ROUND((COUNT(*) FILTER (WHERE result = 'accepted')::numeric / NULLIF(COUNT(*),0))::numeric, 4) AS acceptance_rate
FROM offer_skill
GROUP BY primary_skill
HAVING COUNT(*) >= 5
ORDER BY acceptance_rate DESC, offers DESC;



-- =====================================
-- 8) REJECTION REASONS (TOP)
-- =====================================
SELECT
  rejection_reason,
  COUNT(*) AS occurrences
FROM applications
WHERE rejected_at IS NOT NULL
GROUP BY rejection_reason
ORDER BY occurrences DESC;



-- =====================================
-- 9) TIME FROM APPLICATION → FIRST INTERVIEW (DAYS)
-- =====================================
WITH first_int AS (
  SELECT
    a.application_id,
    a.applied_at::date AS applied_date,
    MIN(i.scheduled_at::date) AS first_interview_date
  FROM applications a
  JOIN interviews i ON i.application_id = a.application_id
  GROUP BY a.application_id, a.applied_at
)
SELECT
  AVG(first_interview_date - applied_date) AS avg_days_to_first_interview,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (first_interview_date - applied_date)) AS median_days_to_first_interview
FROM first_int;



-- =====================================
-- 10) TIME FROM APPLICATION → OFFER (DAYS)
-- =====================================
WITH first_offer AS (
  SELECT
    a.application_id,
    a.applied_at::date AS applied_date,
    MIN(o.offered_at::date) AS first_offer_date
  FROM applications a
  JOIN offers o ON o.application_id = a.application_id
  GROUP BY a.application_id, a.applied_at
)
SELECT
  AVG(first_offer_date - applied_date) AS avg_days_to_offer,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (first_offer_date - applied_date)) AS median_days_to_offer
FROM first_offer;



-- =====================================
-- 11) DROP-OFF POINTS (COUNT OF APPS BY LATEST STAGE)
-- (Helps show where candidates are falling out of the funnel)
-- =====================================
SELECT
  stage,
  COUNT(*) AS applications
FROM applications
GROUP BY stage
ORDER BY applications DESC;



-- =====================================
-- 12) CANDIDATES IN PIPELINE (ACTIVE STAGES)
-- =====================================
SELECT
  a.stage,
  COUNT(DISTINCT a.candidate_id) AS candidates
FROM applications a
WHERE a.stage IN ('applied','screened','submitted','interviewing','offered')
GROUP BY a.stage
ORDER BY candidates DESC;
