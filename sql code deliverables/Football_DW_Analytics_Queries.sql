-- 1.	Home vs Away Performance for Each Team
;WITH PlayerMatch AS (
    SELECT
        p.TeamName,
        f.MatchFK,
        m.HomeTeam,
        m.AwayTeam,
        SUM(f.Goals) AS Goals,
        SUM(f.ShotsOnTarget) AS ShotsOnTarget,
        CASE 
            WHEN p.TeamName = m.HomeTeam THEN 'Home'
            WHEN p.TeamName = m.AwayTeam THEN 'Away'
            ELSE 'Neutral/Unknown'
        END AS HomeAwayFlag
    FROM FactPlayerPerformance f
    JOIN DimPlayer p
        ON f.PlayerFK = p.PlayerKey
    JOIN DimMatch m
        ON f.MatchFK = m.MatchKey
    GROUP BY
        p.TeamName,
        f.MatchFK,
        m.HomeTeam,
        m.AwayTeam
)
SELECT
    TeamName,
    HomeAwayFlag,
    COUNT(DISTINCT MatchFK) AS Matches,
    SUM(Goals) AS Goals,
    1.0 * SUM(Goals) / NULLIF(COUNT(DISTINCT MatchFK), 0) AS GoalsPerMatch
FROM PlayerMatch
WHERE
    HomeAwayFlag IN ('Home', 'Away')
GROUP BY
    TeamName,
    HomeAwayFlag
ORDER BY
    TeamName,
    HomeAwayFlag;



-- 2.	Discover the Weak Defensive Teams
;WITH TeamMatchGoals AS (
    SELECT
        f.MatchFK,
        p.TeamName,
        SUM(f.Goals) AS GoalsFor
    FROM FactPlayerPerformance f
    JOIN DimPlayer p
        ON f.PlayerFK = p.PlayerKey
    GROUP BY
        f.MatchFK,
        p.TeamName
),
TeamConceded AS (
    SELECT
        t1.TeamName,
        SUM(ISNULL(t2.GoalsFor, 0)) AS GoalsConceded
    FROM TeamMatchGoals t1
    LEFT JOIN TeamMatchGoals t2
        ON t1.MatchFK = t2.MatchFK
       AND t1.TeamName <> t2.TeamName
    GROUP BY
        t1.TeamName
)
SELECT
    TeamName,
    GoalsConceded
FROM TeamConceded
ORDER BY
    GoalsConceded DESC;     



-- 3.	 Nominate Player of the Season
SELECT TOP 1
    p.PlayerName,
    p.TeamName,
    SUM(f.Goals)        AS TotalGoals,
    SUM(f.Assists)      AS TotalAssists,
    SUM(f.Goals) + SUM(f.Assists) AS TotalContributions,
    COUNT(DISTINCT f.MatchFK) AS MatchesPlayed,
    SUM(f.MinutesPlayed) AS MinutesPlayed
FROM FactPlayerPerformance f
JOIN DimPlayer p
    ON f.PlayerFK = p.PlayerKey
GROUP BY
    p.PlayerName,
    p.TeamName
ORDER BY
    TotalContributions DESC,
    MinutesPlayed DESC;   


-- 4.	Discover the Weak Attacking Teams
SELECT
    p.TeamName,
    SUM(f.Goals) AS TotalGoals,
    COUNT(DISTINCT f.MatchFK) AS MatchesPlayed,
    SUM(f.Shots) AS TotalShots,
    SUM(f.ShotsOnTarget) AS TotalShotsOnTarget,
    1.0 * SUM(f.Goals) / NULLIF(COUNT(DISTINCT f.MatchFK), 0) AS GoalsPerMatch,
    1.0 * SUM(f.Goals) / NULLIF(SUM(f.ShotsOnTarget), 0)      AS ConversionFromShotsOnTarget
FROM FactPlayerPerformance f
JOIN DimPlayer p
    ON f.PlayerFK = p.PlayerKey
GROUP BY
    p.TeamName
HAVING
    COUNT(DISTINCT f.MatchFK) >= 5  
ORDER BY
    GoalsPerMatch ASC,               
    ConversionFromShotsOnTarget ASC;
