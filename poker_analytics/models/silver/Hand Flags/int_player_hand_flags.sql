{{ config(materialized='table') }}

SELECT hand_id, 
    player_name AS player_id, 
    CASE WHEN slv_players.position = 1 THEN 'Small Blind'
        WHEN slv_players.position = 2 THEN 'Big Blind'
    ELSE NULL END AS Blind_Position,
    CAST(NULL AS varchar(20)) AS is_vpip, 
    NULL AS is_pfr, 
    NULL AS is_three_bet_opportunity, 
    NULL AS did_three_bet
FROM {{ ref('slv_players') }}