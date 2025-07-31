-- Data Cleaning:-

-- 1.Identify null and empty values across all tables
select * from customers;
select * from products;
select * from orders;
select * from orderdetails;
-- Result:-there is no null and empty values present in tables
 
-- 2.Remove duplicates across tables
-- check duplicates in all tables
select customer_id, count(*) from customers
group by customer_id
having count(*) > 1;
select order_id, count(*) from orders
group by order_id
having count(*) > 1;
-- Result:-There is no duplicate record in tables and orderdetails table can have duplicates record 
-- because same product can be added multiple times to one specific order

-- 3.Check Price discrepancies.   
-- a.Check Product price discrepency in products and order details tables
 select *
 from orderdetails od 
 join products p on od.product_id = p.product_id
 where od.price_per_unit != p.price; 
-- Result:-no price discrepency found
 
-- b.Check total amount discrepency in table orders and order details tables
with ctes as
(
select order_id, sum(quantity*price_per_unit) as total_order_amount
from orderdetails
group by order_id
)
select o.order_id, od.total_order_amount, o.total_amount
from orders o 
join ctes od on o.order_id = od.order_id
where o.total_amount != od.total_order_amount; 
-- Result:-No discrepancies found.

-- 4.Check datatypes of all columns for each table 
 desc customers;
 desc orders;
 desc products;
 desc orderdetails;
-- order_date is text, it should be in date format
-- Creating new table schema from orders table
 create table orders_replica like orders;
-- Altering data type of order_date column in new table as date
 alter table orders_replica
 modify column order_date date;
-- inserting data from old table to new table with converted order_date as date
 insert into orders_replica
 select order_id, str_to_date(order_date, '%Y-%m-%d'), customer_id, total_amount
 from orders;
 select * from orders;
 select * from orders_replica;
 desc orders_replica;
-- Dropping old table
 drop table if exists orders;
-- Rename the new table orders_replica as old table's name as orders
 alter table orders_replica
 rename to orders;
 
-- 5.Add relationship between tables by primary key and foreign key to inhance data integrity.
-- a.Add primary key constraint to customer_id in customers table
 alter table customers
 add constraint primary key(customer_id);
 desc customers;
 
-- b.Add primary key constraint to order_id in orders table 
-- and foreign key constraint to customer_id in orders table referencing to customer_id of Customers table 
 alter table orders
 add constraint primary key(order_id),
 add constraint foreign key(customer_id) references customers(customer_id);
 desc orders;
 
-- c.Add primary key constraint to product_id in products table
 desc products;
 alter table products
 add constraint primary key(product_id);
 
-- d.Add foreign key constraints to order_id and product_id that referencing to order_id in orders table and product_id in products table respectively.
 desc orderdetails;
 alter table orderdetails
 add constraint foreign key(order_id) references orders(order_id),
 add constraint foreign key(product_id) references products(product_id);

-- Exploratory Data Analysis
-- 1.Examine total sale and total quantity sold per product means get the popular products:-
-- Write a sql query to fetch total sale and total quantity sold for each product in descending order of toal sale and total quantity.
select p.product_id, p.name as product_name, sum(od.quantity) as total_quantity, sum(od.quantity*od.price_per_unit) as total_sales
from orderdetails od 
join products p on od.product_id = p.product_id
group by p.product_id, p.name
order by sum(od.quantity) desc, sum(od.quantity*od.price_per_unit) desc;
-- Insights:-
-- Most popular products is Digital SLR Camera 
   
-- 2. Examine customer purchase frequency:-
-- Write a sql query to fetch customer with number of order the placed(purchase frequency) and return data with descending order of purchase frequency
select c.customer_id, c.name, count(*) as purchase_frequency
from customers c 
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.name
order by count(*) desc;
-- Insight
-- Customer with id = 57 and name = Diya Upadhyay has highest purchase frequency

