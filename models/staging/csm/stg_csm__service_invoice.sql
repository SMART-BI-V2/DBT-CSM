{{ config(tags=['staging']) }}

select {{ csm_trim('`SourceCode`') }} as `SourceCode`, {{ csm_trim('CAST(`DocumentType` AS VARCHAR(16))') }} as `DocumentType`, `DocumentNo`, `ExternalDocumentNo`, `PostingDate`, `Amount`
from {{ source('csm', 'service_invoice') }}
