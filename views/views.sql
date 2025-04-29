--task 1
alter view vw_StoreSalesSummary as
select
    s.store_id,
    s.store_name,
    count(distinct o.order_id) as total_orders,
    count(distinct o.customer_id) as total_customers, 
    sum(oi.list_price * oi.quantity * (1 - oi.discount)) as total_revenue, 
    case 
        when count(distinct o.order_id) = 0 then 0
        else round(
            sum(oi.list_price * oi.quantity * (1 - oi.discount))  / count(distinct o.order_id), 2)
    end as average_order_value, 
    case
        when count(distinct o.customer_id) = 0 then 0
        else round(
            sum(oi.list_price * oi.quantity * (1 - oi.discount)) / count(distinct o.customer_id), 2)
    end as revenue_per_customer 
from
    stores s
left join orders o on s.store_id = o.store_id
left join order_items oi on o.order_id = oi.order_id
group bys.store_id, s.store_name

select  * from  vw_StoreSalesSummary order by total_revenue desc


--task 2   
alter view  vw_TopSellingProducts as 
select p.product_id,
       p.[product_name],
	   c.category_name,
       coalesce(sum(oi.quantity) , 0) as total_quantity,
	   coalesce(sum(oi.list_price * oi.quantity * (1 - oi.discount)), 0 ) as total_revenue
from  [products] p
left join categories c on p.category_id = c.category_id
left join [order_items] oi on p.product_id=oi.product_id
left join [dbo].[orders] o on oi.order_id=o.order_id
group byp.product_id,[product_name], c.category_name;

select  * from vw_TopSellingProducts
order by 
    total_quantity desc;


--task 3     vw_InventoryStatus	Zaxirasi tugayotgan mahsulotlar  LEFT join [sales] sa on p.product_id = sa.product_id
create view vw_InventoryStatus as 
select 
	p.product_id,
	p.product_name,
	coalesce(sum(s.quantity) , 0 ) as total_stock_quantity,
	case 
        when coalesce(sum(s.quantity), 0) = 0 then 'Out of Stock'
        when coalesce(sum(s.quantity), 0) < (
            select avg(coalesce(quantity, 0)) from stocks
        ) then 'Low products in stock'
        else 'Many products in stock'
    end as stock_status
from products p
left join  [stocks] s on p.product_id = s.product_id
group byp.product_id,p.product_name
--HAVING COALESCE(sum(s.quantity), 0) < 10

select * from vw_InventoryStatus
order by total_stock_quantity

--task 4   vw_StaffPerformance	Har bir xodim bo‘yicha buyurtma va daromad

alter view vw_StaffPerformance as
 select  
    s.staff_id,
    s.first_name + ' ' + s.last_name as StaffName,
	st.[store_name],
    count(o.order_id) as TotalOrders,
	sum(oi.quantity * oi.list_price) as TotalRevenue
from 
    [staffs] s
join orders o on s.staff_id = o.staff_id
join order_items oi on o.order_id = oi.order_id
left join [stores] st on s.store_id=st.store_id
group bys.staff_id, s.first_name, s.last_name,st.[store_name];

select * from vw_StaffPerformance 
order by TotalRevenue desc;



--task 5     vw_RegionalTrends	Shahar yoki mintaqa bo‘yicha daromad

 alter view vw_RegionalTrends as 
 select 
	c.city,
	c.state,
	count(distinct o.order_id) as total_orders  ,
	sum(oi.quantity * oi.list_price)as TotalRevenue
 from customers c 
 join orders o on c.customer_id=o.customer_id
 join order_items oi on oi.order_id=o.order_id
 group by c.city,c.state;

 select * from vw_RegionalTrends
 order by total_orders desc

 --
create view vw_Top5RevenueByCityStore as
select top 5
    c.city,
    c.state,
    s.store_name,
    count(distinct o.order_id) as TotalOrders,
    sum(oi.quantity * oi.list_price) as TotalRevenue,
    format(sum(oi.quantity * oi.list_price), 'C', 'en-US') as TotalRevenueFormatted
from customers c 
	join orders o on c.customer_id = o.customer_id
	join order_items oi on oi.order_id = o.order_id
	join staffs st on o.staff_id = st.staff_id
	join stores s on st.store_id = s.store_id
group by c.city, c.state, s.store_name
order by TotalRevenue desc;

 select * from vw_Top5RevenueByCityStore


 --task6   vw_SalesByCategory	Har bir kategoriya bo‘yicha sotuv va foyda

create view vw_SalesByCategory as 
select  
    c.category_id,
    c.category_name,
    count(distinct  o.order_id) as total_orders,
    sum(oi.quantity) as total_sold_quantity,
    sum(oi.list_price * oi.quantity * (1 - oi.discount)) as total_revenue,
    sum(oi.list_price * oi.quantity * oi.discount) as total_discount_amount,
    round(avg(oi.discount) * 100, 2) as avg_discount_percent
from categories c  
join products p on c.category_id = p.category_id
join order_items oi on p.product_id = oi.product_id
join orders o on oi.order_id = o.order_id
group byc.category_id, c.category_name;

select * from vw_SalesByCategory
order by  total_orders desc;



----
create view vw_CustomerLifetimeValue as
select 
    c.customer_id,
    c.first_name + ' ' + c.last_name as customer_name,
    count(distinct o.order_id) as total_orders,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_revenue,
    avg(oi.quantity * oi.list_price * (1 - oi.discount)) as avg_order_value

from customers c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id
group byc.customer_id, c.first_name, c.last_name;

select * from vw_CustomerLifetimeValue
order by total_orders desc , total_revenue desc

---

alter view vw_SalesTrendsMonthly as
select 
    year(o.order_date) as sales_year,MONTH(o.order_date) as sales_month,
    DATENAME(MONTH, o.order_date) AS sales_month_name,
    count(distinct o.order_id) as total_orders,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_revenue,
	CAST(SUM(oi.quantity * oi.list_price * (1 - oi.discount)) / 
         NULLIF(COUNT(DISTINCT o.order_id), 0) AS DECIMAL(10, 2)) AS avg_order_value
from orders o
join order_items oi on o.order_id = oi.order_id
group by YEAR(o.order_date), MONTH(o.order_date),DATENAME(MONTH, o.order_date);

select * from vw_SalesTrendsMonthly
order by sales_year, sales_month;
