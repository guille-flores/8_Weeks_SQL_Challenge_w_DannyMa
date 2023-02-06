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

/* 1. What are the standard ingredients for each pizza?*/
SELECT 
	r.pizza_id,
    n.pizza_name,
    STRING_AGG(r.recipe_top_id::varchar, ', ') AS toppings_id,
    STRING_AGG(t.topping_name, ', ') AS toppings_name 
FROM (
  SELECT 
      r1.pizza_id,
      UNNEST(STRING_TO_ARRAY(r1.toppings, ', '))::INTEGER AS recipe_top_id
  FROM pizza_runner.pizza_recipes r1) r
INNER JOIN pizza_runner.pizza_toppings t ON t.topping_id = r.recipe_top_id
INNER JOIN pizza_runner.pizza_names n ON n.pizza_id = r.pizza_id
GROUP BY r.pizza_id, n.pizza_name
/*
| pizza_id | pizza_name | toppings_id             | toppings_name                                                         |
| -------- | ---------- | ----------------------- | --------------------------------------------------------------------- |
| 1        | Meatlovers | 2, 8, 4, 10, 5, 1, 6, 3 | BBQ Sauce, Pepperoni, Cheese, Salami, Chicken, Bacon, Mushrooms, Beef |
| 2        | Vegetarian | 12, 4, 6, 7, 9, 11      | Tomato Sauce, Cheese, Mushrooms, Onions, Peppers, Tomatoes            |
*/

/* 2. What was the most commonly added extra?*/
SELECT
    toppings.topping_name,
    ext.total_requested
FROM (
  SELECT 
    UNNEST(STRING_TO_ARRAY(cco.extras, ','))::INTEGER AS extras_id,
    COUNT(*) AS total_requested
  FROM cco
  WHERE cco.extras IS NOT NULL
  GROUP BY extras_id) ext
INNER JOIN pizza_runner.pizza_toppings toppings ON ext.extras_id = toppings.topping_id
/* Bacon was the most commonly added extra.
| extra_topping_name | total_requested |
| ------------------ | --------------- |
| Bacon              | 4               |
| Cheese.            | 1               |
| Chicken            | 1               |
*/

/* 3. What was the most common exclusion? */
SELECT
    toppings.topping_name,
    exc.total_excluded
FROM (
  SELECT 
    UNNEST(STRING_TO_ARRAY(cco.exclusions, ','))::INTEGER AS exc_id,
    COUNT(*) AS total_excluded
  FROM cco
  WHERE cco.exclusions IS NOT NULL
  GROUP BY exc_id) exc
INNER JOIN pizza_runner.pizza_toppings toppings ON exc.exc_id = toppings.topping_id
ORDER BY exc.total_excluded DESC

/* Cheese was the most commonly excluded topping
| topping_name | total_excluded |
| ------------ | -------------- |
| Cheese       | 4              |
| BBQ Sauce    | 1              |
| Mushrooms    | 1              |
*/

/* 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers 
*/
SELECT 
	order_id, 
    pizza_name || 
    CASE 
    	WHEN exclusions IS NOT NULL THEN ' - Exclude ' || 
        	REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                 REGEXP_REPLACE(
                   REGEXP_REPLACE(  
                     REGEXP_REPLACE(
                       REGEXP_REPLACE(
                         REGEXP_REPLACE(   
                            REGEXP_REPLACE(
                              REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                  REGEXP_REPLACE(exclusions, '1', 'Bacon')
                                ,'2', 'BBQ Sauce')
                              , '3', 'Beef')
                            , '4', 'Cheese') 
                          , '5', 'Chicken')
                        , '6', 'Mushrooms') 
                      , '7', 'Onions') 
                    , '8', 'Pepperoni') 
                  , '9', 'Peppers')
            	, '10', 'Salami')
              , '11', 'Tomatoes')
            , '12', 'Tomato Sauce')     
    	ELSE ''
    END 
    ||
    CASE 
    	WHEN extras IS NOT NULL THEN ' - Extra ' || 
        	REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                 REGEXP_REPLACE(
                   REGEXP_REPLACE(  
                     REGEXP_REPLACE(
                       REGEXP_REPLACE(
                         REGEXP_REPLACE(   
                            REGEXP_REPLACE(
                              REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                  REGEXP_REPLACE(extras, '1', 'Bacon')
                                ,'2', 'BBQ Sauce')
                              , '3', 'Beef')
                            , '4', 'Cheese') 
                          , '5', 'Chicken')
                        , '6', 'Mushrooms') 
                      , '7', 'Onions') 
                    , '8', 'Pepperoni') 
                  , '9', 'Peppers')
            	, '10', 'Salami')
              , '11', 'Tomatoes')
            , '12', 'Tomato Sauce')     
    	ELSE ''
    END pizza_order_reformat
