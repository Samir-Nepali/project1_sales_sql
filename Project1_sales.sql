create database project1;
create table sales_store(
transaction_id varchar(15),
customer_id  varchar(15),
customer_name  varchar(30),
customer_age int,
gender  varchar(15),
product_id  varchar(15),
product_name  varchar(15),
product_categroy  varchar(15),
quantiy int,
prce float,
payment_mode  varchar(15),
purchase_date date,
time_of_purchase time,
status  varchar(15)
);
select * from sales_store;
set dateformat dmy;

bulk insert sales_store from 'C:\Users\samir\Downloads\sales.csv'
 with ( firstrow=2,
        fieldterminator=',',
		rowterminator='\n' );

--DATA CLEANING
select * into  sales from sales_store;
select * from sales;
--STEP 1 : TO CHECK DUPLICATE 
select transaction_id , count(*) from sales group by transaction_id having count(transaction_id)>1;
TXN240646
TXN342128	
TXN855235	
TXN981773	

with cte as (
select *, row_number() over (partition by transaction_id order by transaction_id) as row_num from sales)
select * from cte where row_num >1;

with cte as (
select *, row_number() over (partition by transaction_id order by transaction_id) as row_num from sales)
select * from cte where transaction_id in ( 'TXN240646' ,'TXN342128','TXN855235','TXN981773')

with cte as (
select *, row_number() over (partition by transaction_id order by transaction_id) as row_num from sales)
delete from cte where row_num=2;

--step 2 : correction of heading
exec sp_rename 'sales.quantiy','quantity','column';
exec sp_rename 'sales.prce','price','column';
exec sp_rename 'sales.product_categroy','product_category','column';

--step 3: to check datatype
select column_name, data_type from information_schema.columns where table_name='sales';

--step 4: to check null values
-- to check null count

