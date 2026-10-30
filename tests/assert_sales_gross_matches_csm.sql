-- Doanh thu bán hàng theo đúng câu SQL CSM gửi (30/10/2026), từng tháng:
--   SUM(VATBaseAmount + LineDiscountAmount) FROM sale_invoice
--   WHERE ItemNo NOT IN (SELECT ItemNo FROM item WHERE InventoryPostingGroup = 'CK')
-- phải bằng SUM(sales_gross) ở mart. Chiết khấu thương mại = −SUM(VATBase) của dòng CK.
with src as (
  select date_format(s.`PostingDate`, '%Y-%m') as ym,
    sum(case when ck.`ItemNo` is null then coalesce(s.`VATBaseAmount`, 0) + coalesce(s.`LineDiscountAmount`, 0) else 0 end) as gross,
    sum(case when ck.`ItemNo` is not null then -coalesce(s.`VATBaseAmount`, 0) else 0 end) as ckt
  from {{ source('csm', 'sale_invoice') }} s
  left join (select distinct trim(`ItemNo`) as `ItemNo` from {{ source('csm', 'item') }} where trim(`InventoryPostingGroup`) = 'CK') ck
    on ck.`ItemNo` = trim(s.`ItemNo`)
  group by 1
),
mart as (
  select date_format(posting_date, '%Y-%m') as ym, sum(sales_gross) as gross, sum(trade_discount) as ckt
  from {{ ref('fact_csm_sales') }} group by 1
)
select src.ym, src.gross, mart.gross as mart_gross, src.ckt, mart.ckt as mart_ckt
from src left join mart on mart.ym = src.ym
where abs(coalesce(mart.gross, 0) - src.gross) > 1 or abs(coalesce(mart.ckt, 0) - src.ckt) > 1
