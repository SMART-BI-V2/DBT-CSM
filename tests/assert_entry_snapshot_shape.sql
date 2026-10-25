-- Tồn kho trong mart dựa trên giả định về nguồn: dòng tháng (ngày 1) KHÔNG có số đầu kỳ,
-- dòng chụp số dư (ngày khác 1) KHÔNG có phát sinh. ERP đổi cách ghi ⇒ test này đỏ trước khi số tồn sai.
select 'material_entry' as tbl, `PostingDate`, count(*) as n
from {{ source('csm', 'material_entry') }}
where (DAY(`PostingDate`) = 1 and (coalesce(`QtyDau`,0) <> 0 or coalesce(`AmountDau`,0) <> 0))
   or (DAY(`PostingDate`) <> 1 and (coalesce(`QtyNhapTotal`,0) <> 0 or coalesce(`QtyXuatTotal`,0) <> 0))
group by `PostingDate`
union all
select 'production_entry', `PostingDate`, count(*)
from {{ source('csm', 'production_entry') }}
where (DAY(`PostingDate`) = 1 and (coalesce(`QuantityBegin`,0) <> 0 or coalesce(`ValueBegin`,0) <> 0))
   or (DAY(`PostingDate`) <> 1 and (coalesce(`QuantityInputTotal`,0) <> 0 or coalesce(`QuantityOutputTotal`,0) <> 0))
group by `PostingDate`
