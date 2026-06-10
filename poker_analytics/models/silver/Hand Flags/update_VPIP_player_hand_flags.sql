{{ config(materialized='table') }}

SELECT src.hand_id, 
    src.player_id, 
    src.Blind_Position,
    is_vpip = vpip.vpip, 
    NULL AS is_pfr, 
    NULL AS is_three_bet_opportunity, 
    NULL AS did_three_bet
FROM {{ ref('int_player_hand_flags') }} as src
    LEFT JOIN {{ ref('stg_VPIP_Scenario_Combined')}} AS vpip ON src.hand_id = vpip.hand_id
        AND src.player_id = vpip.player