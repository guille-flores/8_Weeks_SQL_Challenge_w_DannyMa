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
  	END extras,
	c_o.order_time
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
   
/* 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)*/

SELECT 
	'Week #'|| RANK() OVER(ORDER BY DATE_TRUNC('week', run.registration_date)) AS Number_Of_Week,
    COUNT(*) AS Registered_Runners
FROM pizza_runner.runners run
GROUP BY DATE_TRUNC('week', run.registration_date)
/*
| number_of_week | registered_runners |
| -------------- | ------------------ |
| Week #1        | 2                  |
| Week #2        | 1                  |
| Week #3        | 1                  |
*/

/* 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?*/
SELECT 
	cro.runner_id,
    AVG(EXTRACT('minute' FROM cro.pickup_time - cco.order_time))::INTEGER AS pickup_delay
FROM cco
INNER JOIN cro on cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY cro.runner_id
ORDER BY cro.runner_id

/*
| runner_id | pickup_delay |
| --------- | ------------ |
| 1         | 15           |
| 2         | 23           |
| 3         | 10           |
*/

/* 3. Is there any relationship between the number of pizzas and how long the order takes to prepare? */
SELECT 
	cco.order_id,
    COUNT(*) AS Number_of_Pizzas,
    AVG(EXTRACT('minute' FROM cro.pickup_time - cco.order_time))::INTEGER AS avg_order_pickup_time,
    (AVG(EXTRACT('minute' FROM cro.pickup_time - cco.order_time))/COUNT(*))::INTEGER AS avg_pickup_time_per_pizza
FROM cco
INNER JOIN cro on cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY cco.order_id
ORDER BY Number_of_Pizzas DESC

/* In general, the more pizzas in an order, the longer it takes. On average, 1 pizza is done in 10 min, except for order_id 8.
| order_id | number_of_pizzas | avg_order_pickup_time | avg_pickup_time_per_pizza |
| -------- | ---------------- | --------------------- | ------------------------- |
| 4        | 3                | 29                    | 10                        |
| 3        | 2                | 21                    | 10                        |
| 10       | 2                | 15                    | 8                         |
| 7        | 1                | 10                    | 10                        |
| 1        | 1                | 10                    | 10                        |
| 5        | 1                | 10                    | 10                        |
| 2        | 1                | 10                    | 10                        |
| 8        | 1                | 20                    | 20                        |
*/

/* 4. What was the average distance travelled for each customer? */
SELECT 
	cco.customer_id,
    ROUND(AVG(cro.distance)::NUMERIC,2) AS avg_distance_km
FROM cco
INNER JOIN cro on cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY cco.customer_id

/*
| customer_id | avg_distance_km |
| ----------- | --------------- |
| 101         | 20.00           |
| 102         | 16.73           |
| 105         | 25.00           |
| 104         | 10.00           |
| 103         | 23.40           |
*/

/* 5. What was the difference between the longest and shortest delivery times for all orders? */
SELECT 
    MAX(cro.duration)-MIN(cro.duration) AS max_min_delivery_difference
FROM cro
WHERE cro.duration IS NOT NULL;
/*
| max_min_delivery_difference |
| --------------------------- |
| 30                          |
*/


/* 6. What was the average speed for each runner for each delivery and do you notice any trend for these values? */
SELECT 
	t1.runner_id,
    t1.order_id,
    t1.distance_km,
    t1.avg_speed_kmhr,
    cco.customer_id
FROM (
  SELECT 
      cro.runner_id,
      cro.order_id,
      AVG(cro.distance) AS distance_km,
      ROUND(AVG(cro.distance/(cro.duration/60))) AS avg_speed_kmhr
  FROM cro
  WHERE cro.duration IS NOT NULL
  GROUP BY cro.runner_id, cro.order_id
  ORDER BY cro.runner_id) t1
INNER JOIN cco ON t1.order_id = cco.order_id

/* Seems like customer 102 distance is incorrect for order id #8, as it seems like an outlier based on previous orders form same customer. 
Besides this, we can notice how with greater distance, the average speed is lower compared with the shortest distance (10km). 

| runner_id | order_id | distance_km | avg_speed_kmhr | customer_id |
| --------- | -------- | ----------- | -------------- | ----------- |
| 1         | 1        | 20          | 38             | 101         |
| 1         | 2        | 20          | 44             | 101         |
| 1         | 3        | 13.4        | 40             | 102         |
| 1         | 3        | 13.4        | 40             | 102         |
| 2         | 4        | 23.4        | 35             | 103         |
| 2         | 4        | 23.4        | 35             | 103         |
| 2         | 4        | 23.4        | 35             | 103         |
| 3         | 5        | 10          | 40             | 104         |
| 2         | 7        | 25          | 60             | 105         |
| 2         | 8        | 23.4        | 94             | 102         |
| 1         | 10       | 10          | 60             | 104         |
| 1         | 10       | 10          | 60             | 104         |
*/

/* 7. What is the successful delivery percentage for each runner? */
SELECT 
	cro.runner_id,
    COUNT(cro.cancellation) AS total_cancellations,
    COUNT(*) AS total_orders,
    CONCAT(100-100*COUNT(cro.cancellation)/COUNT(*),'%') AS successful_delivery_rate
FROM cro
GROUP BY cro.runner_id
ORDER BY cro.runner_id

/*
| runner_id | total_cancellations | total_orders | successful_delivery_rate |
| --------- | ------------------- | ------------ | ------------------------ |
| 1         | 0                   | 4            | 100%                     |
| 2         | 1                   | 4            | 75%                      |
| 3         | 1                   | 2            | 50%                      |
*/

