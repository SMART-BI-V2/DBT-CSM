{{ config(tags=['staging', 'intake']) }}

-- Ô số liệu của các lô KHSX ĐANG HIỆU LỰC (mỗi kỳ một lô).
-- Lô do SmartBI ghi (mô-đun "Nhập dữ liệu Excel"): ghi xong toàn bộ ô mới chuyển 'active', lô bị
-- thay chuyển 'superseded' (giữ lịch sử) ⇒ chỉ đọc 'active'; nếu lúc đổi bản có 2 lô active cùng kỳ
-- thì lấy lần điều chỉnh rồi lô mới nhất.
with b as (
  {{ intake_source_or_empty('intake_batch', [
      ('batch_id', 'BIGINT'), ('template_code', 'VARCHAR(64)'), ('period_year', 'INT'), ('period_month', 'INT'),
      ('revision', 'INT'), ('status', 'VARCHAR(16)'), ('file_name', 'VARCHAR(512)'), ('uploaded_by', 'VARCHAR(256)'),
      ('uploaded_at', 'DATETIME')
  ]) }}
),
active as (
  select * from (
    select b.*, row_number() over (partition by template_code, period_year, period_month
                                   order by revision desc, batch_id desc) as rn
    from b
    where template_code = 'khsx' and status = 'active'
  ) x where rn = 1
),
c as (
  {{ intake_source_or_empty('intake_cell', [
      ('batch_id', 'BIGINT'), ('template_code', 'VARCHAR(64)'), ('sheet', 'VARCHAR(128)'), ('row_no', 'INT'),
      ('row_ord', 'INT'), ('row_kind', 'VARCHAR(16)'), ('row_key', 'VARCHAR(256)'), ('row_label', 'STRING'),
      ('section', 'VARCHAR(64)'), ('unit', 'VARCHAR(64)'), ('entity', 'VARCHAR(64)'), ('measure', 'VARCHAR(64)'),
      ('value_num', 'DECIMAL(38,6)'), ('value_text', 'STRING')
  ]) }}
)
select
  a.batch_id, a.period_year, a.period_month, a.revision, a.file_name, a.uploaded_by, a.uploaded_at,
  CAST(CONCAT(CAST(a.period_year AS VARCHAR(4)), '-', LPAD(CAST(a.period_month AS VARCHAR(2)), 2, '0'), '-01') AS DATE) as period_from,
  c.sheet, c.row_no, c.row_ord, c.row_kind, c.row_key, c.row_label, c.section, c.unit, c.entity, c.measure,
  c.value_num, c.value_text
from active a
join c on c.batch_id = a.batch_id
