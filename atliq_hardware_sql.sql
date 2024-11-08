-- main schema 
use gdb0041;
select * from dim_customer;
select * from fact_gross_price;
select * from fact_sales_monthly;
select * from fact_sales_monthly;
select * from dim_product;
select * from dim_customer;
select * from fact_pre_invoice_deductions;
select * from fact_post_invoice_deductions;

-- Finance Analytics

-- customer codes for Croma india
	SELECT * FROM dim_customer WHERE customer like "%croma%" AND market="india";
    
-- Geting all the sales transaction data from fact_sales_monthly table for Croma(croma: 90002002) in the fiscal_year 2021
	SELECT * FROM fact_sales_monthly 
	WHERE 
            customer_code=90002002 AND
            YEAR(DATE_ADD(date, INTERVAL 4 MONTH))=2021 
	ORDER BY date asc
	LIMIT 100000;
    
    -- by using user defined function get_fiscal_year
    SELECT * FROM fact_sales_monthly 
	WHERE 
            customer_code=90002002 AND
            get_fiscal_year(date)=2021 
	ORDER BY date asc
	LIMIT 100000;
    
-- Gross Sales Report: Monthly Product Transactions

-- Performing joins to pull product information
	SELECT s.date, s.product_code, p.product, p.variant, s.sold_quantity 
	FROM fact_sales_monthly s
	JOIN dim_product p
        ON s.product_code=p.product_code
	WHERE 
            customer_code=90002002 AND 
    	    get_fiscal_year(date)=2021     
	LIMIT 1000000;

-- Performing join with 'fact_gross_price' table with the above query and generating required fields
	SELECT 
    	    s.date, 
            s.product_code, 
            p.product, 
            p.variant, 
            s.sold_quantity, 
            g.gross_price,
            ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total
	FROM fact_sales_monthly s
	JOIN dim_product p
            ON s.product_code=p.product_code
	JOIN fact_gross_price g
            ON g.fiscal_year=get_fiscal_year(s.date)
    	AND g.product_code=s.product_code
	WHERE 
    	    customer_code=90002002 AND 
            get_fiscal_year(s.date)=2021     
	LIMIT 1000000;


-- Gross Sales Report: Total Sales Amount

-- yearly gross sales report for Croma India for all the years
	SELECT 
            get_fiscal_year(s.date), 
    	    SUM(ROUND(s.sold_quantity*g.gross_price,2)) as total_sales
	FROM fact_sales_monthly s
	JOIN fact_gross_price g
        ON g.fiscal_year=get_fiscal_year(s.date) AND g.product_code=s.product_code
	WHERE 
             customer_code=90002002
	GROUP BY get_fiscal_year(s.date);
    
-- a report containing date, product_code,product,variant,sold_quantity,gross_price,gross_price_total
select s.date,
s.product_code,
p.product,
p.variant,
s.sold_quantity as sold_quantity,
g.gross_price, 
round((g.gross_price*s.sold_quantity),2) as gross_price_total 
from fact_sales_monthly s
join fact_gross_price g
on s.product_code=g.product_code and get_fiscal_year(s.date)=g.fiscal_year
join dim_product p
on s.product_code=p.product_code
join fact_pre_invoice_deductions pi
on pi.customer_code=s.customer_code and get_fiscal_year(s.date)=pi.fiscal_year;

-- monthly gross sales report for all the years
	SELECT 
            s.date, 
    	    SUM(ROUND(s.sold_quantity*g.gross_price,2)) as monthly_sales
	FROM fact_sales_monthly s
	JOIN fact_gross_price g
        ON g.fiscal_year=get_fiscal_year(s.date) AND g.product_code=s.product_code
	GROUP BY date;
    

