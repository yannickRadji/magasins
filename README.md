# Executive summary

This project builds a small but production-style Snowflake data stack with:

Ingestion sources: DTL_EXO (schemas GI, TH) already provided.
Transformation & modeling: dbt 1.10 (staging → silver → gold), with tests, snapshot, freshness, policies attached by dbt, tags, and audit logging.
RLS/DDM: Row-level access by BRAND (AUCHAN, CARREFOUR, …); masking of NAME for non-entitled roles; CURRENT_ROLE() driven.
Governance: Database roles (DBR_READ/WRITE/ADMIN + brand roles), grants, and usage without ACCOUNTADMIN.
Migrations: Flyway OSS 11.14 (DDL only: schemas, roles/grants, policy objects). 
Matching logic (GI↔TH): Fuzzy match without cartesian blowups (blocking + scoring + QUALIFY).
Brand detection: No UDFs; dbt macro on normalized names, catching e.g. “auchan hypermarche …”.
KPIs: completeness/coherence surfaced for the Power BI report (provided).

# Goal
Consolidate two raw sources of stores (GI.MAGASINS, TH.MAGASINS) into a canonical view with de-duplicated stores, brand attribution, and secure consumption (internal analysts vs external shop/brand owners).

# How this met the exercices requirement
| Requirement (exercise)                                                         | Implementation                                                                                                                                                               |
| ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Gitflow variant without release branches; **semver**                           | Flyway files `V1.0.0__...`, `V1.1.0__...`, `V1.2.0__...`; project follows `develop/main` protected branches, each developer need to Pull request to modify those branch so to integrate new code.                                                                           |                                                                                                            |
| **Sources** with `{{ source() }}` and **freshness**                            | `models/sources.yml` (`warn_after: 1 day`) for `DTL_EXO.GI/TH.MAGASINS`.                                                                                                     |
| **Staging** normalization                                                      | `macros/clean_name.sql`; applied in `stg_gi_magasins.sql`, `stg_th_magasins.sql`.                                                                                            |
| **Fuzzy matching**                                                             | `SILVER.magasins_match.sql` uses locking (exact, geo grid, first-token)** → **scoring (EDITDISTANCE + HAVERSINE) → `QUALIFY rn_g=1 and rn_t=1`. Fast run less than 20sec because i avoid cartesian join. |
| **Canonical silver**                                                           | `SILVER.magasins_canonical.sql` consolidates matched + unmatched; derives `BRAND`.                                                                                           |
| **Brand detection** (covers “auchan …”)                                        | `macros/brand_from_clean_name.sql` (substring rules on normalized text).                                                                                                     |
| **RLS by BRAND**; **CURRENT_ROLE()**; internal analyst vs external shop owners | `GOLD.dim_magasins.sql` attaches `RLS_BY_BRAND` on `BRAND`. `AUDIT.BRAND_ACCESS` defines which roles can see which brand. `AUDIT.ADMIN_ACCESS` bypass for admin/DBR_ADMIN.   |
| **Masking**                                                                    | `MASK_NAME_BY_BRAND(NAME using BRAND)` attached by dbt on the gold view.                                                                                                     |
| **Secure view**                                                                | `GOLD.dim_magasins` uses `secure=true` in dbt config that prevent users from possibly expose data via workarounds.                                                                                                                        |
| **Managed access schemas**                                        | All schemas are created with MANAGED ACCESS to centralize privilege management.                                                                  |
| **Audit logging** pre/post                                                     | `macros/logging.sql` inserts into `AUDIT.LOGS` via `on-run-end`.                                                                                                             |
| **Tags**                                                                       | dbt sets `sensitivity` tag on `GOLD.dim_magasins`. Data senstivity can be internal, confidential... In real world we will based our masking policy based those levels via tags and masked confidential data like payments to our colleagues.                                                                                                    |
| **Tests**                                                                      | Not-null on IDs; freshness; data tests are defined in `/models`. In CICD as we use build -x we run then test each model along process with fail fast if any fail that prevent to runs all models when there is an error.                                                                             |
| **Snapshot**                                                                   | `snapshots/` includes `dim_magasins_snapshot` then used by gold view.                                                                                                        |
| **Roles model**                                                                | Database roles: `DBR_READ/WRITE/ADMIN` we assign with the principle of least priviledge on them; brand roles for external access; there are roles that can be assigned to users later by brand but there are also by Group that own several brands like AFM that manage Auchan & Leroymerlin.           |
| **DB per environment**                                                                    | DEV: `DWH_DEV_YANNICK`. PROD: `DWH_PROD_YANNICK` (same pattern).                                                                                                             |                                                                                                           |

