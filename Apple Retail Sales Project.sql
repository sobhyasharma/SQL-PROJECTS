use Apple_retailSales_Project
select * from category;
select * from products;
select * from stores;
select * from sales;
select * from warranty;

--check repair status in warranty
select distinct repair_status from warranty

--Total records in sales table
select count(*) from sales

--improving query performance

select * from sales
where product_id='P-44'; --ctr;+l
create index sales_productid on sales(product_id);--indexing improve the perforamance;
create index sales_storeid on sales(store_id); --when we run the query again, cpu time=156ms and elapsed time=413ms
create index sales_satedate on sales(sale_date);

SET STATISTICS TIME ON
SELECT *
FROM sales
where store_id='ST-31'
SET STATISTICS TIME OFF --execution time cpu=172ms, elapsed time= 279ms
--Business Problems
--Medium Problems
--Q1: Find the number of stores in each country.
select count(Store_ID) as store_count, Country from stores
group by Country
order by 1;

--Q2: Calculate the total number of units sold by each store.
select sum(quantity) as total_units, store_id
from sales
group by store_id
order by 1;

select stores.Store_ID, sum(sales.quantity) as total_units
from stores
join sales
on stores.Store_ID=sales.store_id
group by stores.Store_ID
order by 2;

--Q3: Identify how many sales occurred in December 2023.
select count(sale_id) as dec_sales from sales
where sale_date between '2023-12-01' and '2023-12-31'

select count(sale_id) as dec_sales from sales
where month(sale_date)=12 and year(sale_date)=2023

select count(sale_id) as dec_sales from sales
where sale_date>='2023-12-01' and sale_date<='2023-12-31'

--Q4: Determine how many stores have never had a warranty claim filed.

SELECT COUNT(Store_ID) AS stores_with_no_claims
FROM stores
WHERE Store_ID NOT IN (
   
    SELECT sa.store_id 
    FROM sales AS sa
    INNER JOIN warranty AS w ON sa.sale_id = w.sale_id
);

--Q5: Calculate the percentage of warranty claims marked as "Rejected".
select
cast(sum(case when repair_status='Rejected' then 1 else 0 end)*100.0/count(*) as Decimal(10,2) ) as rejected_per
from warranty

--Q6:Identify which store had the highest total units sold in the last year.
select top 1 st.Store_Name, sum(sa.quantity) as total_units
from stores as st
join sales as sa
on st.Store_ID=sa.store_id
where year(sa.sale_date)=2024
group by st.Store_Name
order by 2 desc;

--Q7: Count the number of unique products sold in the last year.
select count(distinct product_id) as unique_products from sales
where sale_date>='2024-01-01' and sale_date<='2024-12-31'

--Q8:Find the average price of products in each category.
select c.category_name, cast(avg(p.Price) as decimal(10,2)) as average_price
from category as c
inner join products as p
on c.category_id=p.Category_ID
group by c.category_name;

--Q9: How many warranty claims were filed in 2020?
select count(claim_id) claims_filed
from warranty
where claim_date>='2020-01-01' and claim_date<='2020-12-31';

--Q10: For each store, identify the best-selling day based on highest quantity sold.
with T as(select st.Store_name, sa.sale_date, sum(sa.quantity) as quantity_sold, 
DENSE_RANK() over (Partition by st.store_name order by sum(sa.quantity)desc ) as R
from stores as st
inner join sales as sa
on st.store_id=sa.store_id
group by st.Store_name, sa.sale_date)
select Store_name, sale_date, quantity_sold from T where R=1;

---MEDIUM to HARD

--Q11: Identify the least selling product in each country for each year based on total units sold.
with T1 as(select P.Product_Name, ST.Country, YEAR(SA.sale_date) as Year_, SUM(SA.quantity) as Total_units,
DENSE_RANK() OVER (PARTITION BY ST.Country, YEAR(SA.sale_date) ORDER BY SUM(SA.quantity)) as R
from products as P
inner join sales as SA
on P.Product_ID=SA.product_id
inner join stores as ST
on SA.store_id=ST.Store_ID
group by P.Product_Name, ST.Country, YEAR(SA.sale_date))
select Product_Name, Country, Year_, Total_Units from T1
Where R=1 

--Q12: Calculate how many warranty claims were filed within 180 days of a product sale.
select count(w.claim_id) claims
from warranty as w
inner join sales as s
on w.sale_id=s.sale_id
where datediff(day, s.sale_date,w.claim_date) between 0 and 180;

