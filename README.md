# 🏟️ Football Data Warehouse — Star Schema & ETL Pipeline

A data warehousing project built on **SQL Server** that models English Premier League football data using a star schema, implements a full **ETL pipeline** with staging, SCD Type 6 dimension loading, and automated fact table population — including scheduled job execution, email notifications, and analytical reporting queries.

---

## 🗂️ Project Structure

```
├── sql code deliverables/
│   ├── StarSchema.sql                    # Star schema DDL (dimensions + fact table)
│   ├── Staging.sql                       # Staging area table definitions
│   ├── SCD_SP.sql                        # SCD Type 6 stored procedure for DimPlayer
│   ├── FactSP.sql                        # Stored procedure to load FactPlayerPerformance
│   ├── runProcedure.sql                  # Script to execute ETL stored procedures
│   ├── runJob.bat                        # Batch file to trigger SQL Agent job
│   ├── send_mail_and_upload_v2.sql       # Email notification + data upload automation
│   └── Football_DW_Analytics_Queries.sql # Analytical queries on the DW
└── Star schema description.pdf           # Full schema documentation and design decisions
```

---

## 🏗️ Schema Design

### Fact Table
**`FactPlayerPerformance`** — the central grain is one row per player per match.

| Column | Description |
|--------|-------------|
| `PlayerFK` | Foreign key → DimPlayer |
| `TeamFK` | Foreign key → DimTeam |
| `MatchFK` | Foreign key → DimMatch |
| `DateFK` | Foreign key → DimDate |
| `StadiumFK` | Foreign key → DimStadium |
| `Goals` | Goals scored in match |
| `Assists` | Assists in match |
| `MinutesPlayed` | Minutes played (derived) |
| `Shots` | Total shots |
| `ShotsOnTarget` | Shots on target |

### Dimension Tables

| Table | Key Attributes |
|-------|---------------|
| `DimPlayer` | PlayerID, Name, Nationality, Age, Position, Team, Jersey No., SCD tracking columns |
| `DimTeam` | MatchID, HomeTeam, AwayTeam, HomeStadium |
| `DimMatch` | MatchID, HomeTeam, AwayTeam, Referee |
| `DimStadium` | StadiumName, City, Capacity, HomeTeam |
| `DimDate` | DateKey, FullDate, Day, Month, MonthName, Quarter, Year |

---

## 🔄 ETL Pipeline

### Stage 1 — Staging (`Staging.sql`)
Raw data is loaded into three staging tables before any transformation:
- `stg.MatchResults` — raw match outcomes
- `stg.PlayerStatsRaw` — raw player statistics (pre-cleaning)
- `stg.PlayerStats` — cleaned player stats with load timestamp (`LoadDate`)
- `stg.PointsTable` — league standings

### Stage 2 — Dimension Loading

#### SCD Type 6 on DimPlayer (`SCD_SP.sql`)
The `usp_LoadDimPlayer_SCD6_FromPlayerStats` stored procedure implements **Slowly Changing Dimension Type 6** (hybrid SCD 1+2+3) on the `DimPlayer` table:
- Tracks full history of player position and team changes (Type 2 — new row)
- Keeps current values accessible on all historical rows (Type 1 — overwrite `CurrentPosition`, `CurrentPlayerName`)
- Watermark-based incremental loading using `LoadDate`

#### Fact Loading (`FactSP.sql`)
The `usp_LoadFactPlayerPerformance` stored procedure:
- Loads facts in configurable batch sizes (default: 50 rows)
- Joins staging data to dimension surrogate keys
- Prevents duplicate inserts with an `EXISTS` check
- Loops until all unprocessed staging rows are loaded

### Stage 3 — Automation
- `runJob.bat` — triggers the SQL Agent job from the command line
- `send_mail_and_upload_v2.sql` — sends automated email notifications on ETL completion/failure and handles upload logging
- `runProcedure.sql` — manual script to run stored procedures in the correct order

---

## 📊 Analytical Queries (`Football_DW_Analytics_Queries.sql`)

Pre-built analytical queries on the data warehouse including:

1. **Home vs Away Performance per Team** — goals and shots per match split by home/away using conditional aggregation
2. Additional queries covering player rankings, match-level performance, and team comparisons

Queries are written against the star schema using standard DW join patterns (fact + dimensions).

---

## ⚙️ Setup & Execution

### Prerequisites
- SQL Server (2016+) with SQL Server Agent enabled
- Database Mail configured (for email notifications)

### Steps
```sql
-- 1. Create the star schema
-- Run: StarSchema.sql

-- 2. Create staging tables
-- Run: Staging.sql

-- 3. Create stored procedures
-- Run: SCD_SP.sql
-- Run: FactSP.sql
-- Run: send_mail_and_upload_v2.sql

-- 4. Load data (manual)
-- Run: runProcedure.sql

-- 5. Or trigger via SQL Agent job
-- Run: runJob.bat (from command line)

-- 6. Run analytics
-- Run: Football_DW_Analytics_Queries.sql
```

---

## 👥 Team Members

| Student ID |
|------------|
| Malak      |
| Jumanah    |
| Laila      |
| Basmalah   |
