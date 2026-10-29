{{ config(tags=['csm'], duplicate_key=['employee_no'], distributed_by=['employee_no']) }}

-- Nhân viên (hr_employee), không có thông tin cá nhân. Ngày trống của ERP được nạp thành
-- 1900-01-01 ⇒ đưa về NULL (cùng quy ước dev: 1900-01-01 = chưa nghỉ việc).
select
  CAST(`EmployeeNo` AS VARCHAR(64)) as employee_no,
  CAST(`Gender` AS INT) as gender,
  CAST(NULLIF(`DepartmentCode`, '') AS VARCHAR(64)) as department_code,
  CAST(`SourceCode` AS VARCHAR(16)) as factory_code,
  CASE WHEN `WorkingDate` > '1900-01-01' THEN `WorkingDate` END as working_date,
  CASE WHEN `TerminationDate` > '1900-01-01' THEN `TerminationDate` END as termination_date,
  CAST(NULLIF(TRIM(`TerminationReason`), '') AS VARCHAR(512)) as termination_reason,
  CASE WHEN `TerminationDate` > '1900-01-01' THEN 0 ELSE 1 END as is_active,
  `SystemDate` as system_date
from {{ ref('stg_csm__hr_employee') }}
