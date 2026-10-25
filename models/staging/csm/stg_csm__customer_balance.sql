{{ config(tags=['staging']) }}

select {{ csm_code('`CustomerNo`') }} as `CustomerNo`, `PostingDate`,
  `Amount`, `DebitAmount`, `CreditAmount`, `AmountLCY`, `DebitAmountLCY`, `CreditAmountLCY`
from {{ source('csm', 'customer_balance') }}