-- 3. Product category performance:-
-- Write a sql query to evaluate product category with total sales in descending order
-- Examine which product category hase highest sales performance
select p.category as Product_Category, sum(od.quantity*od.price_per_unit) as Total_Sales
from products p
join orderdetails od on p.product_id = od.product_id
group by p.category
order by sum(od.quantity*od.price_per_unit) desc;
-- Insights
-- Product category Electronics has highest sales performance, after that Photography and Wearable Tech have lower sales.

-- Detailed Analysis
-- A.Customer insights:-
-- 1. location with high density of customers 
-- Examine top 3 cities with highest number of customers to determine key markets for targeted marketing
-- and logistic optimization
select location as City, count(*) NumberOfCustomers from customers
group by location
order by count(*) desc
limit 3;
-- Insights
-- There are three cities named as Delhi, Chennai and Jaipur which have highest customer density 
-- so these three cities can be key markets for targeted marketing and logistic optimization.

-- 2.Engagement Depth Analysis:-
-- Determine the distribution of customers on the basis of number of orders they placed
-- One-time buyer=> customer with number of orders is 1
-- occasional customers=> customer with number of orders is between 2 and 4
-- regular customers=> customer with number of orders more than 4
select o.customer_id, c.name as customer_name, count(*) as number_of_orders,
		case
        when count(*) > 4 then 'Regular'
        when count(*) >= 2 then 'Occasional'
        when count(*) > 0 then 'One-time Buyer' 
        else 'None' end as CustomerSegment
from orders o 
join customers c on o.customer_id = c.customer_id
group by o.customer_id, c.name;
-- we can count frquency of customer on the basis of customer segment
with CustomerSegments as 
(
select o.customer_id, count(*) as number_of_orders,
		case
        when count(*) > 5 then 'Regular'
        when count(*) >= 2 then 'Occasional'
        when count(*) > 0 then 'One-time Buyer' 
        else 'None' end as CustomerSegment
from orders o 
join customers c on o.customer_id = c.customer_id
group by o.customer_id
)
select CustomerSegment, count(*) as numer_of_customers
from CustomerSegments
group by CustomerSegment
order by count(*) desc;
-- Insights:-
-- Customers are segmented as one-time buyer, occasional customer and regular customer on the basis of number of orders they placed
-- there is highest number of customers falls under occasional customer segment and then in one-time buyer segment
-- here occasional customers are more experiencing the comapny than other customer segment and occasional customers are suggested to tailored marketing strategies.

-- Product Insights:->
-- 1.Single purchase high-value products or premium products:-
-- Means average quantity per order is 1 but having high total revenue
select p.product_id, p.name as product_name, avg(od.quantity) as avg_quantity_per_order, sum(od.quantity*od.price_per_unit) as total_revenue
from orderdetails od
join products p on od.product_id = p.product_id
group by p.product_id, p.name
having avg(od.quantity) = 2
order by total_revenue desc;
-- Insights:-
-- here two products named as Smartphone 6" and Wireless Earbuds are to be considered 
-- as high-value product with low average quantity purchase and high sales values.

-- 2.Product-Category wise customer reach:-
-- Examine the customer distribution based on product category so that, it can help to understand which category
-- has wider appeal across the customers
-- determine number of unique customers purchasing from each product category.
select p.category as Product_Category, Count(distinct o.customer_id) as number_of_customers
from orderdetails od 
join orders o on od.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
join products p on od.product_id = p.product_id
group by p.category
order by number_of_customers desc;
-- Insights:-
-- Product category Electronics has highest number of unique customers, Hence It is suggested frequent restocking of products fall under Electronics category

 
-- Sales-Performance
-- 1. Sales trend analysis:-
-- Analyze the month-on-month percentage change in total sale to detemine growth trends
with monthly_sales as 
(
select date_format(order_date, '%Y-%m') as month, sum(total_amount) as Total_sales,
lag(sum(total_amount)) over(order by date_format(order_date, '%Y-%m')) as previous_month_sales
from orders
group by date_format(order_date, '%Y-%m')
order by date_format(order_date, '%Y-%m')
)
select  month, Total_sales, previous_month_sales,
round((Total_sales - previous_month_sales)*100/previous_month_sales, 2) as monthly_percentage_growth
from monthly_sales
 order by month;
