KPI Dictionary – IT Staffing Analytics Project

This document defines the metrics used in the SQL KPI queries.
The goal of this project is to simulate analytics reporting for an IT staffing / consulting company, including recruiting, sales, and delivery performance.

⸻

Pipeline KPIs

Job Count by Status

Number of jobs grouped by current status (open, on_hold, filled, canceled).

Used to understand overall pipeline volume.

⸻

Open Job Aging Buckets

Groups open jobs by how long they have been open.

Example buckets:
	•	0–7 days
	•	8–14 days
	•	15–30 days
	•	31–60 days
	•	60+ days

Used to identify jobs that are difficult to fill.

⸻

Funnel Counts

Number of applications in each stage:
	•	applied
	•	screened
	•	submitted
	•	interviewing
	•	offered
	•	placed
	•	rejected
	•	withdrawn

Used to monitor pipeline health.

⸻

Funnel Conversion Rates

Measures how candidates move through the funnel.

Examples:
	•	screened / applied
	•	submitted / screened
	•	interviewing / submitted
	•	offered / interviewing
	•	placed / offered

Used to find bottlenecks in recruiting.

⸻

Time to Fill

Days between job creation and placement start.

Formula:

placement.start_date - job.created_at

Used to measure delivery speed.

⸻

Average Time to Fill

Average number of days required to fill jobs.

Used to compare performance across clients or time periods.

⸻

Offer Acceptance Rate

Percentage of offers that are accepted.

Formula:

accepted_offers / total_offers

Used to evaluate candidate quality and compensation competitiveness.

⸻

Recruiting KPIs

Candidates by Source

Number of candidates from each source:
	•	referral
	•	linkedin
	•	inbound
	•	job_board
	•	agency
	•	campus

Used to evaluate sourcing channels.

⸻

Source Conversion Rate

Placements produced per candidate source.

Formula:

placements / candidates_from_source

Used to identify high-quality sources.

⸻

Interview Results

Counts of interview outcomes:
	•	pass
	•	fail
	•	no_show
	•	pending

Used to monitor recruiting quality.

⸻

Interview No-Show Rate

Percentage of interviews where the candidate did not attend.

Used to identify scheduling or candidate quality issues.

⸻

Interview Pass Rate

Percentage of completed interviews that pass.

Used to evaluate screening effectiveness.

⸻

Offer Acceptance Rate by Skill

Acceptance rate grouped by candidate skill.

Used to detect pay or market issues.

⸻

Rejection Reasons

Counts of rejection reasons recorded in applications.

Examples:
	•	not_a_fit
	•	no_response
	•	rate_mismatch
	•	client_declined
	•	failed_screen
	•	withdrew

Used to identify common failure points.

⸻

Time to First Interview

Days between application and first interview.

Used to measure recruiter responsiveness.

⸻

Time to Offer

Days between application and offer.

Used to measure recruiting speed.

⸻

Sales / Client KPIs

Jobs Opened by Client

Number of jobs requested by each client.

Used to identify major customers.

⸻

Open Jobs by Client

Current open positions per client.

Used to measure active demand.

⸻

Fill Count by Client

Number of placements per client.

Used to measure delivery success.

⸻

Fill Rate

Placements divided by jobs opened.

Formula:

placements / jobs_opened

Used to evaluate account performance.

⸻

Average Bill Rate

Average bill rate for placements.

Used to monitor pricing.

⸻

Average Margin

Average difference between bill rate and pay rate.

Formula:

bill_rate - pay_rate

Used to estimate profitability.

⸻

Margin %

Percentage margin on placements.

Formula:

(bill_rate - pay_rate) / bill_rate

Used to evaluate financial health.

⸻

Stuck Jobs

Open jobs older than 30 days with no placements.

Used to identify at-risk accounts.

⸻

Time to Fill by Client

Average days required to fill jobs for each client.

Used to compare account difficulty.

⸻

Job Type Mix

Distribution of:
	•	contract
	•	contract_to_hire
	•	perm

Used to understand business model.

⸻

Delivery KPIs

Placements by Status

Counts of:
	•	active
	•	ended
	•	terminated

Used to monitor workforce size.

⸻

Active Placements

Number of currently active consultants.

Used as a key revenue indicator.

⸻

Starts per Week

Number of placements starting each week.

Used to monitor growth.

⸻

Ends per Week

Number of placements ending each week.

Used to monitor churn.

⸻

Early Termination Rate

Placements ending within 30 days.

Formula:

ended_within_30 / total_ended

Used to detect delivery issues.

⸻

Average Days Active

Average length of completed placements.

Used to measure retention.

⸻

Margin Metrics

Average profit per placement.

Used to estimate delivery performance.

⸻

Active Margin Run Rate

Sum of margin across active placements.

Used as a proxy for current profitability.

⸻

Placements by Job Type

Counts of placements grouped by job type.

Used to understand revenue mix.

⸻

Data Quality Checks

These queries detect invalid or suspicious data.

Examples:
	•	pay_rate > bill_rate
	•	placement without offer
	•	offer without interview
	•	job filled but no placement
	•	inconsistent status values

Used to ensure reporting accuracy.
