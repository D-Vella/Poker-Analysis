{{ config(materialized='table') }}

SELECT hand_id, 
    player_name AS player_id, 
    NULL AS is_vpip, 
    NULL AS is_pfr, 
    NULL AS is_three_bet_opportunity, 
    NULL AS did_three_bet
FROM {{ ref('slv_players') }}