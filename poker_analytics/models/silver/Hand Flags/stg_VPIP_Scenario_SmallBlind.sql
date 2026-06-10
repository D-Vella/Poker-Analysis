{{ config(materialized='table') }}

-- Playwe who pays the small blind but calls.
SELECT Actions.hand_id, player, 'VPIP' AS VPIP
FROM {{ref('slv_actions')}} AS Actions
    LEFT JOIN {{ ref('slv_players')}} AS Players ON Actions.player = Players.Player_name
        AND Actions.hand_id = Players.hand_id
WHERE street = 'preflop'
    AND action = 'call'
    AND position = 2 --small blind