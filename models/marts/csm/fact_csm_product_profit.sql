{{ config(tags=['csm'], duplicate_key=['factory_code', 'product_code', 'doc_type'], distributed_by=['product_code']) }}

-- Doanh thu – giá vốn – lãi theo XN × SP × nội địa/xuất khẩu × tháng (nguồn manufacturer_profit, chỉ có khi
-- tháng đã khoá sổ). Lưu ý nghiệp vụ: ERP ghi gần như toàn bộ dòng lãi ở SourceCode 01 (Văn phòng)
-- ⇒ không dùng để so lãi giữa các xí nghiệp sản xuất.
--
-- [SỬA 10/2026] gross_profit trước đây lấy BusinessProfit của ERP = LÃI KINH DOANH (đã trừ chiết khấu,
-- chi phí bán hàng, quản lý, lãi vay công nợ…), không phải lãi gộp (T9/2026: −7,39 tỷ so với lãi gộp
-- 93,65 tỷ). Nay:
--   gross_profit                = SaleActual − CostActual (doanh thu theo giá bán − giá vốn)
--   gross_profit_after_discount = gross_profit − 3 khoản chiết khấu (≈ chỉ tiêu 20 của BCKQKD)
--   business_profit             = BusinessProfit của ERP
--   business_profit ≈ gross_profit − (warranty + discount_amt + discount_business + discount_paid
--                     + bonus_cost + debt_cost + manage_cost + sale_cost + sale_return_cost) − phần dư.
--   Phần dư (0,2–1,2% doanh thu/tháng 2025–2026) chỉ ở hàng nội địa, là một tỷ lệ cố định trên doanh thu
--   theo nhóm hàng (vd 2206xx 1,726%, 0407xx 0,402% ở T9/2026) — khoản chi phí ERP không xuất ra cột riêng.
--   ERP còn DiscountApportion (= DiscountAmount phân bổ lại, cùng tổng tháng — không cộng thêm) và
--   CostActualNoPrice (luôn 0): không đưa vào mart.
-- Các cột luong…party = 0 như bản cũ (nguồn không có chi tiết) — giữ để không vỡ model SmartBI cũ.
with p as (
  select
    CAST(`SourceCode` AS VARCHAR(16)) as factory_code,
    CAST(`ItemNo` AS VARCHAR(128)) as product_code,
    CAST(`DocumentType` AS VARCHAR(16)) as doc_type,
    {{ csm_period_columns('`PostingDate`') }},
    CAST(sum(case when {{ csm_is_money_in_qty('`Quantity`', '`SaleActual`') }} then 0 else coalesce(`Quantity`, 0) end) AS DECIMAL(38,10)) as sale_qty,
    CAST(sum(coalesce(`SaleActual`, 0)) AS DECIMAL(38,10)) as sale_actual,
    CAST(sum(coalesce(`CostActual`, 0)) AS DECIMAL(38,10)) as cost_actual,
    CAST(sum(coalesce(`BusinessProfit`, 0)) AS DECIMAL(38,10)) as business_profit,
    CAST(sum(coalesce(`DiscountAmount`, 0)) AS DECIMAL(38,10)) as discount_amt,
    CAST(sum(coalesce(`CostWarranty`, 0)) AS DECIMAL(38,10)) as warranty,
    CAST(sum(coalesce(`DiscountBusiness`, 0)) AS DECIMAL(38,10)) as discount_business,
    CAST(sum(coalesce(`DiscountPaid`, 0)) AS DECIMAL(38,10)) as discount_paid,
    CAST(sum(coalesce(`BonusCost`, 0)) AS DECIMAL(38,10)) as bonus_cost,
    CAST(sum(coalesce(`DebtCost`, 0)) AS DECIMAL(38,10)) as debt_cost,
    CAST(sum(coalesce(`ManageCost`, 0)) AS DECIMAL(38,10)) as manage_cost,
    CAST(sum(coalesce(`SaleCost`, 0)) AS DECIMAL(38,10)) as sale_cost,
    CAST(sum(coalesce(`SaleReturnCost`, 0)) AS DECIMAL(38,10)) as sale_return_cost
  from {{ ref('stg_csm__manufacturer_profit') }}
  group by 1, 2, 3, 4, 5
)
select
  factory_code, product_code, doc_type, period_from, period_to,
  sale_qty, sale_actual, cost_actual,
  CAST(sale_actual - cost_actual AS DECIMAL(38,10)) as gross_profit,
  discount_amt, warranty,
  CAST(0 AS DECIMAL(38,10)) as luong, CAST(0 AS DECIMAL(38,10)) as fuel, CAST(0 AS DECIMAL(38,10)) as packing,
  CAST(0 AS DECIMAL(38,10)) as cppx, CAST(0 AS DECIMAL(38,10)) as vl_phu, CAST(0 AS DECIMAL(38,10)) as `repair`,
  CAST(0 AS DECIMAL(38,10)) as cost_warehouse, CAST(0 AS DECIMAL(38,10)) as dien_luc, CAST(0 AS DECIMAL(38,10)) as party,
  discount_business, discount_paid,
  CAST(sale_actual - cost_actual - discount_amt - discount_business - discount_paid AS DECIMAL(38,10)) as gross_profit_after_discount,
  bonus_cost, sale_cost, manage_cost, debt_cost, sale_return_cost,
  business_profit
from p
