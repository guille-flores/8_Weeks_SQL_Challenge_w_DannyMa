
```sql
SELECT
	customer_id,
    s.plan_id,
    p.plan_name,
    start_date
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p ON p.plan_id = s.plan_id
WHERE customer_id IN ('1', '2', '11', '13', '15', '16', '18', '19')
ORDER BY customer_id, start_date
```