-- joining fact_sales_monthly,fact_gross_price,dim_product,fact_pre_invoice_deduction to get a cpmprehensive report for 2021
select s.date,s.product_code,p.segment,p.category,p.product,p.variant,round((g.gross_price*s.sold_quantity),2) as total_gross_price,pi.pre_invoice_discount_pct,
round(pi.pre_invoice_discount_pct*(g.gross_price*s.sold_quantity),2) as pre_invoice_discount_amount,
(round((g.gross_price*s.sold_quantity),2) - round(pi.pre_invoice_discount_pct*(g.gross_price*s.sold_quantity),2)) net_invoice_sales 
from fact_sales_monthly s
join fact_gross_price g
on s.product_code=g.product_code and get_fiscal_year(s.date)=g.fiscal_year
join dim_product p
on s.product_code=p.product_code
join fact_pre_invoice_deductions pi
on pi.customer_code=s.customer_code and get_fiscal_year(s.date)=pi.fiscal_year
where get_fiscal_year(s.date)= 2021;

-- using dim_date table
select s.date,s.product_code,p.segment,p.category,p.product,p.variant,round((g.gross_price*s.sold_quantity),2) as total_gross_price,pi.pre_invoice_discount_pct,
round(pi.pre_invoice_discount_pct*(g.gross_price*s.sold_quantity),2) as pre_invoice_discount_amount,
(round((g.gross_price*s.sold_quantity),2) - round(pi.pre_invoice_discount_pct*(g.gross_price*s.sold_quantity),2)) net_invoice_sales 
from fact_sales_monthly s
join dim_date d
on d.calendar_date=s.date
join fact_gross_price g
on s.product_code=g.product_code and d.fiscal_year=g.fiscal_year
join dim_product p
on s.product_code=p.product_code
join fact_pre_invoice_deductions pi
on pi.customer_code=s.customer_code and d.fiscal_year=pi.fiscal_year
where d.fiscal_year= 2021;


-- using added fiscal_year in fact_sales_monthly
select s.date,s.product_code,p.segment,p.category,p.product,p.variant,round((g.gross_price*s.sold_quantity),2) as total_gross_price,pi.pre_invoice_discount_pct,
round(pi.pre_invoice_discount_pct*(g.gross_price*s.sold_quantity),2) as pre_invoice_discount_amount,
(round((g.gross_price*s.sold_quantity),2) - round(pi.pre_invoice_discount_pct*(g.gross_price*s.sold_quantity),2)) net_invoice_sales 
from fact_sales_monthly s
join fact_gross_price g
on s.product_code=g.product_code and s.fiscal_year=g.fiscal_year
join dim_product p
on s.product_code=p.product_code
join fact_pre_invoice_deductions pi
on pi.customer_code=s.customer_code and s.fiscal_year=pi.fiscal_year
where s.fiscal_year= 2021;

-- using added fiscal_year in fact_sales_monthly (using CTE)
WITH calc AS(
select s.date date,s.product_code product_code,p.segment segement,
p.category category,p.product product,p.variant variant,
s.sold_quantity sold_quantity,g.gross_price gross_price_per_item,
round((g.gross_price*s.sold_quantity),2) as total_gross_price,pi.pre_invoice_discount_pct,
round(pi.pre_invoice_discount_pct*(g.gross_price*s.sold_quantity),2) as pre_invoice_discount_amount
from fact_sales_monthly s
join fact_gross_price g
on s.product_code=g.product_code and s.fiscal_year=g.fiscal_year
join dim_product p
on s.product_code=p.product_code
join fact_pre_invoice_deductions pi
on pi.customer_code=s.customer_code and s.fiscal_year=pi.fiscal_year
where s.fiscal_year= 2021)
SELECT category, product, variant,sold_quantity, gross_price_per_item,
total_gross_price,pre_invoice_discount_pct,
pre_invoice_discount_amount,
(total_gross_price - pre_invoice_discount_amount) as net_invoice_sales FROM calc ;


