USE SCHEMA GOLD;

CREATE OR REPLACE TAG sensitivity COMMENT='Sensitivity tag';

-- RLS by CURRENT_ROLE() and brand from name; ADMIN_ACCESS bypasses all
CREATE OR REPLACE ROW ACCESS POLICY RLS_BY_BRAND
AS (brand STRING) RETURNS BOOLEAN ->
(
  EXISTS (SELECT 1 FROM AUDIT.INTERNAL_ACCESS a WHERE a.role_name = CURRENT_ROLE())
  OR EXISTS (
    SELECT 1 FROM AUDIT.BRAND_ACCESS b
    WHERE b.role_name = CURRENT_ROLE()
      AND b.brand     = brand
  )
);

-- Masking policy aligned with same logic
CREATE OR REPLACE MASKING POLICY MASK_NAME_BY_BRAND
AS (name STRING, brand STRING) RETURNS STRING ->
  CASE
    WHEN EXISTS (SELECT 1 FROM AUDIT.ADMIN_ACCESS a WHERE a.role_name = CURRENT_ROLE()) THEN name
    WHEN EXISTS (
      SELECT 1 FROM AUDIT.BRAND_ACCESS b
      WHERE b.role_name = CURRENT_ROLE()
        AND b.brand     = brand
    ) THEN name
    ELSE '***'
  END;
