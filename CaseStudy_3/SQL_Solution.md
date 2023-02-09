
### A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

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

| customer_id | plan_id | plan_name     | start_date               |
| ----------- | ------- | ------------- | ------------------------ |
| 1           | 0       | trial         | 2020-08-01T00:00:00.000Z |
| 1           | 1       | basic monthly | 2020-08-08T00:00:00.000Z |
| 2           | 0       | trial         | 2020-09-20T00:00:00.000Z |
| 2           | 3       | pro annual    | 2020-09-27T00:00:00.000Z |
| 11          | 0       | trial         | 2020-11-19T00:00:00.000Z |
| 11          | 4       | churn         | 2020-11-26T00:00:00.000Z |
| 13          | 0       | trial         | 2020-12-15T00:00:00.000Z |
| 13          | 1       | basic monthly | 2020-12-22T00:00:00.000Z |
| 13          | 2       | pro monthly   | 2021-03-29T00:00:00.000Z |
| 15          | 0       | trial         | 2020-03-17T00:00:00.000Z |
| 15          | 2       | pro monthly   | 2020-03-24T00:00:00.000Z |
| 15          | 4       | churn         | 2020-04-29T00:00:00.000Z |
| 16          | 0       | trial         | 2020-05-31T00:00:00.000Z |
| 16          | 1       | basic monthly | 2020-06-07T00:00:00.000Z |
| 16          | 3       | pro annual    | 2020-10-21T00:00:00.000Z |
| 18          | 0       | trial         | 2020-07-06T00:00:00.000Z |
| 18          | 2       | pro monthly   | 2020-07-13T00:00:00.000Z |
| 19          | 0       | trial         | 2020-06-22T00:00:00.000Z |
| 19          | 2       | pro monthly   | 2020-06-29T00:00:00.000Z |
| 19          | 3       | pro annual    | 2020-08-29T00:00:00.000Z |


We can see that 
- customer 1 started with a trial plan and, which last 7 days. Right after the trial ended, the consumer upgraded to a basic monthly plan.
- customer 2, on the other hand, started with a trial and upgraded to a pro annual plan right after the trial period.
- customer 11 started the trial and cancelled the subscription after the trial ended
- customer 13 stated as customer 1, from trial to basic monthly plans. Then, after 7 days on basic plan, the customer upgraded to a pro monthly plan.
- customer 15 went from trial to pro monthly, and after a bit more than 1 month, the customer cancelled the subscription.
- customer 16 went from trial to basic monthly, and then, after 4.5 months happened, changed to pro annual.
- customer 18 went from trial to pro monthly as soon as the trial ended
- Finally, customer 19 went form trial to pro monthly, and after 2 months changed it to pro annual.

### B. Data Analysis Questions
1. How many customers has Foodie-Fi ever had? 

```sql
SELECT
	COUNT(DISTINCT customer_id)
FROM foodie_fi.subscriptions s
```

| count |
| ----- |
| 1000  |

2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

```sql
SELECT
    TO_CHAR(
      MAKE_DATE(
        DATE_PART('year', start_date)::INTEGER, 
        DATE_PART('month', start_date)::INTEGER, 
        1),
      'yyyy-mm-dd') AS date_yyyy_mm_dd,
      COUNT(*) AS number_of_trial_customers
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p
	ON p.plan_id = s.plan_id
WHERE s.plan_id = '0'
GROUP BY DATE_PART('year', start_date), DATE_PART('month', start_date)
ORDER BY date_yyyy_mm_dd
```


| date_yyyy_mm_dd | number_of_trial_customers |
| --------------- | ------------------------- |
| 2020-01-01      | 88                        |
| 2020-02-01      | 68                        |
| 2020-03-01      | 94                        |
| 2020-04-01      | 81                        |
| 2020-05-01      | 88                        |
| 2020-06-01      | 79                        |
| 2020-07-01      | 89                        |
| 2020-08-01      | 88                        |
| 2020-09-01      | 87                        |
| 2020-10-01      | 79                        |
| 2020-11-01      | 75                        |
| 2020-12-01      | 84                        |


