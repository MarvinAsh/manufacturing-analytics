import pandas as pd

iqc2024=pd.read_excel(r'D:\Manufacturing_Simulate_Data_Analysis\01_raw_data\待清洗数据\fact_iqc_raw_2024.xlsx')
iqc2025=pd.read_excel(r"D:\Manufacturing_Simulate_Data_Analysis\01_raw_data\待清洗数据\fact_iqc_raw_2025.xlsx")
iqc2026=pd.read_excel(r"D:\Manufacturing_Simulate_Data_Analysis\01_raw_data\待清洗数据\fact_iqc_raw_2026.xlsx")
fact_iqc=pd.concat([iqc2024,iqc2025,iqc2026],ignore_index=True) #将三年的IQC数据拼接一张表

#读取待清洗的表格

fact_defect=pd.read_excel(r"D:\Manufacturing_Simulate_Data_Analysis\01_raw_data\待清洗数据\fact_defect_raw.xlsx")
dim_supplier=pd.read_excel(r"D:\Manufacturing_Simulate_Data_Analysis\01_raw_data\待清洗数据\dim_supplier_raw.xlsx")
dim_product=pd.read_excel(r"D:\Manufacturing_Simulate_Data_Analysis\01_raw_data\待清洗数据\dim_product_raw.xlsx")
dim_date=pd.read_excel(r"D:\Manufacturing_Simulate_Data_Analysis\01_raw_data\待清洗数据\dim_date_raw.xlsx")

excels={'fact_iqc':fact_iqc,'fact_defect':fact_defect,'dim_supplier':dim_supplier,'dim_product':dim_product,'dim_date':dim_date}
#建立字典 可在执行时显示进度 方便循环

def check_first_title(name,df): #检查首行是否是标题，有问题再改路径
    print(f"\n===开始检查{name}===")
    print(df.head(2))

for name,df in excels.items(): #循环执行
    check_first_title(name,df)


#字符串列去两侧空格,int会报错 先找str的,然后把series转str再删
def clean_strip(df):
    column=df.select_dtypes(include=['str']).columns
    for col in column:
        df[col]=df[col].str.strip()
    return df

# clean_strip(fact_iqc)
# clean_strip(fact_defect)
# clean_strip(dim_supplier)
# clean_strip(dim_product)
# clean_strip(dim_date)
for df in excels.values(): #原地修改不涉及原字典重组。
    clean_strip(df)

#整体通用型检查 大小 类别 空值数量 重复数据数量
def check_base_info(name,df):
    print(f"\n===开始检查表{name}===")
    print(df.shape)
    print(df.dtypes)
    print(f"空值总数：\n{df.isna().sum()}") #每列分别检查
    print(f"重复行总数：{df.duplicated().sum()}") #整行检查

for name,df in excels.items():
    check_base_info(name,df)
#检查导入系统前的主键唯一性
def check_primary_key(name,df,key):
    print(f"==开始检查表{name}主键{key}===")
    print(f"重复主键数量： {df[key].duplicated().sum()}") #主键的列检查重复
    # if df[key].duplicated(keep=False).sum()>0:
    #     df[df[key].duplicated(keep=False)].to_excel(f"{name}重复主键导出表.xlsx",index=False)

check_primary_key('fact_iqc',fact_iqc,'inspection_id' )
check_primary_key('dim_supplier',dim_supplier,'supplier_id' )
check_primary_key('dim_product',dim_product,'product_id' )
check_primary_key('dim_date',dim_date,'date' )
check_primary_key('fact_defect',fact_defect,'defect_record_id' )


#列格式问题：因前面发现fact_iqc表的inspection_date和pass_qty是object格式 先看看差异是什么

iqc_date=pd.to_datetime(fact_iqc['inspection_date'],errors='coerce')
iqc_date_diff=fact_iqc[fact_iqc['inspection_date'].notna() & (iqc_date.isna())] #利用原先非空 转换变空 交集
print(iqc_date_diff['inspection_date']) #执行结果出现两类 1.日期待确认 2.2026-13-05  需要反馈业务填写部门自行确认
iqc_date_diff.to_excel("补充任务_待质量部门修改'inspection_date'列问题.xlsx",index=False)

iqc_pass=pd.to_numeric(fact_iqc['pass_qty'],errors='coerce')
iqc_pass_diff=fact_iqc[fact_iqc['pass_qty'].notna() & iqc_pass.isna()]
print(iqc_pass_diff['pass_qty']) #结果出现都是xx件  带单位的情况 我们可以自行处理单位问题

fact_iqc['pass_qty_clean']=fact_iqc['pass_qty'].astype(str).str.replace('件','') #创建新列 确保不破坏原数据
fact_iqc['pass_qty_clean']=pd.to_numeric(fact_iqc['pass_qty_clean'],errors='coerce')
iqc_pass_diff.to_excel("通知任务_告知质量部门'pass_qty'列改善意见.xlsx",index=False) #虽然改完了但还是导出给业务部门 反馈其填写错误

