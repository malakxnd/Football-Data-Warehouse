USE EPL_2021_22;
EXEC dbo.usp_LoadEPL_21_22
    @MatchCsvPath = 'C:\Users\HP\Desktop\Uni\matchdata\all_match_results.csv',
    @PlayerCsvPath = 'C:\Users\HP\Desktop\Uni\matchdata\all_players_stats.csv',
    @PointsCsvPath = 'C:\Users\HP\Desktop\Uni\matchdata\points_table.csv';
GO
