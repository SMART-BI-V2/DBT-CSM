{{ config(tags=['staging']) }}

-- Chỉ lấy cột phục vụ báo cáo. KHÔNG lấy thông tin cá nhân: EmployeeName, Address, City, Village,
-- PhoneNo, Email, BirthDate.
select
  {{ csm_trim('`EmployeeNo`') }} as `EmployeeNo`,
  `Gender`,
  {{ csm_trim('`DepartmentCode`') }} as `DepartmentCode`,
  {{ csm_trim('`SourceCode`') }} as `SourceCode`,
  `WorkingDate`,
  `TerminationDate`,
  `TerminationReason`,
  `SystemDate`
from {{ source('csm', 'hr_employee') }}
