CREATE OR ALTER PROCEDURE dbo.usp_LoadEPL_21_22
(
    @MatchCsvPath  NVARCHAR(4000),
    @PlayerCsvPath NVARCHAR(4000),
    @PointsCsvPath NVARCHAR(4000),
    @BatchSize     INT = 50,  
    @AdminEmail    NVARCHAR(256) = 'lailashawky44@gmail.com'
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start      DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @errorMsg   NVARCHAR(MAX);  
    DECLARE @matchRows  INT = 0,
            @playerRows INT = 0,
            @pointsRows INT = 0;
    DECLARE @sql        NVARCHAR(MAX);

    BEGIN TRY


        TRUNCATE TABLE stg.MatchResults;
        TRUNCATE TABLE stg.PlayerStats;
        TRUNCATE TABLE stg.PlayerStatsRaw;
        TRUNCATE TABLE stg.PointsTable;


        SET @sql = N'BULK INSERT stg.MatchResults
        FROM ' + QUOTENAME(@MatchCsvPath, '''') + N'
        WITH (
              FIRSTROW        = 2,
              FIELDTERMINATOR = '','',
              ROWTERMINATOR   = ''0x0A'',
              CODEPAGE        = ''65001'',
              TABLOCK
        );';

        EXEC sp_executesql @sql;

        SELECT @matchRows = COUNT(*) FROM stg.MatchResults;


        SET @sql = N'BULK INSERT stg.PlayerStatsRaw
        FROM ' + QUOTENAME(@PlayerCsvPath, '''') + N'
        WITH (
              FIRSTROW        = 2,
              FIELDTERMINATOR = '','',
              ROWTERMINATOR   = ''\n'',
              CODEPAGE        = ''65001'',
              TABLOCK
        );';

        EXEC sp_executesql @sql;

        SELECT @playerRows = COUNT(*) FROM stg.PlayerStatsRaw;


        SET @sql = N'BULK INSERT stg.PointsTable
        FROM ' + QUOTENAME(@PointsCsvPath, '''') + N'
        WITH (
              FIRSTROW        = 2,
              FIELDTERMINATOR = '','',
              ROWTERMINATOR   = ''0x0A'',
              CODEPAGE        = ''65001'',
              TABLOCK
        );';

        EXEC sp_executesql @sql;

        SELECT @pointsRows = COUNT(*) FROM stg.PointsTable;


        BEGIN TRANSACTION;


        INSERT INTO stg.PlayerStats (
              Team,
              JerseyNo,
              Player,
              Position,
              Appearances,
              Substitutions,
              Goals,
              Penalties,
              YellowCards,
              RedCards,
              LoadDate
        )
        SELECT
              Team,
              JerseyNo,
              Player,
              Position,
              Appearances,
              Substitutions,
              Goals,
              Penalties,
              YellowCards,
              RedCards,
              SYSUTCDATETIME()
        FROM stg.PlayerStatsRaw;


        INSERT INTO DimDate (DateKey, FullDate, Day, Month, MonthName, Quarter, Year)
        SELECT DISTINCT
            CONVERT(INT, FORMAT(CAST(mr.Date AS DATE), 'yyyyMMdd')),
            CAST(mr.Date AS DATE),
            DAY(CAST(mr.Date AS DATE)),
            MONTH(CAST(mr.Date AS DATE)),
            DATENAME(MONTH, CAST(mr.Date AS DATE)),
            DATEPART(QUARTER, CAST(mr.Date AS DATE)),
            YEAR(CAST(mr.Date AS DATE))
        FROM stg.MatchResults mr
        WHERE NOT EXISTS (
            SELECT 1
            FROM DimDate d
            WHERE d.FullDate = CAST(mr.Date AS DATE)
        );


        INSERT INTO DimTeam (HomeTeam, AwayTeam, HomeStadium)
        SELECT DISTINCT
            mr.HomeTeam,
            mr.AwayTeam,
            NULL
        FROM stg.MatchResults mr
        WHERE NOT EXISTS (
            SELECT 1
            FROM DimTeam t
            WHERE t.HomeTeam = mr.HomeTeam
              AND t.AwayTeam = mr.AwayTeam
        );


        INSERT INTO DimMatch (MatchID, HomeTeam, AwayTeam, Referee)
        SELECT DISTINCT
            ROW_NUMBER() OVER (ORDER BY CAST(mr.Date AS DATE), mr.HomeTeam, mr.AwayTeam) AS MatchID,
            mr.HomeTeam,
            mr.AwayTeam,
            NULL
        FROM stg.MatchResults mr
        WHERE NOT EXISTS (
            SELECT 1
            FROM DimMatch m
            WHERE m.HomeTeam = mr.HomeTeam
              AND m.AwayTeam = mr.AwayTeam
        );


        COMMIT TRANSACTION;

        DECLARE @body NVARCHAR(MAX);

        SET @body  = 'ETL Load SUCCESS' + CHAR(13) + CHAR(10);
        SET @body += 'Match rows: '  + CAST(@matchRows  AS NVARCHAR(20)) + CHAR(13) + CHAR(10);
        SET @body += 'Player rows: ' + CAST(@playerRows AS NVARCHAR(20)) + CHAR(13) + CHAR(10);
        SET @body += 'Points rows: ' + CAST(@pointsRows AS NVARCHAR(20)) + CHAR(13) + CHAR(10);
        SET @body += 'Start time: '  + CAST(@start AS NVARCHAR(30)) + CHAR(13) + CHAR(10);
        SET @body += 'End time: '    + CAST(SYSUTCDATETIME() AS NVARCHAR(30));

        EXEC msdb.dbo.sp_send_dbmail
             @profile_name = 'SampleProfile',
             @recipients   = @AdminEmail,
             @subject      = 'EPL 21-22 ETL Success',
             @body         = @body;

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @bodyError NVARCHAR(MAX);

        SET @errorMsg  = ERROR_MESSAGE();   
        SET @bodyError = N'An error occurred during ETL. Error: ' + ISNULL(@errorMsg, N'');

        EXEC msdb.dbo.sp_send_dbmail
             @profile_name = 'SampleProfile',
             @recipients   = @AdminEmail,
             @subject      = 'EPL 21-22 ETL FAILURE',
             @body         = @bodyError;

        THROW;
    END CATCH
END;
GO




EXEC dbo.usp_LoadEPL_21_22
  @MatchCsvPath  = 'D:\1. GPA\Advanced Database\Assignment 1 2025\all_match_results.csv',
  @PlayerCsvPath = 'D:\1. GPA\Advanced Database\Assignment 1 2025\all_players_stats.csv',
  @PointsCsvPath = 'D:\1. GPA\Advanced Database\Assignment 1 2025\points_table.csv',
  @AdminEmail    = 'lailashawky44@gmail.com';


DECLARE @LastWatermark DATETIME2(3) = '2000-01-01 00:00:00.000';

EXEC dbo.usp_LoadDimPlayer_SCD6_FromPlayerStats @LastWatermark;


EXEC dbo.usp_LoadFactPlayerPerformance @BatchSize = 50;


SELECT COUNT(*) AS DimPlayerCount FROM DimPlayer;
SELECT COUNT(*) AS FactCount      FROM FactPlayerPerformance;

SELECT TOP 10 * FROM DimPlayer;
SELECT TOP 10 * FROM FactPlayerPerformance;