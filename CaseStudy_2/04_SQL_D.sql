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

/* 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees? */
SELECT 
	'$'|| SUM(CASE
    	WHEN pizza_id = '1' THEN 12
        WHEN pizza_id = '2' THEN 10
    END) total_revenue
FROM cco
INNER JOIN cro ON cco.order_id = cro.order_id
WHERE cancellation IS NULL

/*
| total_revenue |
| ------------- |
| $138          |
*/

/* 2. What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 extra */

SELECT
	SUM(total_pizza) + SUM(total_extra) AS profit_w_extra
FROM (
    SELECT
        rn,
        MAX(total_pizza) AS total_pizza,
        SUM(CASE
            WHEN extra_exp != 0 THEN 1
            ELSE 0
        END) AS total_extra
    FROM (
        SELECT 
            cco.order_id,
            pizza_id,
            ROW_NUMBER() OVER(ORDER BY cco.order_id) AS rn,
            CASE
                WHEN pizza_id = '1' THEN 12
                WHEN pizza_id = '2' THEN 10
            END total_pizza,
            UNNEST(
              STRING_TO_ARRAY(
                CASE
                    WHEN extras IS NULL THEN '0'
                    ELSE extras
                END, ','))::INTEGER AS extra_exp
        FROM cco
        INNER JOIN cro ON cco.order_id = cro.order_id
        WHERE cancellation IS NULL
    ) t1
    GROUP BY rn
) t2

/*
| profit_w_extra |
| -------------- |
| 142            |
*/

/* 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.*/
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "customer_id" INTEGER,
  "rating" INTEGER
);
INSERT INTO runner_ratings
  ("order_id", "customer_id", "runner_id", "rating")
VALUES
  ('1', '101', '1', '5'),
  ('2', '101', '1', '5'),
  ('3', '102', '1', '4'),
  ('4', '103', '2', '5'),
  ('5', '104', '3', '5'),
  ('7', '105', '2', '4'),
  ('8', '102', '2', '4'),
  ('10', '104', '1', '5');
  
  /* 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas*/
SELECT
	cco.customer_id,
    cco.order_id,
    cro.runner_id,
    rr.rating,
    cco.order_time,
    cro.pickup_time,
    cro.pickup_time-cco.order_time AS time_between_order_and_pickup,
    cro.duration AS delivery_duration,
    cro.distance/(cro.duration/60) AS avg_speed_kmh,
    COUNT(*) AS total_number_pizza
FROM cco
INNER JOIN cro ON cro.order_id = cco.order_id
LEFT JOIN pizza_runner.runner_ratings rr ON rr.runner_id = cro.runner_id AND cco.order_id = rr.order_id
WHERE cancellation IS NULL
GROUP BY 
	cco.customer_id,
    cco.order_id,
    cro.runner_id,
    rr.rating,
    cco.order_time,
    cro.pickup_time,
    cro.pickup_time-cco.order_time,
    cro.duration,
    cro.distance
ORDER BY order_id

/*
| customer_id | order_id | runner_id | rating | order_time               | pickup_time              | time_between_order_and_pickup | delivery_duration | avg_speed_kmh     | total_number_pizza |
| ----------- | -------- | --------- | ------ | ------------------------ | ------------------------ | ----------------------------- | ----------------- | ----------------- | ------------------ |
| 101         | 1        | 1         | 5      | 2020-01-01T18:05:02.000Z | 2020-01-01T18:15:34.000Z | [object Object]               | 32                | 37.5              | 1                  |
| 101         | 2        | 1         | 5      | 2020-01-01T19:00:52.000Z | 2020-01-01T19:10:54.000Z | [object Object]               | 27                | 44.44444444444444 | 1                  |
| 102         | 3        | 1         | 4      | 2020-01-02T23:51:23.000Z | 2020-01-03T00:12:37.000Z | [object Object]               | 20                | 40.2              | 2                  |
| 103         | 4        | 2         | 5      | 2020-01-04T13:23:46.000Z | 2020-01-04T13:53:03.000Z | [object Object]               | 40                | 35.1              | 3                  |
| 104         | 5        | 3         | 5      | 2020-01-08T21:00:29.000Z | 2020-01-08T21:10:57.000Z | [object Object]               | 15                | 40                | 1                  |
| 105         | 7        | 2         | 4      | 2020-01-08T21:20:29.000Z | 2020-01-08T21:30:45.000Z | [object Object]               | 25                | 60                | 1                  |
| 102         | 8        | 2         | 4      | 2020-01-09T23:54:33.000Z | 2020-01-10T00:15:02.000Z | [object Object]               | 15                | 93.6              | 1                  |
| 104         | 10       | 1         | 5      | 2020-01-11T18:34:49.000Z | 2020-01-11T18:50:20.000Z | [object Object]               | 10                | 60                | 2                  |
*/
