{{ config(materialized='table') }}

-- VPIP: Calling an earlier bet


WITH CTE_BETS AS (
    SELECT hand_id, min(action_seq) AS first_rase_seq
    FROM {{ref('slv_actions')}} as src   
    WHERE action = 'raise' 
    GROUP BY hand_id
)

SELECT src.hand_id, src.player, 'VPIP' AS VPIP
FROM {{ref('slv_actions')}} as src
    JOIN CTE_BETS ON src.hand_id = CTE_BETS.hand_id
        AND src.action_seq > CTE_BETS.first_rase_seq
WHERE street = 'preflop'
    AND action = 'call'