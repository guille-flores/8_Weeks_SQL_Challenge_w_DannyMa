WITH cco AS (
  SELECT 
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
  
