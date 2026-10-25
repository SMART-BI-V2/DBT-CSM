{{ config(tags=['staging']) }}

-- CSM chưa từng nạp `department` (nguồn luôn rỗng). Nghiệp vụ yêu cầu giữ danh sách
-- phòng ban tạm (seeds/seed_department.csv) thay vì để dimension rỗng.
select `RowID`, {{ csm_trim('`Code`') }} as `Code`, `Description`, {{ csm_trim('`SourceCode`') }} as `SourceCode`
from {{ ref('seed_department') }}
