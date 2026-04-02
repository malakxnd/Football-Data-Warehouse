create TABLE DimPlayer (
    PlayerKey INT IDENTITY(1,1) PRIMARY KEY, 
    PlayerID INT NULL,                       
    Nationality VARCHAR(100),
    Age INT,


    TeamName VARCHAR(200),
    JerseyNo INT,
    PlayerName VARCHAR(200),
    Position VARCHAR(50),


    EffectiveDate DATETIME,
    ExpiryDate DATETIME,
    CurrentFlag BIT,


    CurrentPosition VARCHAR(50),
    CurrentPlayerName VARCHAR(100)
);


CREATE TABLE DimTeam (
    TeamKey INT IDENTITY(1,1) PRIMARY KEY,
    MatchID INT,
    HomeTeam VARCHAR(200),
    AwayTeam VARCHAR(200),
    HomeStadium VARCHAR(200),
);

CREATE TABLE DimMatch (
    MatchKey INT IDENTITY(1,1) PRIMARY KEY,
    MatchID INT,
    HomeTeam VARCHAR(200),
    AwayTeam VARCHAR(200),
    Referee VARCHAR(200)
);

CREATE TABLE DimStadium (
    StadiumKey INT IDENTITY(1,1) PRIMARY KEY,
    StadiumName VARCHAR(200),
    City VARCHAR(200),
    Capacity INT,
    HomeTeam VARCHAR(200)
);

CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,       
    FullDate DATE,
    Day INT,
    Month INT,
    MonthName VARCHAR(20),
    Quarter INT,
    Year INT
);

create TABLE FactPlayerPerformance (
    FactKey INT IDENTITY(1,1) PRIMARY KEY,

    PlayerFK INT,
    TeamFK INT,
    MatchFK INT,
    DateFK INT,
    StadiumFK INT,


    Goals INT,
    Assists INT,
    MinutesPlayed INT,
    Shots INT,
    ShotsOnTarget INT,


    FOREIGN KEY (PlayerFK) REFERENCES DimPlayer(PlayerKey),
    FOREIGN KEY (TeamFK) REFERENCES DimTeam(TeamKey),
    FOREIGN KEY (MatchFK) REFERENCES DimMatch(MatchKey),
    FOREIGN KEY (DateFK) REFERENCES DimDate(DateKey),
    FOREIGN KEY (StadiumFK) REFERENCES DimStadium(StadiumKey)
);