-- creating view 'pre_invoice' 
-- using added fiscal_year in fact_sales_monthly (using CTE)
CREATE VIEW pre_invoice AS
select s.date date,s.fiscal_year fiscal_year,c.market market,c.customer_code,c.customer customer,s.product_code product_code,p.segment segement,
p.category category,p.product product,p.variant variant,
s.sold_quantity sold_quantity,g.gross_price gross_price_per_item,
round((g.gross_price*s.sold_quantity),2) as total_gross_price,
pi.pre_invoice_discount_pct pre_invoice_discout_pct,
round(pi.pre_invoice_discount_pct*(g.gross_price*s.sold_quantity),2) as pre_invoice_discount_amount,
round((1-pi.pre_invoice_discount_pct)*(g.gross_price*s.sold_quantity),2) net_invoice_sale
from fact_sales_monthly s
join fact_gross_price g
on s.product_code=g.product_code and s.fiscal_year=g.fiscal_year
join dim_product p
on s.product_code=p.product_code
join fact_pre_invoice_deductions pi
on pi.customer_code=s.customer_code and s.fiscal_year=pi.fiscal_year
join dim_customer c on
s.customer_code=c.customer_code;

select * from pre_invoice;


-- SELECT category, product, variant,sold_quantity, gross_price_per_item,
-- total_gross_price,pre_invoice_discount_pct,
-- pre_invoice_discount_amount,
-- (total_gross_price - pre_invoice_discount_amount) as net_invoice_sales FROM calc ;
-- select *,(total_gross_price - pre_invoice_discount_amount) as net_invoice_sales,(total_gross_price - (pre_invoice_discount_amount+post_invoice_discount_amount)) as net_sales_amount FROM sales; 



-- creating view post invoice
CREATE VIEW post_invoice AS
select p.date,p.fiscal_year,p.market,p.product_code,
pi.customer_code,p.customer customer,
p.segement,
p.category,p.product,p.variant,
p.sold_quantity,p.gross_price_per_item,
p.total_gross_price,
p.pre_invoice_discout_pct,
p.pre_invoice_discount_amount,
p.net_invoice_sale,
pi.discounts_pct,
round((1-pi.discounts_pct)*p.net_invoice_sale,2) net_sales_amount
from pre_invoice p
join fact_post_invoice_deductions pi
on p.product_code=pi.product_code and p.date=pi.date and p.customer_code=pi.customer_code;



SELECT * FROM post_invoice;
 -- Top 5 markets by net_sales
 SELECT market, round(SUM(net_sales_amount)/1000000,2) net_sales_amount
 FROM post_invoice
 GROUP BY market
 ORDER BY SUM(net_sales_amount) DESC
 LIMIT 5;
 
-- creating view 'gross sales'
CREATE VIEW gross_sales as
select s.date date,s.fiscal_year as fiscal_year,s.customer_code customer_code,c.customer as customer,c.market as market,
s.product_code product_code,p.product,p.variant variant,s.sold_quantity sold_quantity,g.gross_price gross_price_per_item,
round((g.gross_price*s.sold_quantity),2) as gross_price_total
from fact_sales_monthly s
join fact_gross_price g
on s.product_code=g.product_code and s.fiscal_year=g.fiscal_year
join dim_product p
on s.product_code=p.product_code
join fact_pre_invoice_deductions pi
on pi.customer_code=s.customer_code and s.fiscal_year=pi.fiscal_year
join dim_customer c
on s.customer_code=c.customer_code;

set session wait_timeout = 600;
set session interactive_timeout=600;
select * from  post_invoice;



-- percentage contribution by customer
WITH customer_net_sales as
(
SELECT customer,
 SUM(net_sales_amount)/1000000 net_sales_amount_mln
 FROM post_invoice
 where fiscal_year=2021
 GROUP BY customer
)
SELECT *, net_sales_amount_mln*100/sum(net_sales_amount_mln) OVER() as prec_contribution FROM customer_net_sales 
order by net_sales_amount_mln desc;


