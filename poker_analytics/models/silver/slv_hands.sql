{{ config(materialized='table') }}

select *
from {{ source('raw_poker', 'hands') }}