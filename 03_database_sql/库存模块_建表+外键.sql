use manufacturing_dw;


#仓库主数据 
create table dim_warehouse(
warehouse_id char(5) primary key,
warehouse_name varchar(50) not null,
warehouse_type varchar(20) not null,
region varchar(10) not null,
province varchar(20) not null,
city varchar(30) not null,
check(warehouse_type in ('综合仓','区域备件仓')),
check(region in ('华东','华北','华南','西南'))
);


#库存快照
create table fact_inventory_snapshot(
snapshot_id char(10) primary key,
snapshot_date date not null,
warehouse_id char(5) not null,
product_id char(7) not null,
on_hand_qty int not null,
available_qty int not null,
reserved_qty int not null,
safety_stock_qty int not null,
unit_cost decimal(12,2) not null,
inventory_amount decimal(16,2) not null,
last_movement_date date not null,
check(on_hand_qty>=0),
check(available_qty>=0),
check(reserved_qty>=0),
check(safety_stock_qty>=0),
check(unit_cost>=0),
check(inventory_amount>=0),
check(on_hand_qty=available_qty+reserved_qty),
foreign key(warehouse_id)
references dim_warehouse(warehouse_id),
foreign key(product_id)
references dim_product(product_id),
foreign key(snapshot_date)
references dim_date(date_key)
);


