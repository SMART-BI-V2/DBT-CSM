-- 12 khoản mục Z (theo costing_title ERP) cộng lại phải bằng CostTotal của ERP.
-- Sai ⇒ ánh xạ cột ↔ khoản mục bị lệch hoặc ERP đổi cấu trúc giá thành.
select factory_code, product_code, period_from, cost_total_components,
  nvlc + vl_phu + fuel + packing + ccpt + dien_luc + luong + bhxh_yt + kpcd + khcb + scl + cppx as sum_12
from {{ ref('fact_csm_product_cost') }}
where abs(cost_total_components - (nvlc + vl_phu + fuel + packing + ccpt + dien_luc + luong + bhxh_yt + kpcd + khcb + scl + cppx)) > 1
