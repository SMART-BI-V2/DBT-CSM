{{ config(tags=['staging']) }}

select `AccountNo`, `AccountName`, `AccountType`, {{ csm_trim('`SourceCode`') }} as `SourceCode`, `PostingDate`,
  `BegDebitAmount`, `BegCreditAmount`, `DebitAmount`, `CreditAmount`, `EndDebitAmount`, `EndCreditAmount`
from {{ source('csm', 'balance_account') }}
