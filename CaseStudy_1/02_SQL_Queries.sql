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
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
