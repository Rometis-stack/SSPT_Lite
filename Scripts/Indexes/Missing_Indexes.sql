/*
    RoMetis SQL Server Performance Toolkit Lite
    Script: Missing_Indexes.sql
    Purpose: Identify high-impact missing index candidates.
    Safety: Read-only
    Requirements: VIEW SERVER STATE
    Notes:
      - Missing index DMVs are suggestions, not automatic recommendations.
      - Always validate with workload, existing indexes and write impact.
      - Impact score is a prioritization aid, not a guaranteed improvement.
*/

SET NOCOUNT ON;

SELECT TOP (50)
    DB_NAME(mid.database_id) AS DatabaseName,
    OBJECT_SCHEMA_NAME(mid.object_id, mid.database_id) AS SchemaName,
    OBJECT_NAME(mid.object_id, mid.database_id) AS TableName,

    migs.user_seeks AS UserSeeks,
    migs.user_scans AS UserScans,
    CAST(migs.avg_total_user_cost AS DECIMAL(18,2)) AS AvgTotalUserCost,
    CAST(migs.avg_user_impact AS DECIMAL(18,2)) AS AvgUserImpactPercent,

    CAST(
        migs.avg_total_user_cost
        * migs.avg_user_impact
        * (migs.user_seeks + migs.user_scans)
        AS DECIMAL(18,2)
    ) AS EstimatedImprovementScore,

    mid.equality_columns AS EqualityColumns,
    mid.inequality_columns AS InequalityColumns,
    mid.included_columns AS IncludedColumns,

    'CREATE INDEX IX_' 
        + REPLACE(REPLACE(OBJECT_SCHEMA_NAME(mid.object_id, mid.database_id), '[', ''), ']', '')
        + '_' 
        + REPLACE(REPLACE(OBJECT_NAME(mid.object_id, mid.database_id), '[', ''), ']', '')
        + '_MissingIndexCandidate ON '
        + mid.statement
        + ' ('
        + ISNULL(mid.equality_columns, '')
        + CASE 
            WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ', '
            ELSE ''
          END
        + ISNULL(mid.inequality_columns, '')
        + ')'
        + CASE 
            WHEN mid.included_columns IS NOT NULL THEN ' INCLUDE (' + mid.included_columns + ')'
            ELSE ''
          END
        AS SuggestedCreateIndexStatement,

    migs.last_user_seek AS LastUserSeek,
    migs.last_user_scan AS LastUserScan
FROM sys.dm_db_missing_index_details AS mid
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats AS migs
    ON mig.index_group_handle = migs.group_handle
WHERE mid.database_id > 4
ORDER BY EstimatedImprovementScore DESC;
