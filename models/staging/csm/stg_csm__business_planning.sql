{{ config(tags=['staging']) }}

-- Chưa có trong raw_stage (dev cũng rỗng) ⇒ tập rỗng đúng kiểu cho tới khi đối tác nạp.
{{ csm_source_or_empty('business_planning', [
    ('PostingDate', 'DATE'), ('Kind', 'INT'), ('IndustrialValue', 'DECIMAL(28,10)'),
    ('IndustrialValueActual', 'DECIMAL(28,10)'), ('Amount', 'DECIMAL(28,10)'), ('IndustrialAmount', 'DECIMAL(28,10)'),
    ('InlandAmount', 'DECIMAL(28,10)'), ('ExportAmount', 'DECIMAL(28,10)'), ('BusinessAmount', 'DECIMAL(28,10)'),
    ('Worker', 'INT'), ('Salary', 'DECIMAL(28,10)'), ('ProfitAmount', 'DECIMAL(28,10)')
]) }}
