SELECT * FROM customers;
SELECT * FROM transactions;
#FINAL PROJECT SQL - DINA

#1
 WITH client_data AS (
	SELECT 
		ID_client, 
		COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) as months_count,
		SUM(Sum_payment) as total_amount,
		COUNT(Id_check) as total_operations,
		COUNT(DISTINCT Id_check) as unique_checks_count
	FROM transactions
	WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
	GROUP BY ID_client
	HAVING months_count = 12
	)
SELECT 
    ID_client,
    ROUND(total_amount / unique_checks_count, 0) AS average_check,
    ROUND(total_amount / 12, 0) AS average_monthly_amount,
    total_operations
FROM client_data;

#2a
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month_period,
    SUM(Sum_payment) AS total_month_revenue,  
    COUNT(DISTINCT Id_check) AS month_checks_count,
    ROUND(SUM(Sum_payment) / COUNT(DISTINCT Id_check), 0) AS avg_check_monthly
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month_period
ORDER BY month_period;

#2b
SELECT
	DATE_FORMAT(date_new, '%Y-%m') AS month_period,
	COUNT(DISTINCT Id_check) AS unique_checks,
	COUNT(DISTINCT ID_client) AS clients,
    ROUND(COUNT(DISTINCT Id_check) / COUNT(DISTINCT ID_client), 2) AS avg_operations
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month_period
ORDER BY month_period;


#2c
SELECT 
    month_period,
    ROUND(AVG(daily_clients), 0) AS avg_daily_clients
FROM (
	SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS month_period,
        COUNT(DISTINCT ID_client) AS daily_clients
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    GROUP BY date_new
    ) AS daily_data
GROUP BY month_period
ORDER BY month_period;

#2d
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month_period,
    SUM(Sum_payment) AS monthly_payments,
    ROUND(SUM(Sum_payment) / 
    (SELECT 
		SUM(Sum_payment) 
	FROM transactions 
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01') * 100, 
    2) AS pct_sum_of_total,
    COUNT(DISTINCT Id_check) AS monthly_operations,
    ROUND(COUNT(DISTINCT Id_check) / 
		(SELECT 
			COUNT(DISTINCT Id_check) 
		FROM transactions 
        WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01') * 100, 
        2) AS pct_ops_of_total
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month_period
ORDER BY month_period;


#2e
WITH monthly_totals AS (
    SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS month_period,
        SUM(Sum_payment) AS total_month_sum,
        COUNT(DISTINCT ID_client) AS total_month_clients
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    GROUP BY month_period
),
gender_data AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS month_period,
        IFNULL(c.Gender, 'NA') AS gender_group,
        SUM(t.Sum_payment) AS gender_sum,
        COUNT(DISTINCT t.ID_client) AS gender_clients
    FROM transactions t
    LEFT JOIN customers c ON t.ID_client = c.ID_client
    WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
    GROUP BY month_period, gender_group
)
SELECT 
    g.month_period,
    g.gender_group,
    ROUND((g.gender_clients / m.total_month_clients) * 100, 2) AS pct_clients,
    ROUND((g.gender_sum / m.total_month_sum) * 100, 2) AS pct_spending
FROM gender_data g
JOIN monthly_totals m ON g.month_period = m.month_period
ORDER BY g.month_period, g.gender_group;


#3
WITH quarter_totals AS 
	(SELECT 
          QUARTER(date_new) AS quarter,
          YEAR(date_new) AS year,
          SUM(Sum_payment) AS total_q_sum,
          COUNT(DISTINCT Id_check) AS total_q_ops
     FROM transactions
     WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
     GROUP BY year, quarter
), 
age_quarterly AS 
	(SELECT 
          QUARTER(t.date_new) AS quarter,
          YEAR(t.date_new) AS year,
          CASE 
               WHEN c.Age IS NULL THEN 'NA'
               ELSE CONCAT(FLOOR(c.Age / 10) * 10, '-', (FLOOR(c.Age / 10) * 10) + 9)
          END AS age_bins,
          SUM(t.Sum_payment) AS q_revenue,
          COUNT(DISTINCT t.Id_check) AS q_operations
     FROM transactions t
     LEFT JOIN customers c ON t.ID_client = c.ID_client
     WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
     GROUP BY year, quarter, age_bins
) 
SELECT 
     aq.year,
     aq.quarter,
     aq.age_bins,
     aq.q_revenue AS sum_payments,
     aq.q_operations AS count_operations,
     ROUND(aq.q_revenue / aq.q_operations, 2) AS avg_check,
     ROUND((aq.q_revenue / qt.total_q_sum) * 100, 2) AS pct_payments_share,
     ROUND((aq.q_operations / qt.total_q_ops) * 100, 2) AS pct_ops_share
FROM age_quarterly aq
JOIN quarter_totals qt ON aq.quarter = qt.quarter AND aq.year = qt.year
ORDER BY aq.year, aq.quarter, aq.age_bins;