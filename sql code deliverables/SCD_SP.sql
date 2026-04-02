CREATE OR ALTER PROCEDURE dbo.usp_LoadDimPlayer_SCD6_FromPlayerStats
(
    @LastWatermark DATETIME2(3)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RunDate DATETIME2(3) = SYSUTCDATETIME();


    IF OBJECT_ID('tempdb..#Src') IS NOT NULL
        DROP TABLE #Src;

    ;WITH SrcRaw AS (
        SELECT
              Team
            , JerseyNo
            , Player
            , Position
            , LoadDate
            , ROW_NUMBER() OVER (
                  PARTITION BY Team, JerseyNo
                  ORDER BY LoadDate DESC
              ) AS rn
        FROM stg.PlayerStats
        WHERE LoadDate >= @LastWatermark
    )
    SELECT
          Team
        , JerseyNo
        , Player
        , Position
        , LoadDate
    INTO #Src
    FROM SrcRaw
    WHERE rn = 1;  


    INSERT INTO dbo.DimPlayer (
          PlayerID
        , PlayerName
        , Position
        , Age
        , EffectiveDate
        , ExpiryDate
        , CurrentFlag
        , TeamName
        , JerseyNo
        , CurrentPosition
        , CurrentPlayerName
        , Nationality
    )
    SELECT
          NULL
        , s.Player
        , s.Position
        , NULL
        , @RunDate
        , CONVERT(DATETIME2(3),'9999-12-31')
        , 1
        , s.Team
        , s.JerseyNo
        , s.Position
        , s.Player
        , NULL
    FROM #Src s
    LEFT JOIN dbo.DimPlayer d
        ON  d.TeamName    = s.Team
        AND d.JerseyNo    = s.JerseyNo
        AND d.CurrentFlag = 1
    WHERE d.PlayerKey IS NULL;


    IF OBJECT_ID('tempdb..#Changed') IS NOT NULL
        DROP TABLE #Changed;

    SELECT
          d.PlayerKey
        , d.PlayerID
        , d.TeamName
        , d.JerseyNo
        , d.PlayerName      AS OldPlayerName
        , d.Position        AS OldPosition
        , d.Age
        , d.Nationality
        , s.Player          AS NewPlayerName
        , s.Position        AS NewPosition
    INTO #Changed
    FROM dbo.DimPlayer d
    JOIN #Src s
      ON  d.TeamName    = s.Team
      AND d.JerseyNo    = s.JerseyNo
      AND d.CurrentFlag = 1
    WHERE ISNULL(s.Position , '') <> ISNULL(d.Position   , '')
       OR ISNULL(s.Player   , '') <> ISNULL(d.PlayerName , '');

    IF NOT EXISTS (SELECT 1 FROM #Changed)
        RETURN;

    UPDATE d
    SET   d.ExpiryDate = DATEADD(DAY, -1, @RunDate),
          d.CurrentFlag = 0
    FROM dbo.DimPlayer d
    JOIN #Changed c
      ON d.PlayerKey = c.PlayerKey;


    INSERT INTO dbo.DimPlayer (
          PlayerID
        , PlayerName
        , Position
        , Age
        , EffectiveDate
        , ExpiryDate
        , CurrentFlag
        , TeamName
        , JerseyNo
        , CurrentPosition
        , CurrentPlayerName
        , Nationality
    )
    SELECT
          c.PlayerID
        , c.NewPlayerName
        , c.NewPosition
        , c.Age
        , @RunDate
        , CONVERT(DATETIME2(3),'9999-12-31')
        , 1
        , c.TeamName
        , c.JerseyNo
        , c.NewPosition
        , c.NewPlayerName
        , c.Nationality
    FROM #Changed c;


    UPDATE d
    SET   d.CurrentPosition   = c.NewPosition,
          d.CurrentPlayerName = c.NewPlayerName
    FROM dbo.DimPlayer d
    JOIN #Changed c
      ON d.TeamName = c.TeamName
     AND d.JerseyNo = c.JerseyNo;

END;
GO
