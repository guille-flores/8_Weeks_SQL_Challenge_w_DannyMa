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