-- Insights:-
-- Monthly percentage change is fluctuating over months
-- Monthly percentage change is at peak level in the month of july 2023
-- the total revenue is decreasing according to month-on-month cahnge
  
-- 2.Average order value fluctuation:-
-- Examine Average order value changes month-on-month 
select date_format(order_date, '%Y-%m') as Month, avg(total_amount) as MonthlyAverageOrderValue,
(avg(total_amount)- (lag(avg(total_amount)) over(order by date_format(order_date, '%Y-%m')))) as ChangeInOrderValue
from orders
group by date_format(order_date, '%Y-%m');
-- Insights:-
-- Change in average order value month-on-month indicates that there are decline in change in average order value form the month of 
-- July 2023, October 2023, January 2024 and February 2024. It is suggested to have upgrading pricing and promotional strategies 
-- to enhance order value for these months.


-- Inventory and Stock Optimization:-
-- Identify the products with fastest turnover rates means products with high sales frequency
-- calculate sales frequency for each products to get inventory refresh rate
select p.product_id, p.name as product_name, count(*) as sales_frequency
from orderdetails od
join products p on od.product_id = p.product_id
group by p.product_id, p.name
order by sales_frequency desc;
-- Insights:-
-- As per analysis, product with id = 7 and name as Digital SLR Camera is having highest sales frequency so this product has highest refresh rate.
-- It means above product has highest demand across customers
-- It is suggested that, company needs to have frequent restocking of above product.

-- Low engagement products:-
-- Determine products purchased by less than 5% of the customer base,
-- It's indicating potential mismatches between inventory and customer interest.
select p.product_id, p.name as product_name, round((count(distinct c.customer_id))*100/(select count(distinct customer_id) from customers), 2) as percent_engaged_customers
from orderdetails od 
join orders o on od.order_id = o.order_id
join products p on od.product_id = p.product_id
join customers c on o.customer_id = c.customer_id
group by p.product_id, p.name
order by percent_engaged_customers;
-- Insights:-
-- there is no low engagement product because every product is engaged with approx. 36%-47% of customers. 


-- Advance Data Analysis=>
-- Customer Acquisition Trends:-  
-- Examine the month-on-month trend of engagement of customers
-- so that company can evaluate the effectiveness of marketing campaign and market expansion efforts 
-- on the basis of number of new customers added on each month.
with CustomerWithFirstPurchaseMonth as 
(
select customer_id, date_format(min(order_date), '%Y-%m') as Month
from orders
group by customer_id
)
select Month, count(customer_id) as NewCustomerCount
from CustomerWithFirstPurchaseMonth 
group by Month
order by Month;
-- Insights:-
-- Effectiveness of marketing campaigns and market expansion are shown in the earlier months(march to August 2023) 
-- but in the later months(Nov 2023 to Feb 2024) need more strategic plans


-- Peak Sales Period Identification:-
-- Identify top 3 months with highest sales volume so, 
select date_format(order_date, '%Y-%m') as Month, sum(total_amount) as Total_sales
from orders 
group by date_format(order_date, '%Y-%m')
order by Total_sales desc 
limit 3;
-- Insights:-
-- Here are three months named as September, December and July having highest total sale, so in these months 
-- are shown as peak demand periods, It is suggested to manage stock levels, marketing efforts, staffing
-- in anticipation of peak demand in these months.

-- Loyalty Indicators:-
-- Write a SQL query that describes the duration between the first and the last purchase of the customer 
-- in that particular company to understand the loyalty of the customer.
-- wirte a sql query to return customers with duration of their first and last purchase to identify how loyal the customers are.
select c.customer_id, c.name, datediff(max(o.order_date), min(o.order_date)) as days_between_purchases
from customers c 
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.name
having datediff(max(o.order_date), min(o.order_date)) > 0
order by days_between_purchases desc;
-- Insights:-
-- customer with id 45 and name Hunar Rout is the most loyal customer.

