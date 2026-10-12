use manufacturing_dw;


#客户维度表 
create table if not exists dim_customer(
customer_id char(6) primary key,
customer_name varchar(80) not null,
customer_segment varchar(10) not null,
customer_industry varchar(20) not null,
region varchar(10) not null,
province varchar(20) not null,
city varchar(30) not null,
check(customer_segment in ('战略客户','重点客户','普通客户')),
check(customer_industry in ('石油化工','电力','水务','工程公司','其他')),
check(region in ('华东','华北','华南','华中','西南','西北','东北'))
);


#销售事实表 一行代表订单中的一条产品明细
create table if not exists fact_sales_order(
order_line_id bigint primary key,
order_no char(12) not null,
order_date date not null,
customer_id char(6) not null,
product_id char(7) not null,
order_qty int not null,
unit_price decimal(12,2) not null,
unit_cost decimal(12,2) not null,
sales_amount decimal(14,2) not null,
cost_amount decimal(14,2) not null,
profit_amount decimal(14,2) not null,
order_status varchar(10) not null,
check(order_qty>0),
check(unit_price>=0),
check(unit_cost>=0),
check(sales_amount>=0),
check(cost_amount>=0),
check(order_status in ('待发货','已发货','已完成','已取消')),
foreign key(order_date)
references dim_date(date_key),
foreign key(customer_id)
references dim_customer(customer_id),
foreign key(product_id)
references dim_product(product_id)
);



#主键重复检查 看看有没有重复id
select customer_id,count(*) as counts
from dim_customer
group by customer_id
having count(*)>1;

select order_line_id,count(*) as counts
from fact_sales_order
group by order_line_id
having count(*)>1;


#客户、产品、日期外键检查 结果应该都是0
select
sum(c.customer_id is null) as missing_customer_fk,
sum(p.product_id is null) as missing_product_fk,
sum(d.date_key is null) as missing_date_fk
from fact_sales_order f
left join dim_customer c
on f.customer_id=c.customer_id
left join dim_product p
on f.product_id=p.product_id
left join dim_date d
on f.order_date=d.date_key;


#金额检查 利润应该等于销售额减成本
select *
from fact_sales_order
where profit_amount != sales_amount-cost_amount;

#取消订单的三个金额应该都是0
select *
from fact_sales_order
where order_status='已取消'
and (sales_amount!=0 or cost_amount!=0 or profit_amount!=0);

#正常订单检查金额和数量单价是否吻合
select *
from fact_sales_order
where order_status!='已取消'
and (sales_amount!=order_qty*unit_price
or cost_amount!=order_qty*unit_cost);

#以上几个简单检查也可以在excel里用公式验证
