use manufacturing_dw;


#客户投诉事实表 
create table fact_customer_complaint(
complaint_id char(10) primary key,
complaint_date date not null,
customer_id char(6) not null,
product_id char(7) not null,
carrier_id char(6) not null,
order_no char(12)  not null,
shipment_id char(10) not null,
complaint_type varchar(20) not null,
complaint_qty int not null,
complaint_status varchar(10) not null,
responsibility_type varchar(20) not null,
resolution_days int not null,
complaint_loss_amount decimal(14,2) not null,
check(complaint_type in(
'产品性能问题','泄漏问题','振动噪声问题','外观包装问题',
'运输损伤','延迟交付','错发漏发')),
check(complaint_qty>0),
check(complaint_status in ('已关闭','处理中','待确认')),
check(responsibility_type in(
'供应商来料','企业内部','仓储发货','承运商运输','客户使用','待确定')),
#关闭的投诉要有处理天数 没关闭的暂时记0
check((complaint_status='已关闭' and resolution_days>0)
or (complaint_status in ('处理中','待确认') and resolution_days=0)),
check(complaint_loss_amount>0),
foreign key(complaint_date)
references dim_date(date_key),
foreign key(customer_id)
references dim_customer(customer_id),
foreign key(product_id)
references dim_product(product_id),
foreign key(carrier_id)
references dim_carrier(carrier_id)
);