# Enhancements

## CICD
This flyway CICD use clean to ensure that correct Snowflake objects are delivered at each run even if the previous has failed but in real world we should handle the case of failure with repair/undo and not use clean. flyway_schema_history should be set to be in the AUDIT schema.

We should be able to deploy application version based on git tag to more easily communicate which version is deployed or roll back.

## Data
The shops brands list is partial but still proove that the matching work. In real life we need to have full referential may be integrated to a Master Data Management. Many name are not correctly set so we need to communicate with the business and find sponsorhip to changes the practices, that people are aware that data quality is an important assets for the company.
We can enhance the name parsing by using an LLM parser with Snowflake Cortex (or another) that will be technically superior but this will not fully prevent the "garbage in; garbage out" effect that why we need to also enhance the data quality at its source.
We have data quality KPIs, visualizations could be embeeded in Snowflake with streamlit but because of time constraint i did it in powerBI.
NB: The access to the source has been revoked but onced set back the CICD should work

# Roadmap/Prioritizing under high business demand

Use a two-layer approach: (A) Intake & Triage for fast sorting, then (B) Scoring for objective ranking.

## Intake & Triage
- Standard intake form (problem statement, expected users, KPI/decision impacted, deadline, compliance sensitivity, rough data sources).
- Eligibility & readiness checks (Definition of Ready: sponsor identified, data owners reachable, minimal metadata known).
- Routing: classify as New Source, Enhancement/Maintenance, Tech Debt, or Regulatory.

## Priority
Adopt scaled Agile (WSJF)
WSJF=(Business Impact + Time Criticality + Risk Reduction)/Effort

Business Impact (1–5): revenue/risk/KPI sensitivity.
Criticality (0–5): legal deadlines, audit/sox, PII exposure.
Risk Reduction(o=or Enablement) (0–5): reduces incidents, unlocks downstream programs.
User Reach (0–5): population affected (brands, markets, analysts).
Effort (1–5): team-weeks; include data availability, complexity, dependencies.

## Balancing new sources, maintenance, tech debt, and regulatory items
Discuss with stakeholders what need to be onboard during the sprint planning based on priorities and keep some capacity bands to work on run and improvement/tech debt.
Even if the backlog is large we should not overcommit and take only what we can do during each sprint, finally have clear priorities to have clear focus (when every is high prio nothing has been prioritize). User stories/Road map item should prepared upfront with:
- Problem & objective: define few mesurable KPI, who benefits with a sponsor that validated its interest or owner.
- Expected value: quant/qual (revenue at risk, time saved, compliance avoided cost).
- Risk profile: data privacy, regulatory exposure, operational risk, SLO impact.
- Effort & dependencies: teams, systems, lead time.
- Data-quality SLOs: targeted completeness/freshness/coherence with owners.
- Go/No-Go gate: must meet Definition of Ready; commit only when risk × impact justifies effort.

## Operating model
- Data Steering Committee monthly: confirm weights, approve top items, track SLOs.
- Backlog hygiene weekly: re-score items, prune, confirm owners.
- Release discipline: Definition of Ready/Done, code reviews, dbt tests, CI gates, cost and quality dashboards.
- Bias controls: document assumptions; use historical incident data to avoid recency/availability bias; revisit weights quarterly.