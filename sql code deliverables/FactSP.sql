CREATE OR ALTER PROCEDURE dbo.usp_LoadFactPlayerPerformance
(
    @BatchSize INT = 50
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @rowCount INT = 1;

    WHILE @rowCount > 0
    BEGIN
        INSERT INTO FactPlayerPerformance (
              PlayerFK,
              TeamFK,
              MatchFK,
              DateFK,
              StadiumFK,
              Goals,
              Assists,
              MinutesPlayed,
              Shots,
              ShotsOnTarget
        )
        SELECT TOP (@BatchSize)
              p.PlayerKey,
              t.TeamKey,
              m.MatchKey,
              d.DateKey,
              NULL,
              ps.Goals,
              0,                       
              ps.Appearances * 90,      
              0,
              0
        FROM stg.PlayerStats ps
        JOIN DimPlayer p
          ON p.PlayerName  = ps.Player
         AND p.TeamName    = ps.Team
         AND p.CurrentFlag = 1
        JOIN stg.MatchResults mr
          ON mr.HomeTeam = ps.Team
          OR mr.AwayTeam = ps.Team
        JOIN DimTeam t
          ON t.HomeTeam = mr.HomeTeam
         AND t.AwayTeam = mr.AwayTeam
        JOIN DimMatch m
          ON m.HomeTeam = mr.HomeTeam
         AND m.AwayTeam = mr.AwayTeam
        JOIN DimDate d
          ON d.FullDate = CAST(mr.Date AS DATE)
        WHERE NOT EXISTS (
            SELECT 1
            FROM FactPlayerPerformance f
            WHERE f.PlayerFK = p.PlayerKey
              AND f.TeamFK   = t.TeamKey
              AND f.MatchFK  = m.MatchKey
        );

        SET @rowCount = @@ROWCOUNT;
    END;
END;
GO
