-- =========================
-- DATA QUALITY CHECKS
-- staffing analytics
-- =========================
-- Purpose:
--   Identify inconsistent records, orphaned funnel steps,
--   and operational “impossible states”.
--
-- Tip:
--   In a real system, these would become scheduled tests (dbt, alerts, etc).


-- =====================================
-- 1) PLACEMENTS WHERE pay_rate > bill_rate (should be impossible)
-- =====================================
SELECT
  p.placement_id,
  p.application_id,
  p.pay_rate,
  p.bill_rate,
  (p.pay_rate - p.bill_rate) AS negative_margin
FROM placements p
WHERE p.pay_rate > p.bill_rate
ORDER BY negative_margin DESC;



-- =====================================
-- 2) ACTIVE PLACEMENTS WITH end_date SET (should be NULL)
-- =====================================
SELECT
  placement_id,
  application_id,
  status,
  start_date,
  end_date
FROM placements
WHERE status = 'active'
  AND end_date IS NOT NULL
ORDER BY end_date DESC;



-- =====================================
-- 3) ENDED/TERMINATED PLACEMENTS WITH NO end_date (should not be NULL)
-- =====================================
SELECT
  placement_id,
  application_id,
  status,
  start_date,
  end_date
FROM placements
WHERE status IN ('ended','terminated')
  AND end_date IS NULL;



-- =====================================
-- 4) PLACEMENTS WITH end_date BEFORE start_date
-- =====================================
SELECT
  placement_id,
  application_id,
  start_date,
  end_date
FROM placements
WHERE end_date IS NOT NULL
  AND end_date < start_date;



-- =====================================
-- 5) JOBS MARKED FILLED BUT NO PLACEMENTS ATTACHED
-- (Operational issue: status says filled, but delivery not recorded)
-- =====================================
SELECT
  j.job_id,
  j.client_name,
  j.job_title,
  j.status,
  j.created_at
FROM jobs j
LEFT JOIN applications a ON a.job_id = j.job_id
LEFT JOIN placements p ON p.application_id = a.application_id
WHERE j.status = 'filled'
GROUP BY j.job_id
HAVING COUNT(p.placement_id) = 0
ORDER BY j.created_at DESC;



-- =====================================
-- 6) APPLICATIONS IN 'placed' STAGE BUT NO PLACEMENT RECORD
-- =====================================
SELECT
  a.application_id,
  a.candidate_id,
  a.job_id,
  a.stage,
  a.applied_at
FROM applications a
LEFT JOIN placements p ON p.application_id = a.application_id
WHERE a.stage = 'placed'
  AND p.placement_id IS NULL
ORDER BY a.applied_at DESC;



-- =====================================
-- 7) OFFERS ACCEPTED BUT NO PLACEMENT
-- (Common real-world gap: accepted offer never started)
-- =====================================
SELECT
  o.offer_id,
  o.application_id,
  o.offered_at,
  o.offer_rate
FROM offers o
LEFT JOIN placements p ON p.application_id = o.application_id
WHERE o.result = 'accepted'
  AND p.placement_id IS NULL
ORDER BY o.offered_at DESC;



-- =====================================
-- 8) OFFERS WITHOUT A PASSED INTERVIEW
-- (Not always wrong, but suspicious depending on policy)
-- =====================================
WITH passed AS (
  SELECT
    application_id,
    BOOL_OR(result = 'pass') AS has_pass
  FROM interviews
  GROUP BY application_id
)
SELECT
  o.offer_id,
  o.application_id,
  o.result,
  o.offered_at
FROM offers o
LEFT JOIN passed p ON p.application_id = o.application_id
WHERE o.result IN ('accepted','pending')
  AND COALESCE(p.has_pass, FALSE) = FALSE
ORDER BY o.offered_at DESC;



-- =====================================
-- 9) INTERVIEWS SCHEDULED BUT STILL 'pending' AFTER 7 DAYS
-- (Possible missing result update)
-- =====================================
SELECT
  interview_id,
  application_id,
  scheduled_at,
  result
FROM interviews
WHERE result = 'pending'
  AND scheduled_at < (now() - INTERVAL '7 days')
ORDER BY scheduled_at ASC;



-- =====================================
-- 10) DUPLICATE OFFERS PER APPLICATION (could indicate re-offers)
-- =====================================
SELECT
  application_id,
  COUNT(*) AS offer_count
FROM offers
GROUP BY application_id
HAVING COUNT(*) > 1
ORDER BY offer_count DESC;



-- =====================================
-- 11) APPLICATIONS WITH rejected_at SET BUT STAGE NOT rejected/withdrawn
-- =====================================
SELECT
  application_id,
  stage,
  applied_at,
  rejected_at,
  rejection_reason
FROM applications
WHERE rejected_at IS NOT NULL
  AND stage NOT IN ('rejected','withdrawn')
ORDER BY rejected_at DESC;



-- =====================================
-- 12) APPLICATIONS WITH STAGE 'rejected/withdrawn' BUT rejected_at NULL
-- =====================================
SELECT
  application_id,
  stage,
  applied_at,
  rejected_at,
  rejection_reason
FROM applications
WHERE stage IN ('rejected','withdrawn')
  AND rejected_at IS NULL
ORDER BY applied_at DESC;



-- =====================================
-- 13) JOBS WITH target_start_date BEFORE created_at (weird)
-- =====================================
SELECT
  job_id,
  client_name,
  job_title,
  created_at,
  target_start_date
FROM jobs
WHERE target_start_date IS NOT NULL
  AND target_start_date < created_at::date
ORDER BY created_at DESC;



-- =====================================
-- 14) BILL RATE MISSING ON NON-PERM JOBS
-- =====================================
SELECT
  job_id,
  client_name,
  job_title,
  job_type,
  bill_rate
FROM jobs
WHERE job_type <> 'perm'
  AND bill_rate IS NULL;



-- =====================================
-- 15) ORPHAN CHECKS (should be zero due to FKs)
-- (Still useful to demonstrate awareness)
-- =====================================

-- Applications without candidate
SELECT COUNT(*) AS orphan_app_candidates
FROM applications a
LEFT JOIN candidates c ON c.candidate_id = a.candidate_id
WHERE c.candidate_id IS NULL;

-- Applications without job
SELECT COUNT(*) AS orphan_app_jobs
FROM applications a
LEFT JOIN jobs j ON j.job_id = a.job_id
WHERE j.job_id IS NULL;
