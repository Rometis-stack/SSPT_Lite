# RoMetis SQL Server Performance Toolkit Lite

A free, read-only SQL Server diagnostic toolkit for quick performance and health checks.

## Included scripts

- `Scripts/CPU/Top_CPU_Queries.sql`
- `Scripts/CPU/Expensive_Queries.sql`
- `Scripts/Indexes/Missing_Indexes.sql`
- `Scripts/Blocking/Active_Blocking.sql`
- `Scripts/Storage/DatabaseGrowth.sql`
- `Scripts/Reports/HealthSummary.sql`

## Requirements

- SQL Server 2016+
- Permissions to read Dynamic Management Views:
  - `VIEW SERVER STATE`
  - `VIEW DATABASE STATE` where applicable

## Notes

All scripts are read-only and do not change database schema, data, indexes, jobs or configuration.

Results from plan-cache based scripts depend on the current SQL Server plan cache.
