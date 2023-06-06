CREATE DATABASE Retail ;
--Data prep and Understanding
use Retail 
SELECT * FROM Customer
SELECT * FROM Transactions
SELECT * FROM prod_cat_info
--Q1 What is the total number of rows in each of the 3 tables in the database? 
  SELECT 'Transactions' as table_name, count(transaction_id) as count_records
  FROM Transactions as transaction_count
  UNION all
  SELECT 'customer' as table_name, count(customer_id)  as count_records
  FROM Customer as customer_count
  UNION all
  SELECT 'prod_cat_code' as table_name, count(prod_cat_code)  as count_records
  FROM prod_cat_info as prod_cat_count
  

--Q2 What is the total number of transactions that have a return?
SELECT count(*) as tot_return
FROM Transactions
WHERE CAST(total_amt as float) < 0

/* Q3 As you would have noticed, the dates provided across the datasets are not in a correct format.
      As first steps, pls convert the date variables into valid date formats before proceeding ahead.*/
SELECT *, CONVERT(date,tran_date,105)as convertdate
FROM Transactions


/* Q4 What is the time range of the transaction data available for analysis? Show the output in 
      number of days, months and years simultaneously in different columns.*/
SELECT 
max(CONVERT(date,tran_date,105)) as max_date, 
min(CONVERT(date,tran_date,105)) as min_date,
DATEDIFF(year, min(CONVERT(date,tran_date,105)), max(CONVERT(date,tran_date,105)) ) as diff_years,
DATEDIFF(MONTH, min(CONVERT(date,tran_date,105)), max(CONVERT(date,tran_date,105)) ) as diff_months,
DATEDIFF(DAY, min(CONVERT(date,tran_date,105)), max(CONVERT(date,tran_date,105)) ) as diff_days
FROM Transactions


--Q5 Which product category does the sub-category “DIY” belong to?
SELECT prod_cat
FROM prod_cat_info
WHERE prod_subcat = 'DIY'


--DATA ANALYSIS

--Q1 Which channel is most frequently used for transactions?
SELECT MAX(STORE_TYPE) AS frequently_used
FROM Transactions


--Q2 What is the count of Male and Female customers in the database?
SELECT 'male' as Gender, COUNT(GENDER) AS count_records from Customer  WHERE GENDER = 'M' 
UNION all
SELECT 'female' as Gender, COUNT(GENDER) AS count_records from Customer  WHERE GENDER = 'F'


--Q3 From which city do we have the maximum number of customers and how many?
SELECT TOP 1 city_code, count(customer_id) as counts
FROM Customer
GROUP BY city_code
ORDER BY counts desc 


--Q4 How many sub-categories are there under the Books category?
SELECT prod_subcat,prod_cat
FROM prod_cat_info
WHERE prod_cat = 'BOOKS'


--Q5 What is the maximum quantity of products ever ordered?
SELECT prod_cat ,MAX(cast(qty as int)) AS MAX_QTY
FROM prod_cat_info AS X
LEFT JOIN Transactions AS Y
ON X.prod_cat_code = Y.prod_cat_code
GROUP BY prod_cat



-- Q6 What is the net total revenue generated in categories Electronics and Books?
SELECT  x.prod_cat, sum(cast(total_amt as float)) as tot_revenue
FROM prod_cat_info AS X
LEFT JOIN Transactions AS Y
ON X.prod_cat_code = Y.prod_cat_code
WHERE prod_cat in ('electronics' , 'books')
GROUP BY prod_cat


--Q7 How many customers have >10 transactions with us, excluding returns?
SELECT customer_Id, COUNT(*) as transaction_count
FROM Customer AS X
LEFT JOIN Transactions AS Y
ON X.customer_Id = Y.cust_id
WHERE cast(total_amt as float) > 0
GROUP BY customer_Id
HAVING COUNT(*) > 10 
ORDER BY transaction_count


/* Q8 What is the combined revenue earned from the “Electronics” & 
  “Clothing” categories, from “Flagship stores”? */

SELECT sum(cast(total_amt as float)) combined_revenue
FROM prod_cat_info AS X
left JOIN Transactions AS Y
ON X.prod_cat_code = Y.prod_cat_code
WHERE prod_cat in ('electronics' , 'clothing')
and
Store_type = 'flagship store'


