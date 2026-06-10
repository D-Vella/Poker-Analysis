{{ config(materialized='table') }}

-- Raises
SELECT hand_id, player, 'VPIP' AS VPIP
FROM {{ref('slv_actions')}}
WHERE street = 'preflop'
    AND action = 'raise'