declare @sql nvarchar(max)= '';
select @sql = string_agg(
     'select ''' + column_name + ''' as columnname,
     count(*) as nullcount
     from ' + quotename(table_schema) + '.sales
     where ' +quotename(column_name) +  ' is null ',
    ' union all '
)
within group (order by column_name)
from information_schema.columns
where table_name='sales';

--execute the dynamic sql
exec sp_executesql @sql;

--treating null values
select  * from sales where transaction_id is null 
or customer_id is null 
or customer_name is null
or customer_age is null
or gender is null
or product_id is null
or product_name is null
or product_categroy is null
or quantity is null
or payment_mode is null
or purchase_date is null
or time_of_purchase is null
or status is null
or price is null;

delete from sales where transaction_id is null;

select * from sales where  customer_name ='Ehsaan Ram';
update sales  set customer_id='CUST9494' where transaction_id='TXN977900';

select * from sales where  customer_name ='Damini Raju';
update sales  set customer_id='CUST1401' where transaction_id='TXN985663';

select * from sales where   customer_id='CUST1003';
update sales  set customer_name='Mahika Saini',customer_age=35,gender='Male' where transaction_id='TXN432798';

--step 5: data cleaning
select distinct gender from sales;
 update sales set gender='Male' where gender='M';
 update sales set gender='Female' where gender='F';

 select distinct payment_mode from sales;
 update sales set payment_mode='Credit Card' where payment_mode ='CC';

 --data analysis
 --1. what are the top 5 most selling products by quantity?
select top 5 product_name, sum(quantity) as total_quantity_sold from sales where status ='delivered' group by product_name
order by total_quantity_sold desc;

--business problem: we don't know which products are the most in demand.
--business impact : helps prioritize stock and boost sales through targeted promotions.

--2. which products are most frequently canceled?
select top 5 product_name , count(*) as total_cancelled from sales where status='cancelled'group by product_name 
order by 2 desc;

--business problem: frequent cancellation affect revenue and customer trust.
--business impact: identify poor-performing products to improve qualtiy or remove from catalog.

--3. what time of the day has the highest number of purchase?
select
case 
    when datepart( hour,time_of_purchase) between 0 and 5 then'Night'
	 when datepart( hour,time_of_purchase) between 6 and 11 then 'Morning'
		 when datepart( hour,time_of_purchase) between 12 and 17 then 'Afternoon'
		  when datepart( hour,time_of_purchase) between 18 and 23 then 'Evening'
    end as time_of_day,
	count(*) as total_order from sales
	group by 
	case
	when datepart( hour,time_of_purchase) between 0 and 5 then'Night'
	 when datepart( hour,time_of_purchase) between 6 and 11 then 'Morning'
		 when datepart( hour,time_of_purchase) between 12 and 17 then 'Afternoon'
		  when datepart( hour,time_of_purchase) between 18 and 23 then 'Evening'
		   end
		   order by 2 desc;

--business problem solved: find peak sales times.
--business impact; optimize staffing, promotions and server loads.

--4. who are the top 5 highest spending customers?
select top 5 customer_name, FORMAT(sum( price* quantity) , 'c0','en-in') as total_spend from sales group by customer_name
order by sum( price* quantity) desc;

-- business problem solved: identify vip customers.
--business impact: personalized offers, loyalty rewards and retention.

--5.which product categories generate the highest revenue?
select product_category, format(sum(price*quantity), 'c0','en-in') as revenue from sales group by product_category
order by sum(price*quantity) desc;

--business problem solved:identify top-performing product categories.
--business impact : refine product strategy, supply chain and promotions.
-- allowing the business to invest more in high margin or high demand categories.

--6. what is the return/cancel rate per product category?
--for cancellation
select product_category,format(count(case when status='cancelled' then 1 end)*100.0 / count(*),'n3')+' %' as cancelled_percentage
from sales group by product_category order by 2 desc;
--for cancellation
select product_category,format(count(case when status='returned' then 1 end)*100.0 / count(*),'n3')+' %' as returned_percentage
from sales group by product_category order by 2 desc;

--business problem solved:monitor dissatisfaction trends per category
--business impact: reduce returns, improve product descriptions/expections.
--helps identify and fix product or logistics issues.

--7. what is the most preferred payment mode?
select payment_mode, count(payment_mode) as total_count from sales group by payment_mode order by 2 desc;

--business problem solved: know which payment options customers prefer.
--business impact: streamline payment processing, prioritize popular modes.

--8. How does age group affect purchasing behavior?
select
case
    when customer_age between 18 and 25 then '18-25'
	when customer_age between 26 and 35 then '26-35'
	when customer_age between 35 and 50 then '35-50'
	else '51+'
	end as customer_age,
	format(sum(price*quantity),'c0','en-in') as total_purchase from sales 
	group by case
    when customer_age between 18 and 25 then '18-25'
	when customer_age between 26 and 35 then '26-35'
	when customer_age between 35 and 50 then '35-50'
	else '51+'
	end
	order by 2 desc;

	-- business  problem : understand customer demographics.
	--business impact: targeted marketing and product recommendations by age group.

--9. what is the monthly sales trend?
--method 1
select format(purchase_date,'yyyy-MM ') as month_year,
       format(sum(price*quantity),'c0','en-in' )as total_sales,
	   sum(quantity) as total_quantity
from sales 
group by format(purchase_date,'yyyy-MM');

--method 2
select year(purchase_date) as years,
month(purchase_date) as months,
format(sum(price*quantity),'c0','en-in') as total_sales,
sum(quantity) as total_quantity
from sales
group by year(purchase_date),month(purchase_date) order by months;

--business problem:sales fluctuatio go unnoticed.
--business impact: plan inventory and marketing according to seasonal trends.

--10. are certain genders buying more specific product categories?
select gender, product_category, count(product_category) as total_purchase
from sales group by gender, product_category order by gender;

select * from (select gender,product_category from sales) as source_table
pivot(count (gender) for gender in([Male],[Female])) as pivot_table order by product_category;

--business problem:gender_bsed product preferences
--business impact: personalized ads, gender-focused campaigns.