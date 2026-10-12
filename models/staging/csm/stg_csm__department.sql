{{ config(tags=['staging']) }}

-- CSM has never populated `department` upstream (source(csm, department) is
-- permanently empty). Business asked to keep a placeholder department list
-- long-term instead of an empty dimension; see seeds/seed_department.csv.
select *
from {{ ref('seed_department') }}
