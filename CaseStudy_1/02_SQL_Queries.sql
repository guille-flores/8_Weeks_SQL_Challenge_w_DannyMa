-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
  sales.customer_id AS Customer,
  SUM(menu.price) AS Total_Spent
FROM dannys_diner.sales sales
INNER JOIN dannys_diner.menu ON sales.product_id = menu.product_id
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
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
