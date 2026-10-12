use manufacturing_dw;


#承运商维度表
create table  dim_carrier(
carrier_id char(6) primary key,
carrier_name varchar(50) not null,
carrier_type varchar(20) not null,
service_level char(1) not null,
region_scope varchar(20) not null,
check(carrier_type in ('综合物流','重型零担','专线运输','工业快运')),
check(service_level in ('A','B','C'))
);


#发货事实表  用了特大整数21亿+
create table if not exists fact_shipment(
shipment_id char(10) primary key,
order_line_id bigint not null,
order_no char(12) not null,
shipment_date  date not null,
promised_delivery_date date not null,
actual_delivery_date date not null,
customer_id char(6) not null,
product_id char(7) not null,
warehouse_id char(5) not null,
carrier_id char(6) not null,
shipped_qty int not null,
freight_cost decimal(14,2) not null,
transport_distance_km int not null,
shipment_status varchar(10) not null,
check(shipped_qty>0),
check(freight_cost>=0),
check(transport_distance_km>0),
check(promised_delivery_date>=shipment_date),
check(actual_delivery_date>=shipment_date),
check(shipment_status in ('按时签收','延迟签收')),
foreign key(shipment_date)
references dim_date(date_key),
foreign key(customer_id)
references dim_customer(customer_id),
foreign key(product_id)
references dim_product(product_id),
foreign key(warehouse_id)
references dim_warehouse(warehouse_id),
foreign key(carrier_id)
references dim_carrier(carrier_id)
);





