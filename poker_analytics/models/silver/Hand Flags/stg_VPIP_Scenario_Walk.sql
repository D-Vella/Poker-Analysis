{{ config(materialized='table') }}

-- WALKS - Player Pays Big Blind and all others fold.

WITH CTE_Tables_Players_Fold AS (
    SELECT Hand_id, COUNT(*) AS Actions,
        SUM(CASE WHEN action = 'fold' THEN 1 ELSE 0 END) AS FoldCount
    FROM {{ ref('slv_actions')}}
    WHERE street = 'preflop'
    GROUP BY Hand_id
    HAVING COUNT(*) = SUM(CASE WHEN action = 'fold' THEN 1 ELSE 0 END)
)

SELECT src.hand_id, player, 'WALK' AS VPIP
FROM {{ref('slv_actions')}} AS src
    JOIN CTE_Tables_Players_Fold ON src.hand_id = CTE_Tables_Players_Fold.hand_id
    LEFT JOIN {{ ref('slv_players')}} AS Players ON src.player = Players.Player_name
        AND src.hand_id = Players.hand_id
WHERE street = 'preflop'
    AND position = 1 -- Big Blind
