### список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период(cnt_month=12), средний чек за период с 01.06.2015 по 01.06.2016(avg_all_check), средняя сумма покупок за месяц(avg_month), количество всех операций по клиенту за период(cnt_payments)

WITH avg_payment_month AS(
	SELECT 
		ID_client,
		date_month,
		AVG(sum_check) AS avg_month
	FROM (SELECT
			ID_client,
			DATE_FORMAT(date_new, '%Y-%m') AS date_month,
			Id_check,
			SUM(Sum_payment) AS sum_check
		  FROM transactions
          GROUP BY ID_client, DATE_FORMAT(date_new, '%Y-%m'), Id_check
          ) AS sum_check_client
	WHERE date_month >= '2015-06-01'  AND date_month < '2016-06-01'
	GROUP BY ID_client, date_month
),

clients_12 AS (
	SELECT
		ID_client,
		COUNT(DISTINCT date_month) AS cnt_month
	FROM avg_payment_month
	GROUP BY ID_client
	HAVING COUNT(*) = 12
)

SELECT 
	apm.ID_client,
    apm.date_month,
	apm.avg_month
FROM avg_payment_month AS apm
JOIN clients_12 AS c ON c.ID_client = apm.ID_client
ORDER BY apm.ID_client, apm.date_month;

SELECT 
	AVG(sum_check) AS avg_all_check
FROM (SELECT
			ID_client,
			date_new,
			Id_check,
			SUM(Sum_payment) AS sum_check
		FROM transactions
        WHERE date_new >= '2015-06-01'  AND date_new < '2016-06-01'
        GROUP BY ID_client, date_new, Id_check
	   ) AS sum_check_client;


SELECT 
    ID_client,
    COUNT(Id_check) AS cnt_check,
    COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS cnt_month
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY ID_client
HAVING cnt_month=12;

### информацию в разрезе месяцев: a) средняя сумма чека в месяц;(avg_sum_payment) b) среднее количество операций в месяц;(avg_check) c) среднее количество клиентов, которые совершали операции(avg_client); d) долю от общего количества операций за год и долю в месяц от общей суммы операций; e) вывести % соотношение M/F/NA в каждом месяце с их долей затрат;


SELECT
    date_month,
	AVG(sum_check) AS avg_sum_payment
FROM (SELECT 
		DATE_FORMAT(date_new, '%Y-%m') AS date_month,
        Id_check,
		SUM(Sum_payment) AS sum_check
        FROM transactions
      GROUP BY DATE_FORMAT(date_new, '%Y-%m'), Id_check 
      ) AS sum_check_month
GROUP BY date_month;


SELECT
	date_month,
	AVG(cnt_check) AS avg_check
FROM (SELECT
		ID_client,
		DATE_FORMAT(date_new, '%Y-%m') AS date_month,
        COUNT(DISTINCT Id_check) AS cnt_check
        FROM transactions
      GROUP BY ID_client, DATE_FORMAT(date_new, '%Y-%m') 
      ) AS cnt_check_month
GROUP BY date_month;


SELECT
	AVG(cnt_client) AS avg_client
FROM (SELECT 
		DATE_FORMAT(date_new, '%Y-%m') AS date_month,
		COUNT(DISTINCT ID_client) AS cnt_client
	  FROM transactions
      GROUP BY DATE_FORMAT(date_new, '%Y-%m')
      ) AS cnt_client_month;


SELECT
	DATE_FORMAT(date_new, '%Y-%m') AS date_month,
    COUNT(DISTINCT Id_check) AS cnt_month_check,
    SUM(Sum_payment) AS sum_month_check,
    COUNT(DISTINCT Id_check) * 100.0 / SUM(COUNT(DISTINCT Id_check)) OVER () AS percent_all_check,
    SUM(Sum_payment) * 100.0 / SUM(SUM(Sum_payment)) OVER () AS percent_sum_all_check
FROM transactions
GROUP BY DATE_FORMAT(date_new, '%Y-%m');


