-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
  sales.customer_id AS Customer,
  SUM(menu.price) AS Total_Spent
FROM dannys_diner.sales sales
INNER JOIN dannys_diner.menu menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC

/*
| customer | total_spent |
| -------- | ----------- |
| A        | 76          |
| B        | 74          |
| C        | 36          |
*/

-- 2. How many days has each customer visited the restaurant?
SELECT 
  sales.customer_id AS Customer,
  COUNT(DISTINCT sales.order_date) AS Visits /* Multiple orders on same days shouldn't count, that's why we are using distincts dates*/
FROM dannys_diner.sales sales
GROUP BY sales.customer_id
ORDER BY sales.customer_id


/* 

| customer | visits |
| -------- | ------ |
| A        | 4      |
| B        | 6      |
| C        | 2      |

*/

-- 3. What was the first item from the menu purchased by each customer?

SELECT
	temp.Customer_ID,  
    temp.order_dates,
    temp.products
FROM (
  SELECT 
      sales.customer_id AS Customer_ID, 
      sales.order_date AS order_dates,
      STRING_AGG(menu.product_name, ', ') AS products, /*Concatenate the producst for each day and customer*/
  	  ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS row_num /*Get the row number by sorting it by date and partition over customer*/
  FROM dannys_diner.sales sales
  INNER JOIN dannys_diner.menu menu ON sales.product_id = menu.product_id
  GROUP BY sales.order_date, sales.customer_id /*Group by customer and date*/
) temp
WHERE row_num = 1 /*only get the 1st row=first order*/

/*

| customer_id | order_dates              | products     |
| ----------- | ------------------------ | ------------ |
| A           | 2021-01-01T00:00:00.000Z | sushi, curry |
| B           | 2021-01-01T00:00:00.000Z | curry        |
| C           | 2021-01-01T00:00:00.000Z | ramen, ramen |

*/



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH productsOrdered AS (
	SELECT
    	menu.product_name AS Product,
   		COUNT(*) AS TimesBought
	FROM dannys_diner.sales sales
	INNER JOIN dannys_diner.menu menu ON sales.product_id = menu.product_id
	GROUP BY menu.product_name
	ORDER BY TimesBought DESC)

SELECT 
	*
FROM productsOrdered
LIMIT 1

/*

| product | timesbought |
| ------- | ----------- |
| ramen   | 8           |

*/


-- 5. Which item was the most popular for each customer?
WITH productsOrdered AS (
  	SELECT 
  		t1.Customer_ID,
  		t1.Product,
  		t1.TimesBought,
  		MAX(t1.TimesBought) OVER(PARTITION BY t1.Customer_ID) AS mostPopular
  	FROM
      (SELECT
         sales.customer_id AS Customer_ID,
         menu.product_name AS Product,
         COUNT(*) AS TimesBought
       FROM dannys_diner.sales sales
       INNER JOIN dannys_diner.menu menu ON sales.product_id = menu.product_id
       GROUP BY sales.customer_id, menu.product_name
       ORDER BY TimesBought DESC) t1
), mostPopulars AS (
  SELECT 
    productsOrdered.Customer_ID,
  	productsOrdered.Product,
    productsOrdered.mostPopular
  FROM productsOrdered
  WHERE productsOrdered.TimesBought = productsOrdered.mostPopular
  )

SELECT
	mostPopulars.Customer_ID,
	STRING_AGG(mostPopulars.Product, ', ') AS Products,
    mostPopulars.mostPopular AS "Times Bought"
FROM mostPopulars
GROUP BY mostPopulars.Customer_ID, mostPopulars.mostPopular

/*

| customer_id | products            | Times Bought |
| ----------- | ------------------- | ------------ |
| A           | ramen               | 3            |
| B           | sushi, curry, ramen | 2            |
| C           | ramen               | 3            |

*/



-- 6. Which item was purchased first by the customer after they became a member?
WITH membersOrders AS (
	SELECT
	  sales.customer_id AS Customer_ID,
	  sales.order_date AS Order_Date,
	  menu.product_name AS Product,
	  members.join_date AS Join_Date
	FROM dannys_diner.sales sales
	INNER JOIN dannys_diner.menu menu ON sales.product_id = menu.product_id
	INNER JOIN dannys_diner.members members ON members.customer_id = sales.customer_id
	WHERE members.join_date < sales.order_date
), firsDateOrder AS (
  SELECT 
	membersOrders.Customer_ID,
    membersOrders.Order_Date,
    MIN(membersOrders.Order_Date) OVER(PARTITION BY membersOrders.Customer_ID) AS First_Order_Date,
    membersOrders.Product,
    membersOrders.Join_Date    
  FROM membersOrders
)

