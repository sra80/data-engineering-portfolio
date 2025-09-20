# Streamlined Portfolio

Curated examples that demonstrate how I design and deliver production-ready data solutions across Azure, Microsoft Fabric, and SQL Server estates. Each case study links to executable assets within this repository.

---

## 1. Real-Time Alerting Platform (Azure Logic Apps + SQL)
**Business context.** Business stakeholders needed proactive notifications when critical events surfaced in the operational data warehouse.

**Solution.** I built an Azure Logic App (Consumption) that orchestrates stored procedures in an Azure SQL Database, fans out email and Microsoft Teams alerts, and captures a full audit trail. The workflow runs on a timed trigger and scales without code changes thanks to parameterized connectors and managed identities.

**What to notice.**
- End-to-end automation: SQL stored procedures `db_sys.sp_email_notifications_schedule*` drive alert selection, while the Logic App handles delivery and Teams posting.
- Operational guardrails: error handling tables, SharePoint spillover for oversized payloads, and audit hooks (`db_sys.sp_auditLog_*`) keep operators informed.
- Deployment friendly: parameterised ARM templates standardise provisioning without manual configuration drift.

**Artifacts.**
- Logic App definition: `azure/logic-apps/alerts-consumption/src/workflow.json`
- Infrastructure as code: `azure/logic-apps/alerts-consumption/deploy/main.json`
- Supporting SQL objects: `sql/nav/db_sys/StoredProcedures/sp_email_notifications_schedule.sql`, `sql/nav/db_sys/Views/vw_email_notifications.sql`

---

## 2. Sales Consolidation for Fabric Lakehouse (PySpark)
**Business context.** Consolidate historical and current sales orders from Dynamics NAV into a Lakehouse while preserving preferred records and regulatory partitions.

**Solution.** A PySpark notebook aligns current and archive tables, normalizes primary keys, applies business whitelists, and writes Delta outputs partitioned for incremental refresh. Safety helpers make the pipeline resilient when optional tables are missing.

**What to notice.**
- Robust ingestion: `_align_pair`, `safe_read_table`, and `normalize_id_str` ensure schema parity across CUR and ARCHIVE sources.
- Business logic baked in: preferred-record selection honours archive reasons, while whitelists keep curated columns ready for semantic modelling.
- Production-friendly writes: Delta `MERGE` with partition keys (`partition_by`) keeps ext tables synchronized without full reloads.

**Artifacts.**
- Fabric notebook: `python/fabric/sales_consolidation_cleaned.ipynb`
- Helper constants and functions: Cells 2–14 inside the notebook

---

## 3. Metadata-Driven Scheduling Framework (Logic Apps + Elastic Jobs)
**Business context.** Refreshing Azure Analysis Services/Power BI tabular models and their prerequisites required dependable orchestration that could be tuned without redeploying workflows.

**Solution.** I designed a metadata-first scheduling layer: Logic Apps read configuration from SQL tables to decide which models, partitions, and prerequisite procedures to run. For long-running SQL tasks, the workflow delegates execution to Azure Elastic Job Agent, which the Logic App then monitors until completion.

**What to notice.**
- Unified procedure cadence: a single stored procedure (`db_sys.sp_procedure_schedule`) covers both model-dependent (`@pre_model = 1`) and standalone (`@pre_model = 0`) runs.
- Model + partition governance: tables such as `db_sys.process_model`, `db_sys.process_model_partitions`, and their pairing tables express orchestration rules without code changes.
- Resilient execution: polling + status tables (`db_sys.procedure_schedule_queue`, `db_sys.pre_model_monitor_local`) provide retry hooks and operator visibility.
- Seamless hand-off: Elastic Jobs bypass Logic App’s 10-minute cap while retaining centralized auditing in SQL.

**Artifacts.**
- Scheduler procedure: `sql/db_sys/StoredProcedures/sp_procedure_schedule.sql`
- Metadata tables: `sql/db_sys/Tables/process_model.sql`, `sql/db_sys/Tables/process_model_partitions.sql`, `sql/db_sys/Tables/procedure_schedule.sql`
- Dependency mappings: `sql/db_sys/Tables/process_model_procedure_pairing.sql`, `sql/db_sys/Tables/process_model_partitions_procedure_pairing.sql`
- Companion infrastructure (Logic App + Elastic Job provisioning): `data-engineering-portfolio-full/azure/orchestration` (separate repository)

---

## 4. Operational SQL Platform Automation
**Business context.** The data platform hosts hundreds of NAV objects; keeping indexes healthy and alert pipelines synchronized requires automation.

**Solution.** I authored a suite of stored procedures in the `db_sys` schema to handle index maintenance, alert scheduling, audit logging, and Microsoft Teams integrations—all designed for safe, repeatable execution.

**What to notice.**
- Intelligent index care: `sp_index_optimization` rebuilds the most fragmented indexes while recording outcomes and exceptions for observability.
- Alert lifecycle: `sp_email_notifications_schedule` queues, executes, and tracks scheduled alerts, escalating errors after repeated failures.
- Integrated telemetry: audit helpers (`sp_auditLog_start`, `sp_auditLog_end`) create traceability that the Logic App and operators consume.

**Artifacts.**
- Index maintenance: `sql/nav/db_sys/StoredProcedures/sp_index_optimization.sql`
- Alert engine: `sql/nav/db_sys/StoredProcedures/sp_email_notifications_schedule.sql`
- Email/Teams view: `sql/nav/db_sys/Views/vw_email_notifications.sql`

---

## Additional Capabilities
- Broader SQL portfolio: `sql/nav` contains schemas, functions, and ETL logic spanning CDC, finance, forecasting, and marketing workloads.
- Automation toolbox: `tools/` includes deployment samples and scripts reusable across projects.
- Notebook experiments: `python/` hosts supporting utilities and prototypes that feed Power BI semantic models and Fabric pipelines.

Use this document as the entry point; drill into each artifact for implementation details, and reference the original README for a full directory map.
