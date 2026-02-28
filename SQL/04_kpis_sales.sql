-- =========================
-- SALES / CLIENT KPI QUERIES
-- staffing analytics
-- =========================


-- =====================================
-- 1) JOBS OPENED BY CLIENT (VOLUME)
-- =====================================
SELECT
  client_name,
  COUNT(*) AS jobs_opened
FROM jobs
GROUP BY client_name
ORDER BY jobs_opened DESC;



-- =====================================
-- 2) OPEN JOBS BY CLIENT (CURRENT PIPELINE)
-- =====================================
SELECT
  client_name,
  COUNT(*) AS open_jobs
FROM jobs
WHERE status = 'open'
GROUP BY client_name
ORDER BY open_jobs DESC;



-- =====================================
-- 3) FILL COUNT BY CLIENT (PLACEMENTS)
-- =====================================
SELECT
  j.client_name,
  COUNT(DISTINCT p.placement_id) AS placements
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id
GROUP BY j.client_name
ORDER BY placements DESC;



-- =====================================
-- 4) FILL RATE BY CLIENT
-- fill_rate = placements / jobs_opened
-- =====================================
WITH jobs_by_client AS (
  SELECT client_name, COUNT(*) AS jobs_opened
  FROM jobs
  GROUP BY client_name
),
placements_by_client AS (
  SELECT j.client_name, COUNT(DISTINCT p.placement_id) AS placements
  FROM placements p
  JOIN applications a ON a.application_id = p.application_id
  JOIN jobs j ON j.job_id = a.job_id
  GROUP BY j.client_name
)
SELECT
  j.client_name,
  j.jobs_opened,
  COALESCE(p.placements, 0) AS placements,
  ROUND((COALESCE(p.placements, 0)::numeric / NULLIF(j.jobs_opened, 0))::numeric, 4) AS fill_rate
FROM jobs_by_client j
LEFT JOIN placements_by_client p ON p.client_name = j.client_name
ORDER BY fill_rate DESC, placements DESC;



-- =====================================
-- 5) REVENUE-LIKE METRIC (ACTIVE PLACEMENTS)
-- proxy: bill_rate per hour * active placements
-- (Not true revenue without hours worked, but useful as a signal)
-- =====================================
SELECT
  j.client_name,
  COUNT(*) FILTER (WHERE p.status = 'active') AS active_placements,
  ROUND(SUM(p.bill_rate) FILTER (WHERE p.status = 'active')::numeric, 2) AS sum_bill_rates_active,
  ROUND(AVG(p.bill_rate) FILTER (WHERE p.status = 'active')::numeric, 2) AS avg_bill_rate_active
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id
GROUP BY j.client_name
ORDER BY sum_bill_rates_active DESC;



-- =====================================
-- 6) AVERAGE BILL RATE BY CLIENT (ALL PLACEMENTS)
-- =====================================
SELECT
  j.client_name,
  COUNT(*) AS placements,
  ROUND(AVG(p.bill_rate)::numeric, 2) AS avg_bill_rate,
  ROUND(AVG(p.pay_rate)::numeric, 2) AS avg_pay_rate,
  ROUND(AVG(p.bill_rate - p.pay_rate)::numeric, 2) AS avg_margin
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id
GROUP BY j.client_name
HAVING COUNT(*) >= 3
ORDER BY avg_margin DESC, avg_bill_rate DESC;



-- =====================================
-- 7) MARGIN % BY CLIENT
-- avg_margin_pct = avg((bill - pay) / bill)
-- =====================================
SELECT
  j.client_name,
  COUNT(*) AS placements,
  ROUND(AVG((p.bill_rate - p.pay_rate) / NULLIF(p.bill_rate,0))::numeric, 4) AS avg_margin_pct
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id
GROUP BY j.client_name
HAVING COUNT(*) >= 3
ORDER BY avg_margin_pct DESC;



-- =====================================
-- 8) CLIENTS WITH "STUCK" JOBS
-- Open jobs older than 30 days with no placements
-- =====================================
WITH open_old AS (
  SELECT
    j.job_id,
    j.client_name,
    j.job_title,
    j.created_at::date AS created_date
  FROM jobs j
  WHERE j.status = 'open'
    AND j.created_at < now() - INTERVAL '30 days'
),
job_has_placement AS (
  SELECT
    j.job_id,
    COUNT(p.placement_id) AS placements
  FROM jobs j
  LEFT JOIN applications a ON a.job_id = j.job_id
  LEFT JOIN placements p ON p.application_id = a.application_id
  GROUP BY j.job_id
)
SELECT
  o.client_name,
  COUNT(*) AS open_jobs_30d_plus,
  COUNT(*) FILTER (WHERE COALESCE(jhp.placements,0) = 0) AS open_jobs_30d_plus_no_placement
FROM open_old o
JOIN job_has_placement jhp ON jhp.job_id = o.job_id
GROUP BY o.client_name
ORDER BY open_jobs_30d_plus_no_placement DESC, open_jobs_30d_plus DESC;



-- =====================================
-- 9) TIME TO FILL BY CLIENT (AVG + MEDIAN)
-- =====================================
WITH ttf AS (
  SELECT
    j.client_name,
    (p.start_date - j.created_at::date) AS days_to_fill
  FROM placements p
  JOIN applications a ON a.application_id = p.application_id
  JOIN jobs j ON j.job_id = a.job_id
)
SELECT
  client_name,
  COUNT(*) AS placements,
  ROUND(AVG(days_to_fill)::numeric, 2) AS avg_days_to_fill,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_to_fill) AS median_days_to_fill
FROM ttf
GROUP BY client_name
HAVING COUNT(*) >= 3
ORDER BY avg_days_to_fill ASC;



-- =====================================
-- 10) JOB TYPE MIX BY CLIENT
-- =====================================
SELECT
  client_name,
  job_type,
  COUNT(*) AS jobs
FROM jobs
GROUP BY client_name, job_type
ORDER BY client_name, jobs DESC;



-- =====================================
-- 11) BILL RATE BY JOB TITLE (MARKET SIGNAL)
-- (Only contract/CTH jobs where bill_rate exists)
-- =====================================
SELECT
  job_title,
  COUNT(*) AS jobs,
  ROUND(AVG(bill_rate)::numeric, 2) AS avg_bill_rate,
  ROUND(MIN(bill_rate)::numeric, 2) AS min_bill_rate,
  ROUND(MAX(bill_rate)::numeric, 2) AS max_bill_rate
FROM jobs
WHERE bill_rate IS NOT NULL
GROUP BY job_title
HAVING COUNT(*) >= 3
ORDER BY avg_bill_rate DESC;
