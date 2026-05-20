/*
    RoMetis SQL Server Performance Toolkit Lite
    Script: DatabaseGrowth.sql
    Purpose: Show database file sizes, free space and growth configuration.
    Safety: Read-only
    Requirements:
      - Public metadata access for sys.master_files
      - VIEW SERVER STATE may improve visibility depending on environment
    Notes:
      - Current size only; historical growth requires collection over time.
*/

SET NOCOUNT ON;

SELECT
    DB_NAME(mf.database_id) AS DatabaseName,
    mf.name AS LogicalFileName,
    mf.type_desc AS FileType,
    mf.physical_name AS PhysicalFileName,

    CAST(mf.size * 8.0 / 1024 AS DECIMAL(18,2)) AS CurrentSizeMB,
    CAST(mf.size * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS CurrentSizeGB,

    CASE 
        WHEN mf.max_size = -1 THEN 'Unlimited'
        WHEN mf.max_size = 0 THEN 'No growth allowed'
        ELSE CAST(CAST(mf.max_size * 8.0 / 1024 AS DECIMAL(18,2)) AS VARCHAR(50)) + ' MB'
    END AS MaxSize,

    CASE 
        WHEN mf.is_percent_growth = 1 THEN CAST(mf.growth AS VARCHAR(20)) + '%'
        ELSE CAST(CAST(mf.growth * 8.0 / 1024 AS DECIMAL(18,2)) AS VARCHAR(50)) + ' MB'
    END AS GrowthSetting,

    mf.is_percent_growth AS IsPercentGrowth,

    CASE 
        WHEN mf.is_percent_growth = 1 AND mf.growth >= 10 THEN 'Review percentage growth setting'
        WHEN mf.is_percent_growth = 0 AND mf.growth * 8.0 / 1024 < 64 THEN 'Review small fixed growth setting'
        ELSE 'OK'
    END AS GrowthConfigurationReview
FROM sys.master_files AS mf
WHERE DB_NAME(mf.database_id) IS NOT NULL
ORDER BY
    DB_NAME(mf.database_id),
    mf.type_desc,
    mf.name;
