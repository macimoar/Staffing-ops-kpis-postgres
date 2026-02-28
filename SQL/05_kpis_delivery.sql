-- =========================
-- DELIVERY KPI QUERIES
-- staffing analytics
-- =========================


-- =====================================
-- 1) PLACEMENTS BY STATUS
-- =====================================
SELECT
  status,
  COUNT(*) AS placements
FROM placements
GROUP BY status
ORDER BY placements DESC;



-- =====================================
-- 2) ACTIVE PLACEMENTS (CURRENT)
-- =====================================
SELECT
  COUNT(*) AS active_placements
FROM placements
WHERE status = 'active';



-- =====================================
-- 3) ACTIVE PLACEMENTS BY CLIENT
-- =====================================
SELECT
  j.client_name,
  COUNT(*) AS active_placements
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id
WHERE p.status = 'active'
GROUP BY j.client_name
ORDER BY active_placements DESC;



-- =====================================
-- 4) PLACEMENT STARTS BY WEEK (TREND)
-- =====================================
SELECT
  date_trunc('week', start_date) AS week,
  COUNT(*) AS starts
FROM placements
GROUP BY week
ORDER BY week;



-- =====================================
-- 5) PLACEMENT ENDS BY WEEK (TREND)
-- =====================================
SELECT
  date_trunc('week', end_date) AS week,
  COUNT(*) AS ends
FROM placements
WHERE end_date IS NOT NULL
GROUP BY week
ORDER BY week;



-- =====================================
-- 6) EARLY TERMINATION RATE (ENDS WITHIN 30 DAYS)
-- =====================================
WITH ended AS (
  SELECT
    placement_id,
    (end_date - start_date) AS days_active
  FROM placements
  WHERE end_date IS NOT NULL
)
SELECT
  COUNT(*) FILTER (WHERE days_active <= 30)::numeric / NULLIF(COUNT(*),0) AS early_termination_rate
FROM ended;



-- =====================================
-- 7) EARLY TERMINATION RATE BY CLIENT
-- =====================================
WITH ended AS (
  SELECT
    p.placement_id,
    j.client_name,
    (p.end_date - p.start_date) AS days_active
  FROM placements p
  JOIN applications a ON a.application_id = p.application_id
  JOIN jobs j ON j.job_id = a.job_id
  WHERE p.end_date IS NOT NULL
)
SELECT
  client_name,
  COUNT(*) AS ended_placements,
  COUNT(*) FILTER (WHERE days_active <= 30) AS early_terms,
  ROUND((COUNT(*) FILTER (WHERE days_active <= 30)::numeric / NULLIF(COUNT(*),0))::numeric, 4) AS early_term_rate
FROM ended
GROUP BY client_name
HAVING COUNT(*) >= 3
ORDER BY early_term_rate DESC, early_terms DESC;



-- =====================================
-- 8) AVG DAYS ACTIVE (ENDED PLACEMENTS)
-- =====================================
SELECT
  ROUND(AVG(end_date - start_date)::numeric, 2) AS avg_days_active
FROM placements
WHERE end_date IS NOT NULL;



-- =====================================
-- 9) MARGIN METRICS (ALL PLACEMENTS)
-- =====================================
SELECT
  ROUND(AVG(bill_rate - pay_rate)::numeric, 2) AS avg_margin_dollars,
  ROUND(AVG((bill_rate - pay_rate) / NULLIF(bill_rate,0))::numeric, 4) AS avg_margin_pct
FROM placements;



-- =====================================
-- 10) MARGIN BY CLIENT (DELIVERY PROFITABILITY)
-- =====================================
SELECT
  j.client_name,
  COUNT(*) AS placements,
  ROUND(AVG(p.bill_rate - p.pay_rate)::numeric, 2) AS avg_margin_dollars,
  ROUND(AVG((p.bill_rate - p.pay_rate) / NULLIF(p.bill_rate,0))::numeric, 4) AS avg_margin_pct
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id
GROUP BY j.client_name
HAVING COUNT(*) >= 3
ORDER BY avg_margin_pct DESC, avg_margin_dollars DESC;



-- =====================================
-- 11) ACTIVE MARGIN RUN-RATE SIGNAL (ACTIVE ONLY)
-- proxy: sum(bill_rate - pay_rate) across active placements
-- =====================================
SELECT
  j.client_name,
  COUNT(*) AS active_placements,
  ROUND(SUM(p.bill_rate - p.pay_rate)::numeric, 2) AS active_margin_sum,
  ROUND(AVG(p.bill_rate - p.pay_rate)::numeric, 2) AS active_margin_avg
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id
WHERE p.status = 'active'
GROUP BY j.client_name
ORDER BY active_margin_sum DESC;



-- =====================================
-- 12) PLACEMENTS BY JOB TYPE
-- =====================================
SELECT
  j.job_type,
  COUNT(*) AS placements
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id
GROUP BY j.job_type
ORDER BY placements DESC;
