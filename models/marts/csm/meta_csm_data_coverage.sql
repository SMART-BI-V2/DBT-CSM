{{ config(tags=['csm'], duplicate_key=['table_name'], distributed_by=['table_name']) }}

-- Độ phủ dữ liệu từng bảng fact — để AI / người dùng biết kỳ nào có số, kỳ cuối đã đủ tháng chưa.
-- Đối tác nạp lại tháng hiện tại nhiều lần/ngày ⇒ tháng hiện tại là số LUỸ KẾ đến last_posting_date.
-- Các bảng khoá sổ tháng (giá thành, lãi, BOM…) chỉ có số khi tháng đã đóng.
-- [SỬA 10/2026] nguồn chỉ ghi theo tháng (material_entry, production_entry, production_planning: mọi dòng
-- PostingDate = ngày 1) ⇒ max(PostingDate) luôn là ngày 1 của tháng cuối. last_posting_date của các bảng
-- này = ngày ERP trích số tháng cuối (SystemDate), chặn ở cuối tháng — xem macro csm_monthly_as_of.
with c as (
  select 'fact_csm_sales' as table_name, 'Doanh thu bán hàng (hoá đơn)' as description,
    (select min(period_from) from {{ ref('fact_csm_sales') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_sales') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__sale_invoice') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_sales') }}) as row_count
  union all
  select 'fact_csm_service_invoice' as table_name, 'Doanh thu dịch vụ' as description,
    (select min(period_from) from {{ ref('fact_csm_service_invoice') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_service_invoice') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__service_invoice') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_service_invoice') }}) as row_count
  union all
  select 'fact_csm_product_cost' as table_name, 'Giá thành sản xuất (Z)' as description,
    (select min(period_from) from {{ ref('fact_csm_product_cost') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_product_cost') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__manufacturer_costing') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_product_cost') }}) as row_count
  union all
  select 'fact_csm_material_cost' as table_name, 'Chi phí NVL chi tiết theo sản phẩm' as description,
    (select min(period_from) from {{ ref('fact_csm_material_cost') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_material_cost') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__manufacturer_material_costing') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_material_cost') }}) as row_count
  union all
  select 'fact_csm_product_profit' as table_name, 'Doanh thu – giá vốn – lãi gộp theo sản phẩm' as description,
    (select min(period_from) from {{ ref('fact_csm_product_profit') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_product_profit') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__manufacturer_profit') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_product_profit') }}) as row_count
  union all
  select 'company_profit_flat' as table_name, 'Kết quả kinh doanh toàn công ty' as description,
    (select min(period_from) from {{ ref('company_profit_flat') }}) as period_first,
    (select max(period_from) from {{ ref('company_profit_flat') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__company_profit') }}) as last_posting_date,
    (select count(*) from {{ ref('company_profit_flat') }}) as row_count
  union all
  select 'fact_csm_bom' as table_name, 'Định mức vật tư (BOM)' as description,
    (select min(period_date) from {{ ref('fact_csm_bom') }}) as period_first,
    (select max(period_date) from {{ ref('fact_csm_bom') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__production_bom_line') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_bom') }}) as row_count
  union all
  select 'fact_csm_material' as table_name, 'Nhập – xuất – tồn nguyên vật liệu' as description,
    (select min(period_date) from {{ ref('fact_csm_material') }}) as period_first,
    (select max(period_date) from {{ ref('fact_csm_material') }}) as period_last,
    {{ csm_monthly_as_of(ref('stg_csm__material_entry')) }} as last_posting_date,
    (select count(*) from {{ ref('fact_csm_material') }}) as row_count
  union all
  select 'fact_csm_fg_inventory' as table_name, 'Nhập – xuất – tồn thành phẩm' as description,
    (select min(period_date) from {{ ref('fact_csm_fg_inventory') }}) as period_first,
    (select max(period_date) from {{ ref('fact_csm_fg_inventory') }}) as period_last,
    {{ csm_monthly_as_of(ref('stg_csm__production_entry')) }} as last_posting_date,
    (select count(*) from {{ ref('fact_csm_fg_inventory') }}) as row_count
  union all
  select 'fact_csm_production' as table_name, 'Sản lượng nhập – xuất – tồn thành phẩm' as description,
    (select min(period_date) from {{ ref('fact_csm_production') }}) as period_first,
    (select max(period_date) from {{ ref('fact_csm_production') }}) as period_last,
    {{ csm_monthly_as_of(ref('stg_csm__production_entry')) }} as last_posting_date,
    (select count(*) from {{ ref('fact_csm_production') }}) as row_count
  union all
  select 'fact_csm_production_plan' as table_name, 'Kế hoạch sản xuất / tiêu thụ' as description,
    (select min(period_date) from {{ ref('fact_csm_production_plan') }}) as period_first,
    (select max(period_date) from {{ ref('fact_csm_production_plan') }}) as period_last,
    {{ csm_monthly_as_of(ref('stg_csm__production_planning')) }} as last_posting_date,
    (select count(*) from {{ ref('fact_csm_production_plan') }}) as row_count
  union all
  select 'fact_csm_customer_balance' as table_name, 'Công nợ phải thu' as description,
    (select min(period_from) from {{ ref('fact_csm_customer_balance') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_customer_balance') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__customer_balance') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_customer_balance') }}) as row_count
  union all
  select 'fact_csm_customer_profit' as table_name, 'Lãi theo khách hàng' as description,
    (select min(period_from) from {{ ref('fact_csm_customer_profit') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_customer_profit') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__customer_profit') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_customer_profit') }}) as row_count
  union all
  select 'fact_csm_account_balance' as table_name, 'Số dư tài khoản' as description,
    (select min(period_from) from {{ ref('fact_csm_account_balance') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_account_balance') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__balance_account') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_account_balance') }}) as row_count
  union all
  select 'fact_csm_business_planning' as table_name, 'Kế hoạch / thực hiện kinh doanh' as description,
    (select min(period_from) from {{ ref('fact_csm_business_planning') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_business_planning') }}) as period_last,
    (select CAST(max(`PostingDate`) AS DATE) from {{ ref('stg_csm__business_planning') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_business_planning') }}) as row_count
  union all
  -- kế hoạch: last_posting_date = ngày tải bản kế hoạch kỳ cuối lên
  select 'fact_csm_plan_company' as table_name, 'Kế hoạch SXKD cấp công ty (tệp KHSX tải lên)' as description,
    (select min(period_from) from {{ ref('fact_csm_plan_company') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_plan_company') }}) as period_last,
    (select CAST(max(systemdate) AS DATE) from {{ ref('fact_csm_plan_company') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_plan_company') }}) as row_count
  union all
  -- kế hoạch: last_posting_date = ngày tải bản kế hoạch kỳ cuối lên
  select 'fact_csm_plan_factory_product' as table_name, 'Kế hoạch SXKD xí nghiệp theo sản phẩm (tệp KHSX tải lên)' as description,
    (select min(period_from) from {{ ref('fact_csm_plan_factory_product') }}) as period_first,
    (select max(period_from) from {{ ref('fact_csm_plan_factory_product') }}) as period_last,
    (select CAST(max(systemdate) AS DATE) from {{ ref('fact_csm_plan_factory_product') }}) as last_posting_date,
    (select count(*) from {{ ref('fact_csm_plan_factory_product') }}) as row_count
)
select
  CAST(table_name AS VARCHAR(64)) as table_name,
  CAST(description AS VARCHAR(256)) as description,
  CAST(period_first AS DATE) as period_first,
  CAST(period_last AS DATE) as period_last,
  last_posting_date,
  -- kỳ cuối đủ tháng: tháng đã qua, hoặc đã có dữ liệu tới ngày cuối tháng
  CAST(case when period_last is null then null
            when period_last < CAST(DATE_TRUNC(CURDATE(), 'month') AS DATE) then 1
            when last_posting_date >= LAST_DAY(period_last) then 1
            else 0 end AS TINYINT) as last_period_complete,
  CAST(row_count AS BIGINT) as row_count,
  CAST(NOW() AS DATETIME) as built_at
from c
