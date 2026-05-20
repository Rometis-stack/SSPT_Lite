/*
    RoMetis SQL Server Performance Toolkit Lite
    Script: HealthSummary.sql
    Purpose: Provide a lightweight SQL Server performance health summary.
    Safety: Read-only
    Requirements: VIEW SERVER STATE
    Notes:
      - Thresholds are intentionally simple for Lite version.
      - Use detailed scripts to investigate warnings and critical findings.
*/

SET NOCOUNT ON;

DECLARE 
    @BlockingSessions INT = 0,
    @MissingIndexes INT = 0,
    @HighCpuQueries INT = 0,
    @LargeDatabases INT = 0,
    @SmallGrowthFiles INT = 0,
    @PercentGrowthFiles INT = 0;

-- Active blocking
SELECT 
    @BlockingSessions = COUNT(*)
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;

-- Missing indexes with meaningful impact
SELECT 
    @MissingIndexes = COUNT(*)
FROM sys.dm_db_missing_index_details AS mid
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats AS migs
    ON mig.index_group_handle = migs.group_handle
WHERE 
    mid.database_id > 4
    AND migs.avg_user_impact >= 70
    AND (migs.user_seeks + migs.user_scans) >= 10;

-- Queries with average CPU above 500 ms
SELECT 
    @HighCpuQueries = COUNT(*)
FROM sys.dm_exec_query_stats
WHERE 
    (total_worker_time / NULLIF(execution_count, 0)) / 1000.0 >= 500;

-- Databases with data files over 10 GB
SELECT 
    @LargeDatabases = COUNT(DISTINCT database_id)
FROM sys.master_files
WHERE 
    database_id > 4
    AND type_desc = 'ROWS'
    AND (size * 8.0 / 1024 / 1024) >= 10;

-- Small fixed-growth files below 64 MB
SELECT
    @SmallGrowthFiles = COUNT(*)
FROM sys.master_files
WHERE
    database_id > 4
    AND is_percent_growth = 0
    AND growth > 0
    AND (growth * 8.0 / 1024) < 64;

-- Percentage growth files
SELECT
    @PercentGrowthFiles = COUNT(*)
FROM sys.master_files
WHERE
    database_id > 4
    AND is_percent_growth = 1;

;WITH HealthChecks AS
(
    SELECT
        'Blocking' AS Category,
        @BlockingSessions AS FindingCount,
        CASE
            WHEN @BlockingSessions = 0 THEN 'Healthy'
            WHEN @BlockingSessions BETWEEN 1 AND 5 THEN 'Warning'
            ELSE 'Critical'
        END AS Status,
        'Active blocked sessions detected.' AS Description,
        'Run Scripts/Blocking/Active_Blocking.sql' AS RecommendedNextStep

    UNION ALL

    SELECT
        'Missing Indexes',
        @MissingIndexes,
        CASE
            WHEN @MissingIndexes = 0 THEN 'Healthy'
            WHEN @MissingIndexes BETWEEN 1 AND 10 THEN 'Warning'
            ELSE 'Critical'
        END,
        'Potential high-impact missing index candidates detected.',
        'Run Scripts/Indexes/Missing_Indexes.sql and validate against workload.'

    UNION ALL

    SELECT
        'CPU',
        @HighCpuQueries,
        CASE
            WHEN @HighCpuQueries = 0 THEN 'Healthy'
            WHEN @HighCpuQueries BETWEEN 1 AND 10 THEN 'Warning'
            ELSE 'Critical'
        END,
        'Queries with average CPU time above 500 ms detected in plan cache.',
        'Run Scripts/CPU/Expensive_Queries.sql or Top_CPU_Queries.sql.'

    UNION ALL

    SELECT
        'Storage Size',
        @LargeDatabases,
        CASE
            WHEN @LargeDatabases = 0 THEN 'Healthy'
            WHEN @LargeDatabases BETWEEN 1 AND 5 THEN 'Review'
            ELSE 'Warning'
        END,
        'User databases with data files larger than 10 GB detected.',
        'Run Scripts/Storage/DatabaseGrowth.sql.'

    UNION ALL

    SELECT
        'File Growth',
        @SmallGrowthFiles + @PercentGrowthFiles,
        CASE
            WHEN (@SmallGrowthFiles + @PercentGrowthFiles) = 0 THEN 'Healthy'
            WHEN (@SmallGrowthFiles + @PercentGrowthFiles) BETWEEN 1 AND 10 THEN 'Review'
            ELSE 'Warning'
        END,
        'Files with percentage growth or very small fixed growth detected.',
        'Review growth settings in Scripts/Storage/DatabaseGrowth.sql.'
)
SELECT
    Category,
    FindingCount,
    Status,
    Description,
    RecommendedNextStep
FROM HealthChecks
ORDER BY
    CASE Status
        WHEN 'Critical' THEN 1
        WHEN 'Warning' THEN 2
        WHEN 'Review' THEN 3
        WHEN 'Healthy' THEN 4
        ELSE 5
    END,
    Category;
