{{ config(tags=['staging']) }}

select {{ csm_trim('`SourceCode`') }} as `SourceCode`, {{ csm_code('`ItemNo`') }} as `ItemNo`, `PostingDate`,
  `QtyDau`, `AmountDau`, `QtyNhapTotal`, `AmountNhapTotal`, `QtyXuatTotal`, `AmountXuatTotal`,
  `QtyNhapKho`, `AmountNhapKho`, `QtyXuatKho`, `AmountXuatKho`, `QtyXuatSX`, `AmountXuatSX`,
  `QtyNhapSX`, `AmountNhapSX`, `QtyTon`, `AmountTon`, CAST(`SystemDate` AS DATE) as `SystemDate`
from {{ source('csm', 'material_entry') }}
