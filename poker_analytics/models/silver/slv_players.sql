{{ config(materialized='table') }}

select {{ dbt_utils.generate_surrogate_key(['hand_id']) }} AS hand_id,
    player_name,
    seat,
    position,
    starting_stack,
    amount_won_lost
from {{ source('raw_poker', 'players') }}