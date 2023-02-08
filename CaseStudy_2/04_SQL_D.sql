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