SELECT 
	s.date_month,
    c.Gender,
    COUNT(c.Gender) * 100.0 / SUM(COUNT(c.Gender)) OVER(PARTITION BY s.date_month) AS percent_gender,
    SUM(s.sum_check) * 100.0 / SUM(SUM(s.sum_check)) OVER (PARTITION BY s.date_month) AS percent_all_sum
FROM sum_client AS s
JOIN customers AS c ON s.ID_client = c.ID_client
GROUP BY s.date_month, c.Gender
ORDER BY s.date_month, c.Gender;


### возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

WITH age_quarter AS (
    SELECT
        CASE
            WHEN Age IS NULL THEN 'EMPTY'
            WHEN Age BETWEEN 1 AND 10 THEN '1-10'
            WHEN Age BETWEEN 11 AND 20 THEN '11-20'
            WHEN Age BETWEEN 21 AND 30 THEN '21-30'
            WHEN Age BETWEEN 31 AND 40 THEN '31-40'
            WHEN Age BETWEEN 41 AND 50 THEN '41-50'
            WHEN Age BETWEEN 51 AND 60 THEN '51-60'
            WHEN Age BETWEEN 61 AND 70 THEN '61-70'
            WHEN Age BETWEEN 71 AND 80 THEN '71-80'
            WHEN Age BETWEEN 81 AND 90 THEN '81-90'
            ELSE '90+'
        END AS age_group,
        CASE
            WHEN date_new >= '2015-04-01' AND date_new < '2015-07-01' THEN '2015_2Qrt'
            WHEN date_new >= '2015-07-01' AND date_new < '2015-10-01' THEN '2015_3Qrt'
            WHEN date_new >= '2015-10-01' AND date_new < '2016-01-01' THEN '2015_4Qrt'
            WHEN date_new >= '2016-01-01' AND date_new < '2016-04-01' THEN '2016_1Qrt'
            WHEN date_new >= '2016-04-01' AND date_new < '2016-07-01' THEN '2016_2Qrt'
            ELSE 'Не_указан'
        END AS date_qrt,
        SUM(Sum_payment) AS sum_payment,
        COUNT(DISTINCT Id_check) AS cnt_check
    FROM transactions AS t
    JOIN customers AS c ON t.ID_client = c.ID_client
    GROUP BY
        CASE
            WHEN Age IS NULL THEN 'EMPTY'
            WHEN Age BETWEEN 1 AND 10 THEN '1-10'
            WHEN Age BETWEEN 11 AND 20 THEN '11-20'
            WHEN Age BETWEEN 21 AND 30 THEN '21-30'
            WHEN Age BETWEEN 31 AND 40 THEN '31-40'
            WHEN Age BETWEEN 41 AND 50 THEN '41-50'
            WHEN Age BETWEEN 51 AND 60 THEN '51-60'
            WHEN Age BETWEEN 61 AND 70 THEN '61-70'
            WHEN Age BETWEEN 71 AND 80 THEN '71-80'
            WHEN Age BETWEEN 81 AND 90 THEN '81-90'
            ELSE '90+'
        END,
		CASE
            WHEN date_new >= '2015-04-01' AND date_new < '2015-07-01' THEN '2015_2Qrt'
            WHEN date_new >= '2015-07-01' AND date_new < '2015-10-01' THEN '2015_3Qrt'
            WHEN date_new >= '2015-10-01' AND date_new < '2016-01-01' THEN '2015_4Qrt'
            WHEN date_new >= '2016-01-01' AND date_new < '2016-04-01' THEN '2016_1Qrt'
            WHEN date_new >= '2016-04-01' AND date_new < '2016-07-01' THEN '2016_2Qrt'
            ELSE 'Не_указан'
        END
)

SELECT
    age_group,
    date_qrt,
    sum_payment,
    cnt_check,
    AVG(sum_payment) OVER (PARTITION BY age_group) AS avg_qrt_sum,
    AVG(cnt_check) OVER (PARTITION BY age_group) AS avg_qrt_check,
    sum_payment * 100.0 / SUM(sum_payment) OVER () AS percent_all_sum,
    cnt_check * 100.0  / SUM(cnt_check) OVER () AS percent_all_check
FROM age_quarter
ORDER BY age_group, date_qrt;
      