3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

```sql
SELECT
    plan_name,
    COUNT(*)
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p
	ON p.plan_id = s.plan_id
WHERE DATE_PART('year', start_date)::INTEGER > 2020 
GROUP BY plan_name
```

| plan_name     | count |
| ------------- | ----- |
| pro annual    | 63    |
| churn         | 71    |
| pro monthly   | 60    |
| basic monthly | 8     |


4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

```sql
WITH churned_cust AS (
	SELECT
  		'001' AS temp_id,
  		COUNT(plan_id) AS churned_customers
  	FROM foodie_fi.subscriptions s
  	WHERE plan_id = '4'
), total_cust AS (
	SELECT
  		'001' AS temp_id,
  		COUNT(DISTINCT customer_id) AS total_customers
  	FROM foodie_fi.subscriptions s
)

SELECT 
	churned_customers,
    TO_CHAR(100*churned_customers::FLOAT/total_customers::FLOAT, 'fm00D0%') AS percentage
FROM churned_cust c
INNER JOIN total_cust t ON t.temp_id = c.temp_id
```

| churned_customers | percentage |
| ----------------- | ---------- |
| 307               | 30.7%      |


5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql

```


6. What is the number and percentage of customer plans after their initial free trial?

```sql

``` 
7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

```sql

```

8. How many customers have upgraded to an annual plan in 2020?

```sql

``` 
9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

```sql

``` 
10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

```sql

``` 
11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?



### C. Challenge Payment Question
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
* monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
* upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
* upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
* once a customer churns they will no longer make payments

Example outputs for this table might look like the following:
|customer_id	|plan_id	|plan_name	|	payment_date	|amount	|payment_order	|
|---	|---	|---	|	---	|---	|---	|
|1	|1	|basic monthly	|	2020-08-08	|9.9	|1	|
|1	|1	|basic monthly	|	2020-09-08	|9.9	|2	|
|1	|1	|basic monthly	|	2020-10-08	|9.9	|3	|
|1	|1	|basic monthly	|	2020-11-08	|9.9	|4	|
|1	|1	|basic monthly	|	2020-12-08	|9.9	|5	|
|2	|3	|pro annual	|	2020-09-27	|199	|1	|
|13	|1	|basic monthly	|	2020-12-22	|9.9	|1	|
|15	|2	|pro monthly	|	2020-03-24	|19.9	|1	|
|15	|2	|pro monthly	|	2020-04-24	|19.9	|2	|
|16	|1	|basic monthly	|	2020-06-07	|9.9	|1	|
|16	|1	|basic monthly	|	2020-07-07	|9.9	|2	|
|16	|1	|basic monthly	|	2020-08-07	|9.9	|3	|
|16	|1	|basic monthly	|	2020-09-07	|9.9	|4	|
|16	|1	|basic monthly	|	2020-10-07	|9.9	|5	|
|16	|3	|pro annual	|	2020-10-21	|189.1	|6	|
|18	|2	|pro monthly	|	2020-07-13	|19.9	|1	|
|18	|2	|pro monthly	|	2020-08-13	|19.9	|2	|
|18	|2	|pro monthly	|	2020-09-13	|19.9	|3	|
|18	|2	|pro monthly	|	2020-10-13	|19.9	|4	|
|18	|2	|pro monthly	|	2020-11-13	|19.9	|5	|
|18	|2	|pro monthly	|	2020-12-13	|19.9	|6	|
|19	|2	|pro monthly	|	2020-06-29	|19.9	|1	|
|19	|2	|pro monthly	|	2020-07-29	|19.9	|2	|
|19	|3	|pro annual	|	2020-08-29	|199	|3	|


### D. Outside The Box Questions
The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!
