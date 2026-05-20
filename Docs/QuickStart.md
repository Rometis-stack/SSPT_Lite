# QuickStart

1. Open SQL Server Management Studio or Azure Data Studio.
2. Connect to your SQL Server instance.
3. Start with `Scripts/Reports/HealthSummary.sql`.
4. Use the detailed scripts to investigate specific findings:
   - CPU issues: `Top_CPU_Queries.sql`, `Expensive_Queries.sql`
   - Index opportunities: `Missing_Indexes.sql`
   - Blocking: `Active_Blocking.sql`
   - Storage: `DatabaseGrowth.sql`

Recommended first run order:

1. `HealthSummary.sql`
2. `Expensive_Queries.sql`
3. `Missing_Indexes.sql`
4. `Active_Blocking.sql`
5. `DatabaseGrowth.sql`
