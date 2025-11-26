DECLARE @TargetDate DATETIME = GETDATE();

WITH ActiveSubs AS (
    SELECT DISTINCT
        s.Msisdn,
        s.SubscriptionPlanId,
        s.Payment_GateWay,
        s.ThirdPartyId,
        s.EffectiveAmount
    FROM dbo.Subscriptions s WITH (NOLOCK)
    WHERE
        s.ActiveFrom <= @TargetDate
        AND s.ActiveTo  > @TargetDate
        AND s.IsDeleted = 0
        AND s.Status    = 2
),
Cal AS (
    SELECT
        CAST(GregorianDate AS DATE) AS stat_date,
        PersianYear,
        PersianMonth,
        PersianDay
    FROM [Common].[Calendar]
    WHERE CAST(GregorianDate AS DATE) = CAST(@TargetDate AS DATE)
),
Agg AS (
    SELECT
        c.stat_date                                        AS [date],
        CONCAT(c.PersianYear, '-', c.PersianMonth, '-', c.PersianDay) AS persian_date,

        a.SubscriptionPlanId                               AS subscription_plan_id,
        a.Payment_GateWay                                  AS gateway,
        a.ThirdPartyId                                     AS thirdparty_id,

        COUNT(*)                                           AS active,
        SUM(CASE WHEN a.EffectiveAmount = 0 THEN 1 ELSE 0 END) AS active_free,
        SUM(CASE WHEN a.EffectiveAmount > 0 THEN 1 ELSE 0 END) AS active_non_free,

        CONCAT(
            CAST(a.SubscriptionPlanId AS nvarchar(50)), '-',
            CAST(a.Payment_GateWay    AS nvarchar(10)), '-',
            ISNULL(CAST(a.ThirdPartyId AS nvarchar(100)), 'null')
        )                                                  AS k
    FROM ActiveSubs a
    CROSS JOIN Cal c
    GROUP BY
        c.stat_date,
        c.PersianYear,
        c.PersianMonth,
        c.PersianDay,
        a.SubscriptionPlanId,
        a.Payment_GateWay,
        a.ThirdPartyId
)

SELECT
    [date],
    persian_date,

    SUM(active)          AS active,
    SUM(active_free)     AS active_free,
    SUM(active_non_free) AS active_non_free,

    '{ "active_non_free": {'
        +
        STRING_AGG(
            CASE 
                WHEN gateway IS NOT NULL AND gateway <> 0
                THEN '"' + k + '": ' + CAST(active_non_free AS nvarchar(20))
            END,
            ','
        )
        +
        '}, "active_free": {'
        +
        STRING_AGG(
            '"' + k + '": ' + CAST(active_free AS nvarchar(20)),
            ','
        )
        +
    '} }' AS detail

FROM Agg
GROUP BY
    [date],
    persian_date
ORDER BY
    [date];
