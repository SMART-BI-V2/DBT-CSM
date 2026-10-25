{{ config(tags=['csm'], duplicate_key=['period_date', 'product_code'], distributed_by=['product_code']) }}

-- Sản lượng nhập/xuất/tồn thành phẩm theo SP × tháng — cùng số liệu với fact_csm_fg_inventory
-- (giữ tên bảng + cột của bản cũ cho project SmartBI đang dùng). Xem giải thích ở fg_inventory.
select
  period_date, product_code,
  qty_begin, val_begin, qty_input, val_input, qty_output, val_output, qty_ending, val_ending,
  qty_inland, qty_export, qty_input_total, qty_output_total, is_provisional
from {{ ref('fact_csm_fg_inventory') }}
