WITH unifiedData AS (
  SELECT
      sales.customer_id AS customer_id,
      TO_CHAR(sales.order_date, 'yyyy-MM-dd') AS order_date,
      menu.product_name AS product_name,
      menu.price AS price,
      CASE
          WHEN sales.order_date >= members.join_date THEN 'Y'
          ELSE 'N'
      END member
  FROM dannys_diner.sales sales
  INNER JOIN dannys_diner.menu menu ON sales.product_id = menu.product_id
  LEFT JOIN dannys_diner.members members ON sales.customer_id = members.customer_id
  ORDER BY sales.customer_id, sales.order_date
), unifiedMembers AS (
  SELECT
      DISTINCT *,
      DENSE_RANK() OVER(PARTITION BY unified.customer_id ORDER BY unified.customer_id, unified.order_date) AS ranking
  FROM unifiedData unified
  WHERE unified.member = 'Y'
)

SELECT 
	unifiedData.*,
    unifiedMembers.ranking
FROM unifiedData
LEFT JOIN unifiedMembers ON 
	unifiedData.customer_ID = unifiedMembers.customer_ID
    AND unifiedData.order_Date = unifiedMembers.order_Date
    AND unifiedData.product_name = unifiedMembers.product_name

/*

| customer_id | order_date | product_name | price | member | ranking |
| ----------- | ---------- | ------------ | ----- | ------ | ------- |
| A           | 2021-01-01 | curry        | 15    | N      |         |
| A           | 2021-01-01 | sushi        | 10    | N      |         |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      |         |
| B           | 2021-01-02 | curry        | 15    | N      |         |
| B           | 2021-01-04 | sushi        | 10    | N      |         |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      |         |
| C           | 2021-01-01 | ramen        | 12    | N      |         |
| C           | 2021-01-07 | ramen        | 12    | N      |         |

*/
