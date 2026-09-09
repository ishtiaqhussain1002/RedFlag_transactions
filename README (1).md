# RedFlag — The Fraud Files

A pure-SQL fraud detection project based on the Unlox Academy minor-project brief.

## Project goal

RedFlag analyzes PayFast's six-month transaction history and detects 12 fraud patterns using **MySQL only**. It uses `GROUP BY`, `HAVING`, `CASE WHEN`, subqueries, `EXISTS`, CTEs, `ROW_NUMBER()`, and `LAG()`.

## Tech stack

- MySQL 8.x
- VS Code
- A MySQL/SQL extension for VS Code
- SQL only for the submitted detection file
- No machine learning

## Files

```text
RedFlag/
├── README.md
├── RedFlag_YourName.sql
└── screenshots/
    └── (add 3–4 screenshots of query results here)
```

Do **not** upload `redflag_transactions.sql` to GitHub. The project brief explicitly says to leave the large dataset out of the public repository.

## Setup

1. Install MySQL Community Server.
2. Install VS Code and a MySQL extension.
3. Open `redflag_transactions.sql` in MySQL Workbench or execute it with MySQL.
4. The script creates the `redflag` database and `transactions` table and loads the dataset.
5. In Workbench, if the import times out, set `Edit → Preferences → SQL Editor → DBMS connection read timeout` to `600` and restart Workbench.

Verify the data:

```sql
USE redflag;
SELECT COUNT(*) FROM transactions;
SELECT COUNT(DISTINCT user_id) FROM transactions;
SELECT MIN(txn_time), MAX(txn_time) FROM transactions;
```

The brief expects approximately 200,000 rows, approximately 14,700 users, and dates from 2024-01-01 through 2024-06-30.

## Fraud patterns

1. Velocity Fraud
2. Round-Amount Clustering
3. Card Testing
4. Failed-Then-Succeeded
5. Odd-Hour Concentration
6. Mule Accounts
7. Refund Abuse
8. Merchant Collusion
9. Just-Under-Threshold / Structuring
10. Dormant-Then-Active
11. Velocity Spike
12. Geographic Impossibility

## Expected results

| Pattern | Expected suspects |
|---|---:|
| P1 | 45–55 user-days |
| P2 | 25 users |
| P3 | 20 users |
| P4 | 25 users |
| P5 | 20 users |
| P6 | 30 users |
| P7 | 24–25 users |
| P8 | 15 merchants |
| P9 | 20 users |
| P10 | 25–27 results |
| P11 | 35–45 users |
| P12 | 15 users |

These ranges are taken from the supplied project brief. Run the SQL against the supplied dataset to verify the actual output.

## GitHub structure

```text
RedFlag/
├── README.md
├── RedFlag_YourName.sql
└── screenshots/
    ├── p1_velocity.png
    ├── p8_collusion.png
    ├── p11_velocity_spike.png
    └── p12_geo.png
```

Do not commit the 18 MB transaction dataset.

## Note

This is a simulated fraud-analysis project using fictional PayFast data. A query flag is a behavioral signal, not proof of criminal activity.
