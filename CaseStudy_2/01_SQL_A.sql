WITH cco AS (
  SELECT 
	c_o.customer_id,
  	c_o.order_id,
  	c_o.pizza_id,  
  	CASE
  		WHEN c_o.exclusions = '' OR c_o.exclusions = 'null' THEN NULL
  		ELSE c_o.exclusions
  	END exclusions,
  	CASE
  		WHEN c_o.extras = '' OR c_o.extras = 'null' THEN NULL
  		ELSE c_o.extras
  	END extras
  FROM pizza_runner.customer_orders c_o
), cro AS (
  SELECT 
  	  r_o.order_id,
      r_o.runner_id,
      CASE
          WHEN r_o.pickup_time = 'null' THEN NULL
          ELSE TO_TIMESTAMP(r_o.pickup_time, 'YYYY-MM-DD HH24-MI-SS')
      END pickup_time,
      CASE
  	      WHEN r_o.distance = 'null' THEN NULL
  	      ELSE CAST(SPLIT_PART(r_o.distance, 'km', 1) AS float)
      END distance,
      CASE
  	      WHEN r_o.duration = 'null' THEN NULL
  	      ELSE CAST(SPLIT_PART(r_o.duration, 'min', 1) AS float)
      END duration,
      CASE
  	      WHEN r_o.cancellation = 'null' OR r_o.cancellation = '' THEN NULL
  	      ELSE r_o.cancellation
      END cancellation
  FROM pizza_runner.runner_orders r_o
)
   
/* 1. How many pizzas were ordered?*/
SELECT 
	COUNT(*)
FROM cco

  
/*
| count |
| ----- |
| 14    |

*/
  
  
/* 2. How many unique customer orders were made?*/
SELECT 
    COUNT(DISTINCT cco.order_id)
FROM cco

/*
| count |
| ----- |
| 10    |
*/


/* 3. How many successful orders were delivered by each runner?*/  
SELECT 
	cro.runner_id,
    COUNT(DISTINCT cro.order_id) AS successful_orders
FROM cro
WHERE cro.cancellation IS NULL
GROUP BY cro.runner_id
/*
| runner_id | successful_orders |
| --------- | ----------------- |
| 1         | 4                 |
| 2         | 3                 |
| 3         | 1                 |
*/

/* 4. How many of each type of pizza was delivered?*/
SELECT 
    pz.pizza_name,
    COUNT(*) AS TotalOrdered
FROM cco
INNER JOIN pizza_runner.pizza_names pz ON cco.pizza_id = pz.pizza_id
INNER JOIN cro ON cro.order_id = cco.order_id
WHERE cro.cancellation IS NULL
GROUP BY pz.pizza_name

/*
| pizza_name | totalordered |
| ---------- | ------------ |
| Meatlovers | 9            |
| Vegetarian | 3            |
*/


/* 5. How many Vegetarian and Meatlovers were ordered by each customer?*/

SELECT 
	cco.customer_id,
    pz.pizza_name,
    COUNT(*) AS TotalOrdered
FROM cco
INNER JOIN pizza_runner.pizza_names pz ON cco.pizza_id = pz.pizza_id
INNER JOIN cro ON cro.order_id = cco.order_id
GROUP BY cco.customer_id, pz.pizza_name
ORDER BY cco.customer_id

/*
| customer_id | pizza_name | totalordered |
| ----------- | ---------- | ------------ |
| 101         | Meatlovers | 2            |
| 101         | Vegetarian | 1            |
| 102         | Meatlovers | 2            |
| 102         | Vegetarian | 1            |
| 103         | Meatlovers | 3            |
| 103         | Vegetarian | 1            |
| 104         | Meatlovers | 3            |
| 105         | Vegetarian | 1            |

*/



/* 6. What was the maximum number of pizzas delivered in a single order? */
SELECT 
	cco.order_id,
    COUNT(*) AS delivered_pizzas
FROM cco
INNER JOIN cro ON cro.order_id = cco.order_id
WHERE cro.cancellation IS NULL
GROUP BY cco.order_id
ORDER BY delivered_pizzas DESC
LIMIT 1

/*
| oder_id | deliveredpizzas |
| 4       | 3               |
*/



/* 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?*/
SELECT 
	cco.customer_id,
    COUNT(*) FILTER (WHERE cco.exclusions IS NOT NULL OR cco.extras IS NOT NULL) AS pizzas_w_changes,
    COUNT(*) FILTER (WHERE cco.exclusions IS NULL OR cco.extras IS NULL) AS pizzas_wo_changes
FROM cco
INNER JOIN cro ON cro.order_id = cco.order_id
WHERE cro.cancellation IS NULL
GROUP BY cco.customer_id
ORDER BY cco.customer_id

/*
| customer_id | pizzas_w_changes | pizzas_wo_changes |
| ----------- | ---------------- | ----------------- |
| 101         | 0                | 2                 |
| 102         | 0                | 3                 |
| 103         | 3                | 3                 |
| 104         | 2                | 2                 |
| 105         | 1                | 1                 |
*/

/* 8. How many pizzas were delivered that had both exclusions and extras? */

SELECT 
    COUNT(*) AS deliver_w_extras_exlusions
FROM cco
INNER JOIN cro ON cro.order_id = cco.order_id
WHERE cro.cancellation IS NULL AND cco.exclusions IS NOT NULL AND cco.extras IS NOT NULL

/*
| deliver_w_extras_exlusions |
| -------------------------- |
| 1                          |
*/


/* 9. What was the total volume of pizzas ordered for each hour of the day? */
SELECT 
	TO_CHAR(cco.order_time, 'YYYY-MM-DD') AS DATE,
    EXTRACT(HOUR FROM cco.order_time) AS HOUR,
    COUNT(*) AS order_per_hour
FROM cco
GROUP BY TO_CHAR(cco.order_time, 'YYYY-MM-DD'), EXTRACT(HOUR FROM cco.order_time)
ORDER BY TO_CHAR(cco.order_time, 'YYYY-MM-DD'), EXTRACT(HOUR FROM cco.order_time)


/*
| date       | hour | order_per_hour |
| ---------- | ---- | -------------- |
| 2020-01-01 | 18   | 1              |
| 2020-01-01 | 19   | 1              |
| 2020-01-02 | 23   | 2              |
| 2020-01-04 | 13   | 3              |
| 2020-01-08 | 21   | 3              |
| 2020-01-09 | 23   | 1              |
| 2020-01-10 | 11   | 1              |
| 2020-01-11 | 18   | 2              |
*/
