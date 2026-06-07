{{ config(materialized='table') }}

select {{ dbt_utils.generate_surrogate_key(['hand_id']) }} AS hand_id,
    player,
    action,
    amount,
    action_seq,
    street
from {{ source('raw_poker', 'actions') }}