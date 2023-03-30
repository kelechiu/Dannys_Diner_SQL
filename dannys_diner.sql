 -- Danny's Diner--

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(p.price) AS sales
FROM dbo.sales s
JOIN dbo.menu p
ON s.product_id= p.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS days
FROM dbo.sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH Rank_CTE AS (
    SELECT 
    s.customer_id, 
    s.order_date,
    p.product_name, 
        DENSE_RANK () OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS Rank -- rank by order date for each customer
    FROM dbo.sales s
    JOIN dbo.menu p
    ON s.product_id = p.product_id
)
SELECT
 Rank_CTE.customer_id, 
 Rank_CTE.product_name,
 Rank_CTE.order_date,
 Rank
FROM Rank_CTE   
WHERE Rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
TOP 1(COUNT(s.product_id)) AS purchase_num,
m.product_name
FROM dbo.sales s
JOIN dbo.menu m
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY purchase_num DESC;

-- 5. Which item was the most popular for each customer?
WITH fav_cte AS
(
	SELECT 
    s.customer_id, 
    m.product_name AS fav_product, 
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) DESC) AS rank
FROM dbo.sales AS s
JOIN dbo.menu AS m
	ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)

SELECT 
  fav_cte.customer_id, 
  fav_cte.fav_product 
FROM fav_cte 
WHERE rank = 1;

--6.Which item was purchased first by the customer after they became a member?

WITH rank_cte AS (
  SELECT
    s.customer_id,
    s.order_date,
    r.join_date,
    m.product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
  FROM dbo.members r
  JOIN dbo.sales s
  ON r.customer_id = s.customer_id
  JOIN dbo.menu m
  ON s.product_id = m.product_id
  WHERE order_date >= join_date
)
SELECT
  rank_cte.customer_id,
  rank_cte.join_date,
  rank_cte.order_date,
  rank_cte.product_name,
  rank
FROM rank_cte
WHERE rank = 1;

--7. Which item was purchased just before the customer became a member?
WITH rank_cte AS(
  SELECT
    s.customer_id,
    s.order_date,
    r.join_date,
    m.product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank
  FROM dbo.members r
  JOIN dbo.sales s
  ON r.customer_id = s.customer_id
  JOIN dbo.menu m
  ON s.product_id = m.product_id
  WHERE s.order_date < r.join_date
)
SELECT
  rank_cte.customer_id,
  rank_cte.order_date,
  rank_cte.join_date,
  rank_cte.product_name
  FROM rank_cte
  WHERE rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH before_cte AS(
  SELECT
    s.customer_id,
    r.join_date,
    COUNT(s.product_id) AS total_items,
    SUM(m.price) AS total_spent 
  FROM 
  dbo.members r
  JOIN dbo.sales s
  ON r.customer_id = s.customer_id
  JOIN dbo.menu m 
  ON s.product_id = m.product_id
  WHERE s.order_date < r.join_date
  GROUP BY s.customer_id, r.join_date
)
SELECT 
  before_cte.customer_id,
  before_cte.total_items,
  before_cte.total_spent
  FROM before_cte;


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
  s.customer_id,
  COUNT(s.product_id) AS total_items,
  SUM(m.price) AS total_sales
  FROM dbo.members r
  JOIN dbo.sales s
  ON r.customer_id = s.customer_id
  JOIN dbo.menu m
  ON s.product_id = m.product_id
  WHERE s.order_date < r.join_date  -- valid order dates before customers became members
  GROUP BY s.customer_id;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH points_cte AS 
(
  SELECT *,
    CASE 
      WHEN product_name IN ('curry', 'ramen') THEN price * 10
      ELSE price * 20
    END AS points
  FROM dbo.menu m
)
SELECT 
  s.customer_id,
  SUM(p.price) AS total_spent,
  SUM(p.points) AS total_points
FROM 
dbo.sales s
JOIN points_cte p
  ON s.product_id = p.product_id
GROUP BY s.customer_id;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH date_cte AS
(
  SELECT *,
  DATEADD (Day, 6, join_date) AS valid_date, -- adds 6 days to the join date to make it 1 week
  EOMONTH ('2021-01-31') AS month_end
  FROM dbo.members
)

  SELECT 
    s.customer_id,
    d.join_date,
    d.valid_date,
    SUM(m.price) AS total_spent,
    SUM(CASE 
      WHEN s.order_date <= d.valid_date THEN (2 * 10 * m.price)
      ELSE 10 * m.price
      END) AS points

  FROM date_cte d
  JOIN dbo.sales s
  ON d.customer_id = s.customer_id
  JOIN dbo.menu m
  ON s.product_id = m.product_id
  WHERE s.order_date < d.month_end
  GROUP BY s.customer_id, d.join_date, d.valid_date;