SELECT
	firsDateOrder.Customer_ID,
    firsDateOrder.First_Order_Date,
    firsDateOrder.Product,
    firsDateOrder.Join_Date
FROM firsDateOrder
WHERE firsDateOrder.Order_Date = firsDateOrder.First_Order_Date

/*

| customer_id | first_order_date         | product | join_date                |
| ----------- | ------------------------ | ------- | ------------------------ |
| A           | 2021-01-10T00:00:00.000Z | ramen   | 2021-01-07T00:00:00.000Z |
| B           | 2021-01-11T00:00:00.000Z | sushi   | 2021-01-09T00:00:00.000Z |

*/




-- 7. Which item was purchased just before the customer became a member?
WITH membersOrders AS (
	SELECT
	  sales.customer_id AS Customer_ID,
	  sales.order_date AS Order_Date,
	  menu.product_name AS Product,
	  members.join_date AS Join_Date
	FROM dannys_diner.sales sales
	INNER JOIN dannys_diner.menu menu ON sales.product_id = menu.product_id
	INNER JOIN dannys_diner.members members ON members.customer_id = sales.customer_id
	WHERE members.join_date > sales.order_date
), firsDateOrder AS (
  SELECT 
	membersOrders.Customer_ID,
    membersOrders.Order_Date,
    MAX(membersOrders.Order_Date) OVER(PARTITION BY membersOrders.Customer_ID) AS Ordered_B4_Joining,
    membersOrders.Product,
    membersOrders.Join_Date    
  FROM membersOrders
), ordersBeforeJoining AS (
	SELECT
      firsDateOrder.Customer_ID,
      firsDateOrder.Ordered_B4_Joining,
      firsDateOrder.Product,
      firsDateOrder.Join_Date
	FROM firsDateOrder
	WHERE firsDateOrder.Order_Date = firsDateOrder.Ordered_B4_Joining
)

SELECT
	ord.Customer_ID,
    to_char(MIN(ord.Ordered_B4_Joining), 'yyyy-MM-dd') AS "Order Date Before Joining",
	STRING_AGG(ord.Product, ', ') AS "Producst",
    to_char(MIN(ord.Join_Date), 'yyyy-MM-dd')  AS "Join Date"
FROM ordersBeforeJoining ord
GROUP BY ord.Customer_ID

/*

| customer_id | Order Date Before Joining | Producst     | Join Date  |
| ----------- | ------------------------- | ------------ | ---------- |
| A           | 2021-01-01                | sushi, curry | 2021-01-07 |
| B           | 2021-01-04                | sushi        | 2021-01-09 |

*/


-- 8. What is the total items and amount spent for each member before they became a member?
WITH membersOrders AS (
  SELECT
    sales.customer_id AS Customer_ID,
    menu.product_name AS Product,
    members.join_date AS Join_Date,
  	menu.price AS Price
  FROM dannys_diner.sales sales
  INNER JOIN dannys_diner.menu menu ON sales.product_id = menu.product_id
  INNER JOIN dannys_diner.members members ON members.customer_id = sales.customer_id
  WHERE members.join_date > sales.order_date
)

SELECT
	ord.Customer_ID,
	COUNT(ord.Product) AS Total_Items,
    SUM(ord.Price) AS Total
FROM membersOrders ord
GROUP BY ord.Customer_ID

/*

| customer_id | total_items | total |
| ----------- | ----------- | ----- |
| B           | 3           | 40    |
| A           | 2           | 25    |
*/


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
	s.customer_id,
	SUM(
		CASE
			WHEN m.product_name = 'sushi' THEN m.price*10*2
			ELSE m.price*10*1
		END
	) AS Total_Points
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id

/*
| customer_id | total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |
| C           | 360          |

*/


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH membersOrders AS (
  SELECT 
      s.customer_id AS customer_id,
      s.order_date AS order_date,
      m.product_name AS product,
      m.price As price,
      members.join_date AS joined
  FROM dannys_diner.sales s
  INNER JOIN dannys_diner.menu m ON m.product_id = s.product_id
  INNER JOIN  dannys_diner.members members ON members.customer_id = s.customer_id 
)

SELECT
	m.customer_id,
    SUM(
    	CASE
        	WHEN m.order_date >= m.joined AND m.order_date <= m.joined + interval '6 day' THEN m.price*2*10
      		WHEN m.product = 'sushi' THEN m.price*2*10
      		ELSE m.price*1*10
      	END
    ) AS Total_Points
FROM membersOrders m
WHERE m.order_date < '2021-02-01'
GROUP BY m.customer_id
ORDER BY m.customer_id

/*
| customer_id | total_points |
| ----------- | ------------ |
| A           | 1370         |
| B           | 820          |
*/



