-- =========================
-- PIPELINE KPI QUERIES
-- staffing analytics
-- =========================


-- =====================================
-- 1. JOB COUNT BY STATUS
-- =====================================

SELECT
    status,
    COUNT(*) AS job_count
FROM jobs
GROUP BY status
ORDER BY job_count DESC;



-- =====================================
-- 2. OPEN JOB AGING BUCKETS
-- =====================================

SELECT
    CASE
        WHEN age(now(), created_at) < interval '7 days' THEN '0-7 days'
        WHEN age(now(), created_at) < interval '14 days' THEN '8-14 days'
        WHEN age(now(), created_at) < interval '30 days' THEN '15-30 days'
        WHEN age(now(), created_at) < interval '60 days' THEN '31-60 days'
        ELSE '60+ days'
    END AS age_bucket,
    COUNT(*) AS jobs
FROM jobs
WHERE status = 'open'
GROUP BY age_bucket
ORDER BY age_bucket;



-- =====================================
-- 3. APPLICATION FUNNEL COUNTS
-- =====================================

SELECT
    stage,
    COUNT(*) AS applications
FROM applications
GROUP BY stage
ORDER BY applications DESC;



-- =====================================
-- 4. FUNNEL CONVERSION RATES
-- =====================================

WITH counts AS (

    SELECT
        COUNT(*) FILTER (WHERE stage = 'applied') AS applied,
        COUNT(*) FILTER (WHERE stage = 'screened') AS screened,
        COUNT(*) FILTER (WHERE stage = 'submitted') AS submitted,
        COUNT(*) FILTER (WHERE stage = 'interviewing') AS interviewing,
        COUNT(*) FILTER (WHERE stage = 'offered') AS offered,
        COUNT(*) FILTER (WHERE stage = 'placed') AS placed

    FROM applications

)

SELECT
    applied,
    screened,
    submitted,
    interviewing,
    offered,
    placed,

    screened::numeric / NULLIF(applied,0) AS applied_to_screened,
    submitted::numeric / NULLIF(screened,0) AS screened_to_submitted,
    interviewing::numeric / NULLIF(submitted,0) AS submitted_to_interview,
    offered::numeric / NULLIF(interviewing,0) AS interview_to_offer,
    placed::numeric / NULLIF(offered,0) AS offer_to_place

FROM counts;



-- =====================================
-- 5. TIME TO FILL (JOB CREATED -> START DATE)
-- =====================================

SELECT
    j.job_id,
    j.client_name,
    j.job_title,
    p.start_date,
    j.created_at,
    (p.start_date - j.created_at::date) AS days_to_fill
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id
ORDER BY days_to_fill;



-- =====================================
-- 6. AVERAGE TIME TO FILL
-- =====================================

SELECT
    AVG(p.start_date - j.created_at::date) AS avg_days_to_fill
FROM placements p
JOIN applications a ON a.application_id = p.application_id
JOIN jobs j ON j.job_id = a.job_id;



-- =====================================
-- 7. OFFER ACCEPTANCE RATE
-- =====================================

SELECT
    COUNT(*) FILTER (WHERE result = 'accepted')::numeric /
    COUNT(*) AS acceptance_rate
FROM offers;



-- =====================================
-- 8. ACTIVE PLACEMENTS
-- =====================================

SELECT
    status,
    COUNT(*)
FROM placements
GROUP BY status;



-- =====================================
-- 9. AVG MARGIN PER PLACEMENT
-- =====================================

SELECT
    AVG(bill_rate - pay_rate) AS avg_margin,
    AVG((bill_rate - pay_rate) / bill_rate) AS avg_margin_pct
FROM placements;



-- =====================================
-- 10. WEEKLY PLACEMENT TREND
-- =====================================

SELECT
    date_trunc('week', start_date) AS week,
    COUNT(*) AS placements
FROM placements
GROUP BY week
ORDER BY week;
