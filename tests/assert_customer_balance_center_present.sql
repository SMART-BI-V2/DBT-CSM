-- Công nợ phải có TTTN (responsibility_center) để phân quyền theo dòng lọc được: khách có trong
-- danh mục mà TTTN vẫn NULL ⇒ hỏng phép nối (lệch chuẩn hoá mã) ⇒ dòng đó lọt khỏi mọi luật
-- (=/NOT IN loại NULL) và chỉ người "xem toàn bộ" thấy.
select b.customer_code, count(*) as n_rows
from {{ ref('fact_csm_customer_balance') }} b
join {{ ref('dim_csm_customer') }} c on c.customer_code = b.customer_code
where b.responsibility_center is null
  and c.responsibility_center is not null
group by 1