--Q13:Determine how many warranty claims were filed for products launched in the last two years.
select count(w.claim_id) claims
from warranty as w
inner join sales as s
on w.sale_id=s.sale_id
inner join products as p
on s.product_id=p.Product_ID
where YEAR(p.Launch_Date)>=
(select  year(max(Launch_Date))-1 from products)

--Q14: List the months in the last three years where sales exceeded 5,000 units in the USA.
select Year(sa.sale_date) as Year_, DateName(MONTH,sa.sale_date) as Months, SUM(sa.quantity) as Units
from sales as sa
join stores as st
on sa.store_id=st.Store_ID
where st.Country='United States' and Year(sa.sale_date)>=(select YEAR(MAX(sale_date))-2 from sales)
group by DateName(MONTH,sa.sale_date), Year(sa.sale_date)
having SUM(sa.quantity)>5000
order by 1,2

--Q15:Identify the product category with the most warranty claims filed in the last two years.
select top 1 ca.category_name, count(w.claim_id) as claims
from warranty as w
join sales as sa
on w.sale_id=sa.sale_id
join products as p
on sa.product_id=p.Product_ID
join category as ca
on p.Category_ID=ca.category_id
where year(w.claim_date)>=(select MAX(YEAR(claim_date))-1 from warranty)
group by ca.category_name
order by 2 desc;

-------------COMPLEX--------------------
--Q16: Determine the percentage chance of receiving warranty claims after each purchase for each country.

select CAST(COUNT(w.claim_id)*100.0/COUNT(DISTINCT sa.sale_id) AS decimal(10,2)) as claims, st.Country
from warranty as w
right join sales as sa
on w.sale_id=sa.sale_id
inner join stores as st
on sa.store_id=st.Store_ID
group by st.Country
order by 1 desc;

--Q17:Analyze the year-by-year growth ratio for each store.
with T2 as(select st.Store_Name, Year(sa.sale_date) as Y, SUM(sa.quantity) as totalunits,
LAG(SUM(sa.quantity)) OVER (PARTITION BY st.Store_Name ORDER BY Year(sa.sale_date)) as Previous_Year_Units
from stores as st
join sales as sa
on st.Store_ID=sa.store_id
group by st.Store_Name, Year(sa.sale_date))
select *, CAST((totalunits-Previous_Year_Units)*100.0/(Previous_Year_Units) as Decimal(10,2)) as growth_per from T2

--Q18: Calculate the correlation between product price and warranty claims for products sold in the last five years, 
--segmented by price range.

with T3 as(select
case 
when p.Price<500 then 'Low'
when p.Price<1500 then 'Medium'
else 'high'
end as Price_Range,
COUNT(DISTINCT s.sale_id) as sales, count(w.claim_id) as claims
from products as p join sales as s
on p.Product_ID=s.product_id
left join warranty as w
on s.sale_id=w.sale_id
where YEAR(s.sale_date)>=(SELECT MAX(YEAR(sale_date))-4 from sales)
group by case 
when p.Price<500 then 'Low'
when p.Price<1500 then 'Medium'
else 'high' end)

select Price_Range, sales, claims,
cast((claims*100.0)/(sales) as Decimal (10,2)) as claim_per from T3
order by 4;

--Q19:Identify the store with the highest percentage of "Completed" claims relative to total claims filed.

select top 1 st.Store_Name, 
cast(sum(case 
when w.repair_status='Completed' then 1 end)*100.0/count(w.claim_id) as decimal (10,2)) as completed_claim_per
from stores as st
join sales as sa
on st.Store_ID=sa.store_id
left join warranty as w
on sa.sale_id=w.sale_id
group by st.Store_Name
order by 2 desc;

--Q20:Write a query to calculate the monthly running total of sales for each store over the past four years 
--and compare trends during this period.
select * from stores
select * from sales

with T4 as(select 
st.Store_Name, 
YEAR(sa.sale_date) as year_,
MONTH(sa.sale_date) as m, 
DATENAME(MONTH,sa.sale_date) as month_, 
SUM(p.Price*sa.quantity) as monthly_sales
from stores as st
join sales as sa
on st.Store_ID=sa.store_id
join products as P
on sa.product_id=p.Product_ID
where year(sa.sale_date)>=(select MAX(YEAR(sale_date))-3 from sales)
group by st.Store_Name,YEAR(sa.sale_date), MONTH(sa.sale_date), DATENAME(MONTH,sa.sale_date))

select store_name, year_, month_, monthly_sales,
sum(monthly_sales) OVER (PARTITION BY store_name ORDER BY year_, m) as running_Total from T4
