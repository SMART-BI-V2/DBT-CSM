{{ config(tags=['csm'], duplicate_key=['period_date', 'product_code', 'material_code'], distributed_by=['product_code'], buckets=3) }}

-- Định mức BOM 1 cấp theo tháng: period_date = NGÀY CUỐI tháng; ERP chỉ ghi BOM cho thành phẩm
-- có sản xuất trong tháng. qty_per_unit = SL vật tư / 1 SP; scrap_pct = % hao hụt.
-- Trùng (tháng, SP, vật tư) giữ dòng Scrap lớn nhất (như DISTINCT ON của bản PG).
select period_date, product_code, material_code, qty_per_unit, scrap_pct, gross_weight
from (
  select
    CAST(`PostingDate` AS DATE) as period_date,
    CAST(`ProductionBomNo` AS VARCHAR(128)) as product_code,
    CAST(`ItemNo` AS VARCHAR(128)) as material_code,
    CAST(coalesce(`Quantity`, 0) AS DECIMAL(18,6)) as qty_per_unit,
    CAST(coalesce(`Scrap`, 0) AS DECIMAL(10,4)) as scrap_pct,
    CAST(coalesce(`GrossWeight`, 0) AS DECIMAL(18,4)) as gross_weight,
    row_number() over (partition by CAST(`PostingDate` AS DATE), `ProductionBomNo`, `ItemNo`
                       order by `Scrap` desc) as rn
  from {{ ref('stg_csm__production_bom_line') }}
) d
where rn = 1
