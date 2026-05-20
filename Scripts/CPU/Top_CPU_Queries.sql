/*
    RoMetis SQL Server Performance Toolkit Lite
    Script: Top_CPU_Queries.sql
    Purpose: Show cached queries with the highest total CPU usage.
    Safety: Read-only
    Requirements: VIEW SERVER STATE
    Notes:
      - Based on current plan cache.
      - CPU values are shown in milliseconds.
*/

SET NOCOUNT ON;

SELECT TOP (25)
    DB_NAME(COALESCE(st.dbid, CONVERT(INT, pa.value))) AS DatabaseName,
    OBJECT_SCHEMA_NAME(st.objectid, st.dbid) AS ObjectSchema,
    OBJECT_NAME(st.objectid, st.dbid) AS ObjectName,
    qs.execution_count AS ExecutionCount,

    CAST(qs.total_worker_time / 1000.0 AS DECIMAL(18,2)) AS TotalCPU_ms,
    CAST((qs.total_worker_time / NULLIF(qs.execution_count, 0)) / 1000.0 AS DECIMAL(18,2)) AS AvgCPU_ms,

    CAST(qs.total_elapsed_time / 1000.0 AS DECIMAL(18,2)) AS TotalDuration_ms,
    CAST((qs.total_elapsed_time / NULLIF(qs.execution_count, 0)) / 1000.0 AS DECIMAL(18,2)) AS AvgDuration_ms,

    qs.total_logical_reads AS TotalLogicalReads,
    qs.total_logical_reads / NULLIF(qs.execution_count, 0) AS AvgLogicalReads,

    qs.creation_time AS PlanCreationTime,
    qs.last_execution_time AS LastExecutionTime,

    SUBSTRING(
        st.text,
        (qs.statement_start_offset / 2) + 1,
        CASE
            WHEN qs.statement_end_offset = -1
                THEN (DATALENGTH(st.text) - qs.statement_start_offset) / 2 + 1
            ELSE (qs.statement_end_offset - qs.statement_start_offset) / 2 + 1
        END
    ) AS QueryText
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
OUTER APPLY sys.dm_exec_plan_attributes(qs.plan_handle) AS pa
WHERE pa.attribute = 'dbid'
ORDER BY qs.total_worker_time DESC;
