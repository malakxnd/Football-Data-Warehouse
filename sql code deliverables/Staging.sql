
DROP TABLE IF EXISTS stg.MatchResults;
CREATE TABLE stg.MatchResults (
    Date VARCHAR(50),
    HomeTeam VARCHAR(200),
    Result VARCHAR(10),
    AwayTeam VARCHAR(200)
);


DROP TABLE IF EXISTS stg.PlayerStatsRaw;
CREATE TABLE stg.PlayerStatsRaw (
    Team VARCHAR(200),
    JerseyNo INT,
    Player VARCHAR(200),
    Position VARCHAR(50),
    Appearances INT, 
    Substitutions INT, 
    Goals INT, 
    Penalties INT , 
    YellowCards VARCHAR(50),  
    RedCards VARCHAR(50), 

);


DROP TABLE IF EXISTS stg.PlayerStats;
CREATE TABLE stg.PlayerStats (
    Team VARCHAR(200),
    JerseyNo INT,
    Player VARCHAR(200),
    Position VARCHAR(50),
    Appearances INT, 
    Substitutions INT, 
    Goals INT, 
    Penalties INT , 
    YellowCards VARCHAR(50),  
    RedCards VARCHAR(50), 
    LoadDate DATETIME2(3) NOT NULL DEFAULT (SYSUTCDATETIME())  
);


DROP TABLE IF EXISTS stg.PointsTable;
create TABLE stg.PointsTable (
    Pos INT,
    Team VARCHAR(200),
    Pld INT,
    W INT,
    D INT,
    L INT,
    GF INT,
    GA INT,
    GD INT,
    Pts INT
);
GO

