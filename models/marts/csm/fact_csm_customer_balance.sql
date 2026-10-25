{{ config(tags=['csm'], duplicate_key=['customer_code', 'period_from'], distributed_by=['customer_code']) }}

-- Công nợ phải thu theo KH × tháng. Nguồn customer_balance là PHÁT SINH theo ngày (Amount = Nợ − Có;
-- Amount* = nguyên tệ, *LCY = quy đổi VND) cộng một lần số dư đầu kỳ (dòng 31/12 đầu dữ liệu).
-- amount/debit/credit = phát sinh trong tháng (như bản cũ).
-- [THÊM] balance_end / balance_end_lcy = DƯ NỢ CUỐI THÁNG (luỹ kế từ đầu dữ liệu); lưới KH × tháng
--   để tháng không phát sinh vẫn có dư nợ. Đã đối chiếu: dư nợ cuối 2024 tính từ dev = đầu kỳ ERP
--   trên prod (353/353 KH, 743,39 tỷ VND).
with mv as (
  select `CustomerNo` as customer_code, {{ csm_month('`PostingDate`') }} as mth,
    sum(coalesce(`Amount`,0)) a, sum(coalesce(`DebitAmount`,0)) d, sum(coalesce(`CreditAmount`,0)) c,
    sum(coalesce(`AmountLCY`,0)) al, sum(coalesce(`DebitAmountLCY`,0)) dl, sum(coalesce(`CreditAmountLCY`,0)) cl
  from {{ ref('stg_csm__customer_balance') }}
  group by 1, 2
),
months as (select distinct mth from mv),
key_months as (select customer_code, min(mth) first_mth from mv group by 1),
grid as (
  select k.customer_code, m.mth,
    coalesce(v.a,0) a, coalesce(v.d,0) d, coalesce(v.c,0) c, coalesce(v.al,0) al, coalesce(v.dl,0) dl, coalesce(v.cl,0) cl,
    v.mth is not null as has_src
  from key_months k join months m on m.mth >= k.first_mth
  left join mv v on v.customer_code = k.customer_code and v.mth = m.mth
),
bal as (
  select g.*,
    sum(a) over (partition by customer_code order by mth rows between unbounded preceding and current row) as b,
    sum(al) over (partition by customer_code order by mth rows between unbounded preceding and current row) as bl
  from grid g
)
select
  CAST(customer_code AS VARCHAR(128)) as customer_code,
  mth as period_from,
  CAST(LAST_DAY(mth) AS DATE) as period_to,
  CAST(a AS DECIMAL(18,2)) as amount,
  CAST(d AS DECIMAL(18,2)) as debit_amount,
  CAST(c AS DECIMAL(18,2)) as credit_amount,
  CAST(al AS DECIMAL(18,2)) as amount_lcy,
  CAST(dl AS DECIMAL(18,2)) as debit_amount_lcy,
  CAST(cl AS DECIMAL(18,2)) as credit_amount_lcy,
  CAST(b AS DECIMAL(18,2)) as balance_end,
  CAST(bl AS DECIMAL(18,2)) as balance_end_lcy
from bal
where has_src or abs(b) >= 0.5 or abs(bl) >= 0.5
