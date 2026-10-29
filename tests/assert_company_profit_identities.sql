{{ config(severity='warn') }}
-- Công thức BCKQKD theo từng tháng (số ERP, mình không biến đổi ⇒ chỉ cảnh báo để báo đối tác/DA).
-- Chỉ tiêu 52 (thuế TNDN hoãn lại) ERP ghi ngược dấu mẫu B02-DN ⇒ 60 = 50 − 51 + 52 (đúng nhãn ERP).
with p as (
  select period_from as m, account_name as a, sum(amount) as v
  from {{ ref('company_profit_flat') }} group by 1, 2
),
w as (
  select m,
    sum(case when a = '01' then v else 0 end) c01, sum(case when a = '02' then v else 0 end) c02,
    sum(case when a = '10' then v else 0 end) c10, sum(case when a = '11' then v else 0 end) c11,
    sum(case when a = '20' then v else 0 end) c20, sum(case when a = '22' then v else 0 end) c22,
    sum(case when a = '23' then v else 0 end) c23, sum(case when a = '25' then v else 0 end) c25,
    sum(case when a = '26' then v else 0 end) c26, sum(case when a = '30' then v else 0 end) c30,
    sum(case when a = '31' then v else 0 end) c31, sum(case when a = '32' then v else 0 end) c32,
    sum(case when a = '40' then v else 0 end) c40, sum(case when a = '50' then v else 0 end) c50,
    sum(case when a = '51' then v else 0 end) c51, sum(case when a = '52' then v else 0 end) c52,
    sum(case when a = '60' then v else 0 end) c60
  from p group by m
)
select m,
  c10 - (c01 - c02) as d10, c20 - (c10 - c11) as d20, c30 - (c20 + c22 - c23 - c25 - c26) as d30,
  c40 - (c31 - c32) as d40, c50 - (c30 + c40) as d50, c60 - (c50 - c51 + c52) as d60
from w
where abs(c10 - (c01 - c02)) > 1000 or abs(c20 - (c10 - c11)) > 1000
   or abs(c30 - (c20 + c22 - c23 - c25 - c26)) > 1000 or abs(c40 - (c31 - c32)) > 1000
   or abs(c50 - (c30 + c40)) > 1000 or abs(c60 - (c50 - c51 + c52)) > 1000
