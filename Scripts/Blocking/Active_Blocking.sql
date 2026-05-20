/*
    RoMetis SQL Server Performance Toolkit Lite
    Script: Active_Blocking.sql
    Purpose: Show active blocking sessions and waiting requests.
    Safety: Read-only
    Requirements: VIEW SERVER STATE
    Notes:
      - Shows current blocking only.
      - For historical blocking/deadlocks, use Extended Events in a Pro/advanced setup.
*/

SET NOCOUNT ON;

SELECT
    r.blocking_session_id AS BlockingSessionId,
    r.session_id AS BlockedSessionId,
    DB_NAME(r.database_id) AS DatabaseName,

    r.status AS RequestStatus,
    r.command AS Command,
    r.wait_type AS WaitType,
    r.wait_time AS WaitTime_ms,
    r.wait_resource AS WaitResource,

    r.cpu_time AS CpuTime_ms,
    r.total_elapsed_time AS TotalElapsedTime_ms,
    r.reads AS Reads,
    r.writes AS Writes,
    r.logical_reads AS LogicalReads,

    blocked_s.login_name AS BlockedLoginName,
    blocked_s.host_name AS BlockedHostName,
    blocked_s.program_name AS BlockedProgramName,

    blocker_s.login_name AS BlockingLoginName,
    blocker_s.host_name AS BlockingHostName,
    blocker_s.program_name AS BlockingProgramName,

    SUBSTRING(
        blocked_txt.text,
        (r.statement_start_offset / 2) + 1,
        CASE
            WHEN r.statement_end_offset = -1
                THEN (DATALENGTH(blocked_txt.text) - r.statement_start_offset) / 2 + 1
            ELSE (r.statement_end_offset - r.statement_start_offset) / 2 + 1
        END
    ) AS BlockedQueryText,

    blocker_txt.text AS BlockingSessionLastBatchText
FROM sys.dm_exec_requests AS r
INNER JOIN sys.dm_exec_sessions AS blocked_s
    ON r.session_id = blocked_s.session_id
LEFT JOIN sys.dm_exec_sessions AS blocker_s
    ON r.blocking_session_id = blocker_s.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS blocked_txt
OUTER APPLY (
    SELECT c.most_recent_sql_handle
    FROM sys.dm_exec_connections AS c
    WHERE c.session_id = r.blocking_session_id
) AS blocker_conn
OUTER APPLY sys.dm_exec_sql_text(blocker_conn.most_recent_sql_handle) AS blocker_txt
WHERE r.blocking_session_id <> 0
ORDER BY r.wait_time DESC;
