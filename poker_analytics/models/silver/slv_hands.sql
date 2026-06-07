{{ config(materialized='table') }}

select {{ dbt_utils.generate_surrogate_key(['id']) }} AS id,
    stakes,
    small_blind,
    big_blind,
    board
from {{ source('raw_poker', 'hands') }}