FROM cco
INNER JOIN pizza_runner.pizza_names p on p.pizza_id = cco.pizza_id
ORDER BY order_id
/*
| order_id | pizza_order_reformat_ii                                         |
| -------- | --------------------------------------------------------------- |
| 1        | Meatlovers                                                      |
| 2        | Meatlovers                                                      |
| 3        | Meatlovers                                                      |
| 3        | Vegetarian                                                      |
| 4        | Vegetarian - Exclude Cheese                                     |
| 4        | Meatlovers - Exclude Cheese                                     |
| 4        | Meatlovers - Exclude Cheese                                     |
| 5        | Meatlovers - Extra Bacon                                        |
| 6        | Vegetarian                                                      |
| 7        | Vegetarian - Extra Bacon                                        |
| 8        | Meatlovers                                                      |
| 9        | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
| 10       | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |
| 10       | Meatlovers                                                      |
*/

/* 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
*/

SELECT
  order_id,
  order_row,
  pizza_name,
    CASE
      WHEN POSITION(t.topping_name IN wo_exc) > 0 THEN REGEXP_REPLACE(wo_exc, t.topping_name, '2x'||t.topping_name)
      ELSE wo_exc
    END new_recipe
FROM (

  SELECT
    order_id,
    order_row,
    pizza_name,
    CASE
      WHEN POSITION(t.topping_name IN tt1.topping_name) > 0 THEN REGEXP_REPLACE(tt1.topping_name, t.topping_name, '')
      ELSE tt1.topping_name
    END wo_exc,
    exp_extras
  FROM (
    SELECT
        corank.order_id,
        corank.order_row,
        corank.pizza_id,
        pizza_name,
        STRING_AGG(exp_toppings::VARCHAR, ', ') AS exp_toppings,
        STRING_AGG(topping_name, ', ') AS topping_name,
        UNNEST(exclusions) AS exc_exp,
        UNNEST(extras) AS exp_extras
    FROM (
      SELECT 
          re.pizza_id AS pizza_id,
          pizza_name,
          UNNEST(STRING_TO_ARRAY(toppings, ', '))::INTEGER AS exp_toppings
      FROM pizza_runner.pizza_recipes re
      INNER JOIN pizza_runner.pizza_names pz ON pz.pizza_id = re.pizza_id
    ) exp_t1
    INNER JOIN pizza_runner.pizza_toppings t ON t.topping_id = exp_t1.exp_toppings
    INNER JOIN (
      SELECT
        order_id,
        customer_id,
        pizza_id,
        ROW_NUMBER() OVER(ORDER BY order_id ASC) AS order_row,
        STRING_TO_ARRAY(
          CASE
            WHEN exclusions IS NULL THEN 'NULL'
            ELSE exclusions
          END, 
          ', ') AS exclusions,
        STRING_TO_ARRAY(
            CASE
              WHEN extras IS NULL THEN 'NULL'
              ELSE extras
            END, 
            ', ') AS extras	
      FROM cco
    ) corank ON corank.pizza_id = exp_t1.pizza_id
    GROUP BY corank.order_id, corank.order_row, corank.pizza_id, pizza_name, exclusions, extras
    ) tt1
  LEFT JOIN pizza_runner.pizza_toppings t ON t.topping_id::VARCHAR = exc_exp
) temp1
LEFT JOIN pizza_runner.pizza_toppings t ON t.topping_id::VARCHAR = exp_extras
ORDER BY order_id, order_row


