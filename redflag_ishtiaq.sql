USE redflag;

-- 1. VELOCITY FRAUD
SELECT user_id, DATE(txn_time) AS txn_date, COUNT(*) AS txn_count
FROM transactions
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY txn_count DESC;


-- 2. ROUND-AMOUNT CLUSTERING
SELECT user_id, COUNT(*) AS round_count
FROM transactions
WHERE amount IN (100,200,500,1000,2000,5000,10000)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_count DESC;


-- 3. CARD TESTING
SELECT user_id, DATE(txn_time) AS txn_date, COUNT(*) AS tiny_count
FROM transactions
WHERE amount < 10
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY tiny_count DESC;


-- 4. FAILED THEN SUCCEEDED
SELECT f.user_id, COUNT(*) AS matched_failures
FROM transactions f
WHERE f.status = 'FAILED'
AND EXISTS (
    SELECT 1
    FROM transactions s
    WHERE s.user_id = f.user_id
    AND s.status = 'SUCCESS'
    AND s.amount = f.amount
    AND s.txn_time > f.txn_time
    AND TIMESTAMPDIFF(MINUTE,f.txn_time,s.txn_time) <= 2
)
GROUP BY f.user_id
HAVING COUNT(*) >= 20
ORDER BY matched_failures DESC;


-- 5. ODD-HOUR CONCENTRATION
SELECT user_id,
       COUNT(*) AS total_txns,
       SUM(CASE WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1 ELSE 0 END) AS odd_txns
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
AND odd_txns / COUNT(*) >= 0.80
ORDER BY odd_txns DESC;


-- 6. MULE ACCOUNTS
SELECT c.user_id, COUNT(*) AS mule_instances
FROM transactions c
WHERE c.txn_type = 'CREDIT'
AND c.payment_mode = 'NETBANKING'
AND EXISTS (
    SELECT 1
    FROM transactions d
    WHERE d.user_id = c.user_id
    AND d.txn_type = 'DEBIT'
    AND d.payment_mode = 'UPI'
    AND d.txn_time > c.txn_time
    AND TIMESTAMPDIFF(MINUTE,c.txn_time,d.txn_time) <= 30
    AND d.amount >= c.amount * 0.70
)
GROUP BY c.user_id
HAVING COUNT(*) >= 5
ORDER BY mule_instances DESC;


-- 7. REFUND ABUSE
SELECT user_id,
       COUNT(*) AS total_txns,
       SUM(CASE WHEN txn_type = 'REFUND' THEN 1 ELSE 0 END) AS refunds
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
AND refunds / COUNT(*) > 0.40
ORDER BY refunds DESC;


-- 8. MERCHANT COLLUSION
WITH uv AS (
    SELECT merchant_id, user_id, SUM(amount) AS volume
    FROM transactions
    WHERE status = 'SUCCESS'
    GROUP BY merchant_id, user_id
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER(
        PARTITION BY merchant_id ORDER BY volume DESC
    ) AS rnk
    FROM uv
),
top5 AS (
    SELECT merchant_id, SUM(volume) AS top_volume
    FROM ranked
    WHERE rnk <= 5
    GROUP BY merchant_id
),
total AS (
    SELECT merchant_id, SUM(amount) AS total_volume
    FROM transactions
    WHERE status = 'SUCCESS'
    GROUP BY merchant_id
)
SELECT t.merchant_id, t.top_volume, m.total_volume,
       t.top_volume / m.total_volume AS top5_ratio
FROM top5 t
JOIN total m ON t.merchant_id = m.merchant_id
WHERE t.top_volume / m.total_volume > 0.60
ORDER BY top5_ratio DESC;


-- 9. JUST-UNDER-THRESHOLD
SELECT user_id, COUNT(*) AS txn_count
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY txn_count DESC;


-- 10. DORMANT THEN ACTIVE
WITH x AS (
    SELECT *,
           LAG(txn_time) OVER(
               PARTITION BY user_id ORDER BY txn_time
           ) AS prev_time
    FROM transactions
),
gaps AS (
    SELECT user_id, txn_time AS dormant_end
    FROM x
    WHERE prev_time IS NOT NULL
    AND TIMESTAMPDIFF(DAY,prev_time,txn_time) >= 90
)
SELECT g.user_id, g.dormant_end, COUNT(t.txn_id) AS post_gap_txns
FROM gaps g
JOIN transactions t
ON t.user_id = g.user_id
AND t.txn_time > g.dormant_end
GROUP BY g.user_id, g.dormant_end
HAVING COUNT(t.txn_id) >= 15
ORDER BY post_gap_txns DESC;


-- 11. VELOCITY SPIKE
WITH monthly AS (
    SELECT user_id,
           DATE_FORMAT(txn_time,'%Y-%m') AS month,
           COUNT(*) AS txn_count
    FROM transactions
    GROUP BY user_id, DATE_FORMAT(txn_time,'%Y-%m')
),
stats AS (
    SELECT user_id,
           AVG(txn_count) AS avg_txns,
           MAX(txn_count) AS peak_txns,
           COUNT(*) AS active_months
    FROM monthly
    GROUP BY user_id
)
SELECT user_id, peak_txns, ROUND(avg_txns,2) AS avg_txns
FROM stats
WHERE peak_txns >= 20
AND peak_txns >= 5 * avg_txns
AND active_months >= 2
ORDER BY peak_txns DESC;


-- 12. GEOGRAPHIC IMPOSSIBILITY
WITH x AS (
    SELECT *,
           LAG(city) OVER(
               PARTITION BY user_id ORDER BY txn_time
           ) AS prev_city,
           LAG(txn_time) OVER(
               PARTITION BY user_id ORDER BY txn_time
           ) AS prev_time
    FROM transactions
)
SELECT user_id, prev_city, city, prev_time, txn_time
FROM x
WHERE prev_city IS NOT NULL
AND city <> prev_city
AND TIMESTAMPDIFF(MINUTE,prev_time,txn_time) <= 60
ORDER BY user_id, txn_time;