-- percentage contribution by customer without using views 
WITH customer_net_sales as
(
SELECT c.customer,
 SUM(net_sales_amount)/1000000 net_sales_amount_mln
 FROM post_invoice
 where fiscal_year=2021
 GROUP BY customer
)
SELECT *, net_sales_amount_mln*100/sum(net_sales_amount_mln) OVER() as prec_contribution FROM customer_net_sales 
order by net_sales_amount_mln desc;


-- % contribution by customer and region
WITH region_net_sales AS
(SELECT pi.customer,c.region,sum(pi.net_sales_amount/1000000) AS net_sales_mln
FROM post_invoice pi
JOIN dim_customer c
ON pi.customer_code=c.customer_code
where pi.fiscal_year=2021
GROUP BY pi.customer,c.region
)
SELECT *,
net_sales_mln*100/SUM(net_sales_mln) OVER(PARTITION BY region) as perc_contribution_region
FROM region_net_sales;



-- Top 3 products by sold_quantity divisionwise
with product_rank as
(
select pro.division division,
pi.product product,
sum(pi.sold_quantity) sold_quantity,
dense_rank() over(partition by pro.division order by sum(pi.sold_quantity) desc) as drnk
FROM post_invoice pi
JOIN dim_product pro
on pi.product_code=pro.product_code
where pi.fiscal_year=2021
group by pro.division,pi.product
)
SELECT *
from product_rank
where drnk<=3;


-- top 2 customer by gross_sales and region
with gross_price_by_market_region as
(select gs.market market,
c.region region,
round(sum(gs.gross_price_total)/1000000,2) gross_price_total_mln
from gross_sales gs
JOIN dim_customer c
on gs.customer_code=c.customer_code
where gs.fiscal_year=2021
group by gs.market,c.region),
gross_price_by_market_region_drnk as
(select *,dense_rank() over(partition by region order by gross_price_total_mln desc) drnk from gross_price_by_market_region)   
select * from gross_price_by_market_region_drnk 
where drnk<=2;



-- Created a helper table fact_act_est by doing a full outer join between fact_sales_mpnthly and fact_forecast_monthly
create table fact_act_est(
select s.date date,
s.fiscal_year fiscal_year,
s.product_code product_code,
s.customer_code customer_code,
s.sold_quantity sold_quantity,
f.forecast_quantity forecast_quantity
from fact_sales_monthly s
left join fact_forecast_monthly f
using (date,product_code,customer_code)
union
select f.date date,
f.fiscal_year fiscal_year,
f.product_code product_code,
f.customer_code customer_code,
s.sold_quantity sold_quantity,
f.forecast_quantity forecast_quantity
from fact_forecast_monthly f
left join fact_sales_monthly s
using (date,product_code,customer_code)
);

-- added a column 'fiscal year' as generated column 
ALTER TABLE `gdb0041`.`fact_forecast_monthly`
ADD COLUMN `fiscal_year` YEAR GENERATED ALWAYS AS (YEAR(`date` + INTERVAL 4 MONTH)) VIRTUAL;

 
 -- checking trigger
 show triggers;
 
 insert into fact_sales_monthly(date,product_code,customer_code,sold_quantity)
 values("2050-07-11","LoL",100,76);
 
 select * from fact_sales_monthly where customer_code=100;
 select * from fact_act_est where customer_code=100;
 select * from fact_act_est 
 limit 5;
 
 -- checking trigger
 insert into fact_forecast_monthly(date,product_code,customer_code,forecast_quantity)
 values("2050-07-11","LoL",100,66);
 
 select * from fact_forecast_monthly where customer_code=100;
 select * from fact_act_est where customer_code=100;
 update fact_act_est
 set forecast_quantity=99 where customer_code=99;

update fact_act_est
set sold_quantity=0
where sold_quantity is null;

update fact_act_est
set forecast_quantity=0
where forecast_quantity is null;

DROP TABLE fact_act_est;



-- Supply Chain Analysis
-- Calculating abs error