/* Q9 What is the total revenue generated from “Male” customers
      in “Electronics” category? Output should display total revenue by prod sub-cat.*/
SELECT prod_subcat_code , sum(cast(total_amt as float)) as tot_revenue
FROM Customer AS X
left join Transactions as y
on x.customer_Id = y.cust_id
WHERE gender = 'm'
and   prod_cat_code = 3
GROUP BY prod_subcat_code



/* Q10 What is percentage of sales and returns by product sub category; display only top 5
       sub categories in terms of sales*/
SELECT top 5 b.prod_subcat, percent_sale,percent_return FROM
(select prod_subcat,
sum(convert(numeric,total_amt))*100/sum(sum(convert(numeric,total_amt)))over()as percent_sale
FROM prod_cat_info
left join Transactions
on prod_cat_info.prod_cat_code = Transactions.prod_cat_code
WHERE convert(numeric,qty)>0
GROUP BY prod_subcat) as b

left join

(SELECT prod_subcat,
sum(convert(numeric,total_amt))*100/sum(sum(convert(numeric,total_amt)))over()as percent_return
FROM prod_cat_info
left join Transactions
on prod_cat_info.prod_cat_code = Transactions.prod_cat_code
WHERE convert(numeric,qty)<0
GROUP BY prod_subcat )as o
on b.prod_subcat = o.prod_subcat
ORDER BY percent_sale desc



/* Q11 For all customers aged between 25 to 35 years find what is the net total revenue generated
       by these consumers in last 30 days of transactions from max transaction date available in the data?*/

SELECT cust_id , sum(cast(total_amt as float)) as revenue
FROM Transactions
WHERE cust_id in 
(select customer_id from Customer
WHERE datediff(year,convert(date,dob,105),GETDATE())between 25 and 35) 
and convert (date,tran_date,105)
between dateadd (day,-30 , (select max(convert (date, tran_date , 105)) from Transactions))
and (select max (convert (date, tran_date , 105)) FROM Transactions) --and tran_date between 30 days before max tran_date and max tran_date 
GROUP BY cust_id 


--Q12 Which product category has seen the max value of returns in the last 3 months of transactions?
SELECT top 1 
prod_cat , sum(cast(total_amt as float)) as total FROM Transactions as x
left join prod_cat_info as y 
on x.prod_cat_code = y.prod_cat_code
WHERE cast(total_amt as float) < 0 and
 convert (date,tran_date,105)
between dateadd (month,-3 , (select max(convert (date, tran_date , 105)) from Transactions))
and (select max (convert (date, tran_date , 105)) FROM Transactions)  --and tran_date between 3 months before max tran_date and max tran_date
GROUP BY prod_cat
ORDER BY 2 desc


--Q13 Which store-type sells the maximum products; by value of sales amount and by quantity sold?
SELECT TOP 1 Store_type
FROM
(
SELECT Store_type, SUM(CAST(QTY AS numeric)) AS CNT_QTY,
SUM(cast(total_amt as float)) AS CNT_AMT
FROM Transactions AS X
LEFT JOIN prod_cat_info AS Y
ON X.prod_cat_code = Y.prod_cat_code
GROUP BY Store_type
)AS X
ORDER BY CNT_AMT DESC , 
CNT_QTY DESC

--Q14 What are the categories for which average revenue is above the overall average.
SELECT prod_cat , AVG(cast(total_amt as float)) AS AVG_AMT
FROM Transactions AS X
LEFT JOIN prod_cat_info AS Y
ON X.prod_cat_code = Y.prod_cat_code
GROUP BY prod_cat
HAVING avg(cast(total_amt as float)) > (select AVG(cast(total_amt as float)) from Transactions)


/* Q15 Find the average and total revenue by each subcategory for the categories 
       which are among top 5 categories in terms of quantity sold.*/
SELECT TOP 5 *
FROM
(
SELECT prod_cat, prod_subcat,
SUM(cast(total_amt as float)) AS TOT_REVENUE,
AVG(cast(total_amt as float)) AS AVG_REVENUE,
SUM(CAST(QTY AS numeric)) AS TOT_QUANTITY
FROM Transactions AS X
LEFT JOIN prod_cat_info AS Y
ON X.prod_cat_code = Y.prod_cat_code
GROUP BY prod_cat, prod_subcat
) AS X
ORDER BY TOT_QUANTITY DESC