#重复主键问题检查：
dmp_fact_iqc=fact_iqc[fact_iqc['inspection_id'].duplicated(False)].sort_values('inspection_id') #吧重复都标记false然后排序在一起
print(f'一共重复主键 {len(dmp_fact_iqc)} 项')
print(dmp_fact_iqc.to_string())#检查发现不存在主键一样 数据不同的问题 可以自行去重
fact_iqc=fact_iqc.drop_duplicates()





dmp_supplier=dim_supplier[dim_supplier['supplier_id'].duplicated(False)].sort_values('supplier_id')
print(f'一共重复主键 {len(dmp_supplier)} 项')
print(dmp_supplier.to_string()) #同上 数据完全一致 自行去重
dim_supplier=dim_supplier.drop_duplicates()

dmp_product=dim_product[dim_product['product_id'].duplicated(False)].sort_values('product_id')
print(f'一共重复主键 {len(dmp_product)}项')
print(dmp_product.to_string())
dim_product=dim_product.drop_duplicates() #同上 数据完全一致 自行去重

#空值问题全部输出一张表：
# def put_empty(name,df,key):
    # print(f"==开始处理表{name}的列{key}==")
    # empty_values=df[df[key].isna()]
    # empty_values.to_excel(f"表_{name}_列_{key}_待补充.xlsx") #优化

excels={'fact_iqc':fact_iqc,'fact_defect':fact_defect,'dim_supplier':dim_supplier,'dim_product':dim_product,'dim_date':dim_date}
with pd.ExcelWriter("所有空值报告输出.xlsx") as writer:
    for name, df in excels.items():
        empty_values = df[df.isna().any(axis=1)] #利用any有没有 axis=1整行却值才拿出来
        if len(empty_values)>0:
            empty_values.to_excel(writer,sheet_name=name,index=False)
    print("空值报告已汇总Excel")

#检查孤儿键
# check_supplier=pd.merge(fact_iqc,dim_supplier["supplier_id"],how='left',on='supplier_id',indicator=True)
# solo=check_supplier['_merge']=='left_only'
# print(f"iqc的供应商名称有 {solo.sum()} 个孤儿键")

def check_solo(left_sheet,right_sheet,left_key,right_key,name):
    check=pd.merge(left_sheet,right_sheet[[right_key]],how='left',left_on=left_key,right_on=right_key,indicator=True)
    solo=check['_merge']=='left_only'
    print(f"{name} 有 {solo.sum()} 个孤儿键")
    return check[solo]

check_solo(fact_iqc,dim_supplier,'supplier_id','supplier_id','供应商')
check_solo(fact_iqc,dim_product,'product_id','product_id','产品')
check_solo(fact_defect,fact_iqc,'inspection_id','inspection_id','缺陷记录')

#值域检测:
# wrong_type=fact_iqc[~fact_iqc['inspection_type'].isin(['首检','复检'])]
# print(f"检验类型有 {len(wrong_type)} 错误输入。")

def wrong_values(name,df,column,column_values):
    wrong_df=df[~df[column].isin(column_values)
                & (df[column].notna())] #要加入notna判定 前面已有空值判断 避免两个体系问题重复展示
    print(f"表 {name} 列{column}共有 {len(wrong_df)} 条输入错误。")
    return wrong_df




iqc_error=wrong_values('IQC',fact_iqc,'inspection_type',['首检','复检'])
product_error=wrong_values('产品',dim_product,'product_category',['承压壳体组件','转子组件','耐磨件','轴封系统','轴承总成','传动与底座组件','辅助管路附件'])
supplier_error=wrong_values('供应商',dim_supplier,'supplier_level',['A','B','C'])
defect_error=wrong_values('缺陷',fact_defect,'defect_type',['尺寸问题','外观问题','尺寸+外观问题'])


wrong_num=fact_iqc[fact_iqc["defect_qty"]
                   +
                   fact_iqc["pass_qty_clean"]
                   !=
                   fact_iqc["inspect_qty"]
                   & fact_iqc['pass_qty_clean'].notna()]
print(f"合格数量与不合格数量之和有 {len(wrong_num)} 条不等于检验数量")
print(wrong_num.to_string())


#数据校验 检查缺陷表登记的不合格数量是否和检验表不合格数吻合
defect_sum=fact_defect.groupby('inspection_id').agg({'defect_qty':'sum'}).reset_index()
check_match=pd.merge(fact_iqc,defect_sum,how='left',on='inspection_id')
print(check_match.head(5).to_string())
check_match['defect_qty_y']=check_match['defect_qty_y'].fillna(0) #后加的 避免原表合格件不成立的误判
defect_diff=check_match[check_match['defect_qty_x']!=check_match['defect_qty_y']]
print(f"缺陷表与检验表的不合格数量不吻合的条目有{len(defect_diff)} 条。")


