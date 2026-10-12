create database manufacturing_dw;
use manufacturing_dw;

start transaction;

create table dim_supplier(
supplier_id char(6) primary key,
supplier_name varchar(50) not null,
supplier_level char(1) not null,
region varchar (10) not null,
check(supplier_level in ('A','B','C'))
);

create table dim_product(
product_id char(7) primary key,
product_name varchar(50) not null,
product_category varchar(20) not null,
specification varchar(50) not null,
check(product_category in ('承压壳体组件','转子组件','耐磨件','轴封系统','传动与底座组件','辅助管路附件','轴承总成')));

create table dim_date(
date_key date primary key, 
year_num int not null,
month_num int not null,
quarter_num char(2)not null,
year_month_num char(7) not null
);





create table fact_iqc(
inspection_id int primary key,
batch_no CHAR(10) not null,
inspection_date date not null,
supplier_id  char(6) not null,
product_id char(7) not null,
inspection_type varchar(20) not null,
inspect_qty int not null,
pass_qty int not null,
defect_qty int not null,
check (inspection_type in ('首检','复检')),
check(inspect_qty =pass_qty+defect_qty),
check(pass_qty>0),
check(defect_qty>=0),
check(inspect_qty>=0),
foreign key (supplier_id)
references dim_supplier(supplier_id),
foreign key(product_id)
references dim_product(product_id),
foreign key(inspection_date)
references dim_date(date_key)
);


create table fact_defect( 
defect_record_id int primary key,
inspection_id int not null,
defect_type varchar(20)not null,
defect_qty int not null,
check(defect_type in('尺寸问题','外观问题','尺寸+外观问题')),
foreign key(inspection_id)
references fact_iqc(inspection_id),
check(defect_qty >=0));


#检查外键 孤儿吻合
select *
from fact_iqc fi 
left join dim_supplier ds 
on fi.supplier_id =ds.supplier_id 
where ds.supplier_id is null;

select *
from fact_iqc fi 
left join dim_product dp 
on fi.product_id =dp.product_id 
where dp.product_id is null;


select *
from fact_iqc fi 
left join dim_date dd 
on fi.inspection_date =dd.date_key 
where dd.date_key is null;
##全都是空 主数据外键全部符合要求 与python印证



#=====sql进行数据分析=====

#供应商合格率如何？
select ds.supplier_name,
sum(fi.inspect_qty )as inspect_total,
sum(fi.pass_qty )as inspect_pass,
sum(fi.defect_qty )as inspect_dft,
sum(fi.pass_qty )/sum(fi.inspect_qty )*100 as FPY
from fact_iqc fi 
left join dim_supplier ds 
on fi.supplier_id =ds.supplier_id 
where fi.inspection_type ='首检'
group by ds.supplier_name 
order by FPY desc;

#哪些产品更容易出问题？组内排序
with a as(
select product_category,product_name,
sum(fi.inspect_qty )as inspect_total,
sum(fi.pass_qty )as inspect_pass,
sum(fi.defect_qty )as inspect_dft,
sum(fi.pass_qty )/sum(fi.inspect_qty )*100 as FPY
from fact_iqc fi 
left join dim_product dp 
on fi.product_id =dp.product_id 
group by dp.product_category ,dp.product_name
)
select *,rank()over(partition by product_category order by FPY)as ranking
from a
order by product_category,FPY ;

#供应商来料缺陷占比分析
with b as(
select ds.supplier_name,fd.defect_type,sum(fd.defect_qty )as defect_qty_sum
from fact_iqc fi 
inner join fact_defect fd 
on fi.inspection_id =fd.inspection_id 
left join dim_supplier ds 
on fi.supplier_id =ds.supplier_id 
group by ds.supplier_name,fd.defect_type
), c as(
select *,sum(defect_qty_sum)over(partition by supplier_name) as single_supplier_defect_num
from b)
select *,defect_qty_sum/single_supplier_defect_num*100 as proportion
from c
order by supplier_name ,proportion desc ;


#供应商合格率月度分析
select dd.year_month_num ,
sum(fi.inspect_qty )as inspect_total,
sum(fi.pass_qty )as inspect_pass,
sum(fi.defect_qty )as inspect_dft,
sum(fi.pass_qty )/sum(fi.inspect_qty )*100 as FPY
from fact_iqc fi 
right join dim_date dd 
on fi.inspection_date =dd.date_key 
group by dd.year_month_num ;

#平均每批物料经过几次检验能合格？
select avg(inspection_times)
from (select batch_no,
count(*) as inspection_times
from fact_iqc
group by batch_no
) as t;

#哪些供应商经常复检？
-- select ds.supplier_id ,sum(case when fi.inspection_type='复检' then 1 end)/COUNT(*)*100 as reinspection_rate
-- from fact_iqc fi 
-- left join dim_supplier ds 
-- on fi.supplier_id =ds.supplier_id 
-- group  by ds.supplier_id 
-- order by reinspection_rate desc;

select ds.supplier_name ,sum(case when fi.inspection_type='复检' then 1 else 0 end)as fujian_times,COUNT(*)total_times,
sum(case when fi.inspection_type='复检' then 1 else 0 end)/COUNT(*)*100 as fujian_rate,
rank()over(order by sum(case when fi.inspection_type='复检' then 1 else 0 end)/COUNT(*)*100 desc)as ranking
from fact_iqc fi 
left join  dim_supplier ds  
on fi.supplier_id =ds.supplier_id 
group by ds.supplier_name 
order by ranking ;

# 近三年数据环比情况
with step1 as(
select date_format(date_key,'%Y-%m') as "年月",SUM(fi.inspect_qty ) as "总数",sum(fi.pass_qty )as "合格数",sum(fi.pass_qty )*1.0 /SUM(fi.inspect_qty )*100 as FPY
from dim_date dd
left join  fact_iqc fi
on fi.inspection_date =dd.date_key 
where fi.inspection_type ='首检'
group by date_format(date_key,'%Y-%m')
order by 年月 
)select *,lag(FPY,1)over(order by 年月)as "上月",(FPY-lag(FPY,1)over(order by 年月))/lag(FPY,1)over(order by 年月) as "环比变化",
avg(FPY)over(order by 年月 rows between 2 preceding and current row)as "三月平均"
from step1;