WITH error_cal AS
(select c.customer_code customer_code,
c.customer customer_name,
c.market market,
sum(s.sold_quantity) sold_quantity,
sum(s.forecast_quantity) forecast_quantity,
sum(s.forecast_quantity - s.sold_quantity) as net_error,
round(sum(s.forecast_quantity - s.sold_quantity)*100/sum(s.forecast_quantity),2) as net_error_pct,
sum(abs(s.forecast_quantity - s.sold_quantity)) as abs_error,
round(sum(abs(s.forecast_quantity - s.sold_quantity))*100/sum(s.forecast_quantity),2) as abs_error_pct
from fact_act_est s
join
dim_customer c
on c.customer_code=s.customer_code
where s.fiscal_year = 2021
group by c.customer_code
order by abs_error_pct desc)
SELECT *,
IF (abs_error_pct>100,0, 100.0-abs_error_pct) forecast_accuracy 
FROM error_cal
order by forecast_accuracy desc;


-- 2020 vs 2021 supply chain analysis
-- creating a temporary table for year 2020
create temporary table forecast_accu_2020 
(select c.customer_code customer_code,
c.customer customer_name,
c.market market,
round(sum(abs(s.forecast_quantity - s.sold_quantity))*100/sum(s.forecast_quantity),2) as abs_error_pct,
IF (round(sum(abs(s.forecast_quantity - s.sold_quantity))*100/sum(s.forecast_quantity),2)>100,0, 100.0-round(sum(abs(s.forecast_quantity - s.sold_quantity))*100/sum(s.forecast_quantity),2)) forecast_accuracy_2020 
from fact_act_est s
join
dim_customer c
on c.customer_code=s.customer_code
where s.fiscal_year = 2020
group by c.customer_code
order by round(sum(abs(s.forecast_quantity - s.sold_quantity))*100/sum(s.forecast_quantity),2) desc);

-- creating a temporary table for year 2021
create temporary table forecast_accu_2021 
(select c.customer_code customer_code,
c.customer customer_name,
c.market market,
round(sum(abs(s.forecast_quantity - s.sold_quantity))*100/sum(s.forecast_quantity),2) as abs_error_pct_2021,
IF (round(sum(abs(s.forecast_quantity - s.sold_quantity))*100/sum(s.forecast_quantity),2)>100,0, 100.0-round(sum(abs(s.forecast_quantity - s.sold_quantity))*100/sum(s.forecast_quantity),2)) forecast_accuracy_2021 
from fact_act_est s
join
dim_customer c
on c.customer_code=s.customer_code
where s.fiscal_year = 2021
group by c.customer_code
order by round(sum(abs(s.forecast_quantity - s.sold_quantity))*100/sum(s.forecast_quantity),2) desc);

select f20.customer_code customer_code,
f20.customer_name customer_name,
f20.market market,
f20.forecast_accuracy_2020 forecast_accuracy_2020,
f21.forecast_accuracy_2021 forecast_accuracy_2021,
f20.forecast_accuracy_2020-f21.forecast_accuracy_2021 forecast_diff
from forecast_accu_2020 f20
join forecast_accu_2021 f21
on f20.customer_code=f21.customer_code
where f21.forecast_accuracy_2021<f20.forecast_accuracy_2020
order by f20.forecast_accuracy_2020 desc ; 




-- Final Report considering all costs involved with gross margin 
WITH cost_calculation AS
(select pi.*,
mc.manufacturing_cost manufacturing_cost,
round(pi.net_sales_amount*fc.freight_pct,2) freight_cost_amount,
round(pi.net_sales_amount*fc.other_cost_pct,2) other_cost_amount
from post_invoice pi
join fact_manufacturing_cost mc
on pi.product_code=mc.product_code and pi.fiscal_year=mc.cost_year
join fact_freight_cost fc
on pi.market=fc.market and pi.fiscal_year=fc.fiscal_year)
select *,(manufacturing_cost+freight_cost_amount+other_cost_amount) cogs,
round(net_sales_amount-(manufacturing_cost+freight_cost_amount+other_cost_amount),2) as gross_margin
from cost_calculation;








