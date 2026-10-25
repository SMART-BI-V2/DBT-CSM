{{ config(tags=['csm'], duplicate_key=['factory_code', 'product_code', 'period_from'], distributed_by=['product_code']) }}

-- Giá thành sản xuất (Z) theo XN × SP × tháng. Giữ DẤU của ERP: chi phí ÂM (quy ước ghi Có);
-- What-If và hướng dẫn AI (#44) tự đổi dấu khi dùng. qty DƯƠNG.
--
-- Ánh xạ 12 thành phần Z theo bảng costing_title của ERP (thứ tự cột ERP ↔ mã khoản mục):
--   MainMaterial=NVLC, SubMaterial=NVLP, Fuel=NL, Packing=BB, OtherMaterial=CCPT (công cụ phụ tùng),
--   Engine=DL (động lực), Salary=LUONG, Warranty=BHXH, Party=KPCĐ, Discount=KHCB (khấu hao cơ bản),
--   Repair=SCL (sửa chữa lớn), CostWarehouse=CPPX (chi phí phân xưởng).
-- Đã kiểm: CostTotal = tổng 12 cột (100% dòng); Warranty ≈ 12–16% lương (BHXH), Party ≈ 1–1,5% lương (KPCĐ).
-- [SỬA so với bản PG] bản cũ gán nhầm: cppx←OtherMaterial, khcb←CostWarehouse, chiet_khau←Discount,
--   party←Party, repair←Repair, và Warranty vào CẢ bhxh_yt lẫn warranty (cộng 16 cột bị tính BHXH 2 lần).
--   Nay: mỗi khoản mục đúng tên; 5 cột cũ không phải khoản mục Z (warranty, party, chiet_khau, repair,
--   cost_warehouse) giữ lại để truy vấn cũ không lỗi nhưng = 0; thêm cột ccpt.
--   ⇒ nvlc+vl_phu+fuel+packing+ccpt+dien_luc+luong+bhxh_yt+kpcd+khcb+scl+cppx = cost_total_components.
select
  CAST(`SourceCode` AS VARCHAR(16)) as factory_code,
  CAST(`ItemNo` AS VARCHAR(128)) as product_code,
  {{ csm_period_columns('`PostingDate`') }},
  CAST(coalesce(`Quantity`, 0) AS DECIMAL(38,10)) as qty,
  CAST(coalesce(`CostUnit`, 0) AS DECIMAL(38,10)) as unit_cost,
  CAST(coalesce(`CostActual`, 0) AS DECIMAL(38,10)) as total_cost,
  CAST(coalesce(`MainMaterial`, 0) AS DECIMAL(38,10)) as nvlc,
  CAST(coalesce(`SubMaterial`, 0) AS DECIMAL(38,10)) as vl_phu,
  CAST(coalesce(`Fuel`, 0) AS DECIMAL(38,10)) as fuel,
  CAST(coalesce(`Packing`, 0) AS DECIMAL(38,10)) as packing,
  CAST(coalesce(`CostWarehouse`, 0) AS DECIMAL(38,10)) as cppx,
  CAST(coalesce(`Engine`, 0) AS DECIMAL(38,10)) as dien_luc,
  CAST(coalesce(`Salary`, 0) AS DECIMAL(38,10)) as luong,
  CAST(coalesce(`Warranty`, 0) AS DECIMAL(38,10)) as bhxh_yt,
  CAST(coalesce(`Party`, 0) AS DECIMAL(38,10)) as kpcd,
  CAST(coalesce(`Discount`, 0) AS DECIMAL(38,10)) as khcb,
  CAST(coalesce(`Repair`, 0) AS DECIMAL(38,10)) as scl,
  CAST(0 AS DECIMAL(38,10)) as warranty,
  CAST(0 AS DECIMAL(38,10)) as party,
  CAST(0 AS DECIMAL(38,10)) as chiet_khau,
  CAST(0 AS DECIMAL(38,10)) as `repair`,
  CAST(0 AS DECIMAL(38,10)) as cost_warehouse,
  CAST(coalesce(`OtherMaterial`, 0) AS DECIMAL(38,10)) as ccpt,
  CAST(coalesce(`CostTotal`, 0) AS DECIMAL(38,10)) as cost_total_components
from {{ ref('stg_csm__manufacturer_costing') }}
