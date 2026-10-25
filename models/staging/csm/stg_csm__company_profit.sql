{{ config(tags=['staging']) }}

select `RowID`, `Lecture`, `Description`, `AccountName`, `Ord`, `Amount`, `PostingDate`, `SystemDate`
from {{ source('csm', 'company_profit') }}
