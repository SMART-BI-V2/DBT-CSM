{{ config(tags=['csm'], duplicate_key=['customer_code', 'product_code', 'doc_type'], distributed_by=['product_code'], buckets=3) }}

-- Doanh thu chi tiết từng dòng hoá đơn. doc_type là mã ERP (0, 5 = bán hàng; 12 = điều chỉnh/giảm giá
-- hoá đơn, amount ÂM…), KHÔNG phải inland/export. Tổng doanh thu = SUM(amount) (đã trừ điều chỉnh).
-- [SỬA so với bản PG] dòng điều chỉnh (mã giả 2900xx, loại 12) ERP ghi SỐ TIỀN vào Quantity
-- (dev 2024: 285 tỷ "cái" so với ~47 triệu SP thật) ⇒ qty = 0, unit_price = NULL, đánh dấu is_adjustment = 1.
-- [30/10/2026 — định nghĩa của CSM] Doanh thu bán hàng = SUM(VATBaseAmount + LineDiscountAmount) trên các dòng
-- KHÔNG phải mặt hàng nhóm kho 'CK' (chiết khấu thương mại) ⇒ cột sales_gross (đã GỒM chiết khấu dòng + CKTM).
-- Chiết khấu thương mại = các dòng mặt hàng nhóm 'CK' (VATBase âm) ⇒ trade_discount (số dương).
select
  CAST(`CustomerNo` AS VARCHAR(128)) as customer_code,
  CAST(`ItemNo` AS VARCHAR(128)) as product_code,
  CAST(`DocumentType` AS VARCHAR(16)) as doc_type,
  CAST(`DocumentNo` AS VARCHAR(128)) as doc_no,
  CAST(`ResponsibilityCenter` AS VARCHAR(64)) as responsibility_center,
  {{ csm_period_columns('`PostingDate`') }},
  -- Ngày ghi sổ — để dự báo theo TUẦN (Forecast) và phân tích theo ngày.
  CAST(`PostingDate` AS DATE) as posting_date,
  CAST(case when is_adj then 0 else coalesce(`Quantity`, 0) end AS DECIMAL(38,10)) as qty,
  CAST(coalesce(`Amount`, 0) AS DECIMAL(38,10)) as amount,
  CAST(coalesce(`VATBaseAmount`, 0) AS DECIMAL(38,10)) as vat_base,
  CAST(coalesce(`VATAmount`, 0) AS DECIMAL(38,10)) as vat_amount,
  CAST(case when is_adj then NULL else `Amount` / nullif(`Quantity`, 0) end AS DECIMAL(38,10)) as unit_price,
  CAST(coalesce(`LineDiscountAmount`, 0) AS DECIMAL(38,10)) as line_discount,
  CAST(case when is_adj then 1 else 0 end AS TINYINT) as is_adjustment,
  CAST(case when is_ck then 1 else 0 end AS TINYINT) as is_trade_discount,
  CAST(case when is_ck then 0 else coalesce(`VATBaseAmount`, 0) + coalesce(`LineDiscountAmount`, 0) end AS DECIMAL(38,10)) as sales_gross,
  CAST(case when is_ck then -coalesce(`VATBaseAmount`, 0) else 0 end AS DECIMAL(38,10)) as trade_discount
from (
  select s.*,
    (s.`DocumentType` = '12' or {{ csm_is_money_in_qty('s.`Quantity`', 's.`Amount`') }}) as is_adj,
    (ck.`ItemNo` is not null) as is_ck
  from {{ ref('stg_csm__sale_invoice') }} s
  left join (
    select distinct `ItemNo` from {{ ref('stg_csm__item') }} where `InventoryPostingGroup` = 'CK'
  ) ck on ck.`ItemNo` = s.`ItemNo`
) x
