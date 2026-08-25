{{ config(tags=['csm']) }}

select
  "SourceCode"::text as factory_code, "ItemNo"::text as product_code, {{ csm_period_columns('"PostingDate"') }},
  coalesce("Quantity", 0)::numeric as qty,
  coalesce("CostUnit", 0)::numeric as unit_cost,
  coalesce("CostActual", 0)::numeric as total_cost,
  coalesce("MainMaterial", 0)::numeric as nvlc,
  coalesce("SubMaterial", 0)::numeric as vl_phu,
  coalesce("Fuel", 0)::numeric as fuel,
  coalesce("Packing", 0)::numeric as packing,
  coalesce("OtherMaterial", 0)::numeric as cppx,
  coalesce("Engine", 0)::numeric as dien_luc,
  coalesce("Salary", 0)::numeric as luong,
  coalesce("Warranty", 0)::numeric as bhxh_yt,
  0::numeric as kpcd,
  coalesce("CostWarehouse", 0)::numeric as khcb,
  0::numeric as scl,
  coalesce("Warranty", 0)::numeric as warranty,
  coalesce("Party", 0)::numeric as party,
  coalesce("Discount", 0)::numeric as chiet_khau,
  coalesce("Repair", 0)::numeric as repair,
  0::numeric as cost_warehouse
from {{ ref('stg_csm__manufacturer_costing') }}
