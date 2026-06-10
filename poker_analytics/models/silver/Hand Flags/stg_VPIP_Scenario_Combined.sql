{{ config(materialized='table') }}

SELECT DISTINCT * 
FROM (
    SELECT *
    FROM {{ref('stg_VPIP_Scenario_Raise')}}

    UNION ALL

    SELECT *
    FROM {{ref('stg_VPIP_Scenario_CallBet')}}

    UNION ALL

    SELECT *
    FROM {{ref('stg_VPIP_Scenario_SmallBlind')}}

    UNION ALL 

    SELECT *
    FROM {{ ref('stg_VPIP_Scenario_Walk')}}
) AS SubQuery