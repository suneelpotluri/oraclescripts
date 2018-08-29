SPO coe_siebel_profile.log;
SET DEF ON TERM OFF ECHO ON;
CL TIMI;
REM
REM $Header: coe_siebel_profile.sql 11.2 2010/11/19 csierra $
REM
REM Copyright (c) 1990-2010, Oracle. All rights reserved.
REM
REM The Programs (which include both the software and documentation) contain
REM proprietary information; they are provided under a license agreement containing
REM restrictions on use and disclosure and are also protected by copyright, patent,
REM and other intellectual and industrial property laws. Reverse engineering,
REM disassembly, or decompilation of the Programs, except to the extent required to
REM obtain interoperability with other independently created software or as specified
REM by law, is prohibited.
REM
REM Oracle, JD Edwards, PeopleSoft, and Siebel are registered trademarks of
REM Oracle Corporation and/or its affiliates. Other names may be trademarks
REM of their respective owners.
REM
REM If you have received this software in error, please notify Oracle Corporation
REM immediately at 1.800.ORACLE1.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   coe_siebel_profile.sql
REM
REM DESCRIPTION
REM   Collects schema object details for Siebel on 10g, 11g and 12C.
REM
REM PARAMETERS
REM   1. Proces Type: (N)ormal or (E)xpert. Default N.
REM   2. Schema Owner: Default SIEBEL.
REM   3. Repository Name: Default Siebel Repository.
REM
REM EXECUTION
REM   1. Connect into SQL*Plus as SYSDBA.
REM   2. Execute this script with or without inline parameters.
REM
REM EXAMPLE
REM   # sqlplus / as sysdba
REM   SQL> START coe_siebel_profile.sql N SIEBEL Siebel_Repository
REM   or
REM   SQL> START coe_siebel_profile.sql
REM
REM NOTES
REM   1. Expert process type should only by used by Expert Services.
REM   2. Please notice that when passing parameters inline
REM      spaces must be converted to underscore, for example
REM      "Siebel Repository" is passed as "Siebel_Repository".
REM
-- default parameters
DEF default_schema_owner = 'SIEBEL';
DEF default_repository = 'Siebel Repository';
-- default threshold for top x columns in need of an index
DEF default_col_count = '25';
-- default project name for system tables
DEF default_project_name = 'Table ServerApps';
-- default status code
DEF default_stat_cd = 'Active';

-- must connect as SYS or user with DBA grant
SELECT USER FROM DUAL;

SET TERM ON ECHO OFF;
PRO
PRO Parameter 1:
PRO Proces Type: (N)ormal or (E)xpert. Default "N".
PRO
DEF process_type = '&1';
PRO
PRO Parameter 2:
PRO Schema Owner: Default "SIEBEL".
PRO
DEF schema_owner = '&2';
PRO

SET TERM OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- prepares parameters
VAR process_type CHAR(1);
VAR schema_owner VARCHAR2(30);
VAR col_count NUMBER;
EXEC :process_type := NVL(UPPER(SUBSTR(TRIM(' ' FROM '&&process_type.'), 1, 1)), 'N');
EXEC :schema_owner := UPPER(NVL(TRIM(' ' FROM '&&schema_owner.'), '&&default_schema_owner.'));
EXEC :col_count := TO_NUMBER('&&default_col_count.');
PRINT process_type;
PRINT schema_owner;
PRINT col_count;
COL schema_owner NEW_V schema_owner;
COL current_time NEW_V current_time;
COL process_type NEW_V process_type;
SELECT :schema_owner schema_owner, :process_type process_type, TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') current_time FROM DUAL;

-- validates process type
BEGIN
  IF :process_type NOT IN ('N', 'E') THEN
    RAISE_APPLICATION_ERROR(-20400, 'Invalid process type: '||:process_type);
  END IF;
END;
/

-- validates schema owner
DECLARE
  cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO cnt FROM sys.dba_users WHERE username = :schema_owner;
  IF cnt != 1 THEN
    RAISE_APPLICATION_ERROR(-20300, 'Invalid schame owner: '||:schema_owner);
  END IF;
END;
/

SET TERM ON VER OFF;
SELECT name repository_name FROM &&schema_owner..s_repository;
PRO Parameter 3:
PRO Repository Name: Default "Siebel Repository".
PRO
DEF repository_name = '&3';
PRO
PRO wait...
SET TERM OFF VER ON;

-- prepares parameters
VAR repository_name VARCHAR2(75);
VAR repository_id VARCHAR2(15);
EXEC :repository_name := REPLACE(UPPER(NVL(TRIM(' ' FROM '&&repository_name.'), '&&default_repository.')), '_', ' ');
PRINT repository_name;

-- validates repository name
BEGIN
  SELECT row_id INTO :repository_id FROM &&schema_owner..s_repository WHERE REPLACE(UPPER(name), '_', ' ') = :repository_name;
END;
/
PRINT repository_id;
COL repository_id NEW_V repository_id;
SELECT :repository_id repository_id FROM DUAL;

-- validates this is 10g or 11g
VAR rdbms_version VARCHAR2(17);
VAR rdbms_release NUMBER;
DECLARE
  dot1 NUMBER;
  dot2 NUMBER;
BEGIN
  EXECUTE IMMEDIATE 'SELECT version FROM v$instance' INTO :rdbms_version;
  dot1 := INSTR(:rdbms_version, '.');
  dot2 := INSTR(:rdbms_version, '.', dot1 + 1);
  :rdbms_release :=
  TO_NUMBER(SUBSTR(:rdbms_version, 1, dot1 - 1)) +
  (TO_NUMBER(SUBSTR(:rdbms_version, dot1 + 1, dot2 - dot1 - 1)) / POWER(10, (dot2 - dot1 - 1)));
  IF :rdbms_release < 10 THEN
    RAISE_APPLICATION_ERROR(-20200, 'Use on 10g or higher, not in '||:rdbms_release);
  END IF;
END;
/
PRINT rdbms_release;
PRINT rdbms_version;

WHENEVER SQLERROR CONTINUE;
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";

/********************************* create temp tables *********************************/

DROP TABLE &&schema_owner..siebel_tables;
CREATE TABLE &&schema_owner..siebel_tables AS
SELECT t.table_name, t.num_rows, t.blocks, t.last_analyzed, t.sample_size, t.avg_row_len,
       t.degree, t.partitioned, t.temporary, t.global_stats,
       DECODE(s.stattype_locked, NULL, 'NO', s.stattype_locked) stattype_locked,
       DECODE(s.stale_stats, NULL, 'UNKOWN', s.stale_stats) stale_stats,
       m.inserts, m.updates, m.deletes, m.timestamp, st.row_id tbl_id
  FROM sys.dba_tables t,
       sys.dba_tab_statistics s,
       sys.dba_tab_modifications m,
       &&schema_owner..s_table st,
       &&schema_owner..s_project sp
 WHERE t.owner = '&&schema_owner.'
   AND (t.table_name LIKE 'S^_%' ESCAPE '^' OR  t.table_name LIKE 'CX^_%' ESCAPE '^')
   AND t.table_name NOT LIKE 'S^_ETL%' ESCAPE '^'
   AND t.table_name NOT LIKE 'BIN$%' -- recycle bin
   AND (t.iot_type IS NULL OR t.iot_type <> 'IOT_OVERFLOW')
   AND t.owner = s.owner
   AND t.table_name = s.table_name
   AND s.object_type = 'TABLE'
   AND t.owner = m.table_owner(+)
   AND t.table_name = m.table_name(+)
   AND m.partition_name(+) IS NULL
   AND m.subpartition_name(+) IS NULL
   AND t.table_name = st.name
   AND st.repository_id = '&&repository_id.'
   AND st.stat_cd = '&&default_stat_cd.'
   AND st.project_id = sp.row_id
   AND sp.name != '&&default_project_name.';

DROP TABLE &&schema_owner..siebel_tab_cols;
CREATE TABLE &&schema_owner..siebel_tab_cols AS
SELECT c.table_name, c.column_id, c.column_name, c.last_analyzed, c.sample_size,
       c.num_nulls, c.num_distinct, c.num_buckets, c.density, c.histogram, c.avg_col_len,
       c.global_stats, c.hidden_column, st.tbl_id, sc.row_id col_id
  FROM sys.dba_tab_cols c,
       &&schema_owner..siebel_tables st,
       &&schema_owner..s_column sc
 WHERE c.owner = '&&schema_owner.'
   AND c.table_name = st.table_name
   AND st.tbl_id = sc.tbl_id
   AND c.column_name = sc.name
   AND sc.repository_id = '&&repository_id.'
   AND sc.stat_cd = '&&default_stat_cd.';

DROP TABLE &&schema_owner..siebel_indexes;
CREATE TABLE &&schema_owner..siebel_indexes AS
SELECT i.owner, i.index_name, i.index_type, i.table_name, i.uniqueness, i.blevel,
       i.num_rows, i.leaf_blocks, i.last_analyzed, i.sample_size, i.distinct_keys,
       i.avg_leaf_blocks_per_key, i.avg_data_blocks_per_key, i.clustering_factor,
       i.degree, i.partitioned, i.temporary, i.global_stats, st.tbl_id,
       si.row_id index_id
  FROM sys.dba_indexes i,
       &&schema_owner..siebel_tables st,
       &&schema_owner..s_index si
 WHERE i.table_owner = '&&schema_owner.'
   AND i.index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
   AND i.table_name = st.table_name
   AND st.tbl_id = si.tbl_id
   AND i.index_name = si.name
   AND si.repository_id = '&&repository_id.'
   AND si.stat_cd = '&&default_stat_cd.';

DROP TABLE &&schema_owner..siebel_ind_columns;
CREATE TABLE &&schema_owner..siebel_ind_columns AS
SELECT ic.index_name, ic.table_name, SUBSTR(ic.column_name, 1, 30) column_name,
       ic.column_position, ic.descend, st.tbl_id, si.index_id, stc.col_id,
       sic.row_id idx_col_id
  FROM sys.dba_ind_columns ic,
       &&schema_owner..siebel_indexes si,
       &&schema_owner..siebel_tables st,
       &&schema_owner..siebel_tab_cols stc,
       &&schema_owner..s_index_column sic
 WHERE ic.table_owner = '&&schema_owner.'
   AND ic.index_name = si.index_name
   AND ic.table_name = st.table_name
   AND ic.table_name = stc.table_name
   AND ic.column_name = stc.column_name
   AND si.index_id = sic.index_id
   AND stc.col_id = sic.col_id
   AND sic.repository_id = '&&repository_id.'
   AND sic.stat_cd = '&&default_stat_cd.';

DROP TABLE &&schema_owner..siebel_col_usage;
CREATE TABLE &&schema_owner..siebel_col_usage AS
SELECT u.name owner,
       o.name table_name,
       c.name column_name,
       (g.equality_preds + g.equijoin_preds + g.nonequijoin_preds + g.range_preds + g.like_preds + g.null_preds)
       predicates,
       g.equality_preds,
       g.equijoin_preds,
       g.nonequijoin_preds,
       g.range_preds,
       g.like_preds,
       g.null_preds,
       g.timestamp
  FROM sys.col_usage$ g,
       sys.col$ c,
       sys.obj$ o,
       sys.user$ u
 WHERE g.obj# = c.obj#
   AND g.intcol# = c.intcol#
   AND c.obj# = o.obj#
   AND o.owner# = u.user#
   AND u.name = '&&schema_owner.';

/********************************* create temp views *********************************/

CREATE OR REPLACE VIEW &&schema_owner..siebel_tables_v AS
SELECT DECODE(t.last_analyzed, NULL, 'NO', 'YES') table_stats,
       ROUND(SYSDATE - t.last_analyzed) stats_age_days,
       CASE
       WHEN t.num_rows < 16 THEN '<16'
       WHEN t.num_rows BETWEEN 16 AND 1e2 THEN '16-100'
       WHEN t.num_rows BETWEEN 1e2 AND 1e3 THEN '100-1000'
       WHEN t.num_rows BETWEEN 1e3 AND 1e4 THEN '1K-10K'
       WHEN t.num_rows BETWEEN 1e4 AND 1e5 THEN '10K-100K'
       WHEN t.num_rows BETWEEN 1e5 AND 1e6 THEN '100K-1M'
       WHEN t.num_rows BETWEEN 1e6 AND 1e7 THEN '1M-10M'
       WHEN t.num_rows BETWEEN 1e7 AND 1e8 THEN '10M-100M'
       WHEN t.num_rows BETWEEN 1e8 AND 1e9 THEN '100M-1B'
       WHEN t.num_rows > 1e9 THEN '>1B'
       ELSE 'UNKNOWN' END table_size,
       DECODE(NVL(i.indexes_count, 0), 0, 'NO', 'YES') indexed,
       i.indexes_count,
       t.*
  FROM &&schema_owner..siebel_tables t,
       (SELECT table_name, COUNT(*) indexes_count
          FROM &&schema_owner..siebel_indexes
         GROUP BY
               table_name) i
 WHERE t.table_name = i.table_name(+);

CREATE OR REPLACE VIEW &&schema_owner..siebel_indexes_v AS
SELECT t.table_stats,
       t.table_size,
       DECODE(i.last_analyzed, NULL, 'NO', 'YES') index_stats,
       ROUND(SYSDATE - i.last_analyzed) stats_age_days,
       i.*,
       ic.columns,
       ic1.column_name column1,
       ic2.column_name column2,
       ic3.column_name column3,
       ic4.column_name column4,
       ic5.column_name column5,
       ic6.column_name column6
  FROM &&schema_owner..siebel_indexes i,
       &&schema_owner..siebel_tables_v t,
       (SELECT index_name, COUNT(*) columns
          FROM &&schema_owner..siebel_ind_columns
         GROUP BY index_name ) ic,
       (SELECT index_name, SUBSTR(column_name||DECODE(descend, 'DESC', '(DESC)'), 1, 40) column_name
          FROM &&schema_owner..siebel_ind_columns
         WHERE column_position = 1 ) ic1,
       (SELECT index_name, SUBSTR(column_name||DECODE(descend, 'DESC', '(DESC)'), 1, 40) column_name
          FROM &&schema_owner..siebel_ind_columns
         WHERE column_position = 2 ) ic2,
       (SELECT index_name, SUBSTR(column_name||DECODE(descend, 'DESC', '(DESC)'), 1, 40) column_name
          FROM &&schema_owner..siebel_ind_columns
         WHERE column_position = 3 ) ic3,
       (SELECT index_name, SUBSTR(column_name||DECODE(descend, 'DESC', '(DESC)'), 1, 40) column_name
          FROM &&schema_owner..siebel_ind_columns
         WHERE column_position = 4 ) ic4,
       (SELECT index_name, SUBSTR(column_name||DECODE(descend, 'DESC', '(DESC)'), 1, 40) column_name
          FROM &&schema_owner..siebel_ind_columns
         WHERE column_position = 5 ) ic5,
       (SELECT index_name, SUBSTR(column_name||DECODE(descend, 'DESC', '(DESC)'), 1, 40) column_name
          FROM &&schema_owner..siebel_ind_columns
         WHERE column_position = 6 ) ic6
 WHERE i.table_name = t.table_name
   AND i.index_name = ic.index_name
   AND i.index_name = ic1.index_name
   AND i.index_name = ic2.index_name(+)
   AND i.index_name = ic3.index_name(+)
   AND i.index_name = ic4.index_name(+)
   AND i.index_name = ic5.index_name(+)
   AND i.index_name = ic6.index_name(+);

CREATE OR REPLACE VIEW &&schema_owner..siebel_tab_cols_v AS
SELECT t.table_stats,
       t.table_size,
       DECODE(NVL(cu.predicates, 0), 0, 'NO', 'YES') col_in_predicates,
       DECODE(NVL(ic.indexes, 0), 0, 'NO', 'YES') col_in_indexes,
       DECODE(tc.last_analyzed, NULL, 'NO', 'YES') col_stats,
       DECODE(NVL(tc.histogram, 'NONE'), 'NONE', 'NO', 'YES') col_histogram,
       ROUND(SYSDATE - tc.last_analyzed) stats_age_days,
       tc.*,
       t.num_rows table_num_rows,
       ic.indexes,
       cu.predicates,
       cu.equality_preds,
       cu.equijoin_preds,
       cu.nonequijoin_preds,
       cu.range_preds,
       cu.like_preds,
       cu.null_preds,
       cu.timestamp
  FROM &&schema_owner..siebel_tab_cols tc,
       &&schema_owner..siebel_tables_v t,
       &&schema_owner..siebel_col_usage cu,
       (SELECT table_name, column_name, COUNT(*) indexes
          FROM &&schema_owner..siebel_ind_columns
         GROUP BY
               table_name, column_name) ic
 WHERE tc.table_name = t.table_name
   AND tc.table_name = cu.table_name(+)
   AND tc.column_name = cu.column_name(+)
   AND '&&schema_owner.' = cu.owner(+)
   AND tc.table_name = ic.table_name(+)
   AND tc.column_name = ic.column_name(+);

CREATE OR REPLACE VIEW &&schema_owner..siebel_ind_cols_v AS
SELECT ic.*,
       tc.col_in_predicates,
       tc.col_stats,
       tc.col_histogram,
       tc.stats_age_days,
       tc.last_analyzed,
       tc.sample_size,
       tc.num_nulls,
       tc.num_distinct,
       tc.num_buckets,
       tc.density,
       tc.histogram,
       tc.avg_col_len,
       tc.global_stats,
       tc.hidden_column,
       tc.table_size,
       tc.table_num_rows,
       tc.indexes,
       tc.predicates,
       tc.equality_preds,
       tc.equijoin_preds,
       tc.nonequijoin_preds,
       tc.range_preds,
       tc.like_preds,
       tc.null_preds,
       tc.timestamp
  FROM &&schema_owner..siebel_ind_columns ic,
       &&schema_owner..siebel_tab_cols_v tc
 WHERE ic.table_name = tc.table_name
   AND ic.column_name = tc.column_name;

/********************************* counts *********************************/

SET ECHO OFF VER OFF FEED OFF PAGES 50000 LIN 2000 TRIMS ON;

SPO &&schema_owner._&&current_time._S_profile_cols_with_no_index.txt;

PRO Columns with no index
PRO ~~~~~~~~~~~~~~~~~~~~~
PRO Complete list of non-indexed columns referenced by at least one SQL predicate.

SELECT predicates, table_name, column_name
  FROM &&schema_owner..siebel_tab_cols_v
 WHERE col_in_predicates = 'YES'
   AND col_in_indexes = 'NO'
 ORDER BY
       predicates DESC,
       table_name,
       column_name ;

SPO OFF;

SPO &&schema_owner._&&current_time._S_profile_summary.txt;

PRO Top &&default_col_count. columns in need of an index
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO Partial list of non-indexed columns referenced by at least one SQL predicate.

SELECT * FROM (
SELECT predicates, table_name, column_name
  FROM &&schema_owner..siebel_tab_cols_v
 WHERE col_in_predicates = 'YES'
   AND col_in_indexes = 'NO'
 ORDER BY
       predicates DESC,
       table_name,
       column_name )
 WHERE ROWNUM <= &&default_col_count.;

COL tables FOR 99999;
COL table_stats FOR A11;
COL stats_locked FOR A12;
COL stale_stats FOR A11;

PRO
PRO Tables
PRO ~~~~~~
PRO Count and rollup of tables grouped by the following 3 attributes:
PRO 1. Table has CBO statistics. 2. Statistics are locked. 3. Statistics are stale.

SELECT COUNT(*) tables,
       table_stats, stattype_locked stats_locked, stale_stats
  FROM &&schema_owner..siebel_tables_v
 GROUP BY
       ROLLUP(table_stats, stattype_locked, stale_stats);

COL tables FOR 99999;
COL table_size FOR A10;
COL indexed FOR A7;

PRO
PRO Count and rollup of tables grouped by the following 2 attributes:
PRO 1. Table size according to number of rows. 2. Table has at least an index.

SELECT COUNT(*) tables,
       table_size, indexed
  FROM &&schema_owner..siebel_tables_v
 GROUP BY
       ROLLUP(table_size, indexed)
 ORDER BY
       DECODE(table_size,
       'UNKNOWN', 0,
       '<16', 1,
       '16-100', 2,
       '100-1000', 3,
       '1K-10K', 4,
       '10K-100K', 5,
       '100K-1M', 6,
       '1M-10M', 7,
       '10M-100M', 8,
       '100M-1B', 9,
       '>1B', 10) NULLS LAST,
       indexed DESC NULLS LAST;

COL tables FOR 99999;
COL stats_age_days FOR 99999999999999;
COL table_size FOR A10;

PRO
PRO Count and rollup of tables grouped by the following 2 attributes:
PRO 1. Table size according to number of rows. 2. Age of table CBO statistics in days.

SELECT COUNT(*) tables,
       table_size,
       stats_age_days
  FROM &&schema_owner..siebel_tables_v
 WHERE table_stats = 'YES'
 GROUP BY
       ROLLUP(table_size, stats_age_days)
 ORDER BY
       DECODE(table_size,
       'UNKNOWN', 0,
       '<16', 1,
       '16-100', 2,
       '100-1000', 3,
       '1K-10K', 4,
       '10K-100K', 5,
       '100K-1M', 6,
       '1M-10M', 7,
       '10M-100M', 8,
       '100M-1B', 9,
       '>1B', 10) NULLS LAST,
       stats_age_days NULLS LAST;

COL indexes FOR 9999999;
COL table_size FOR A10;
COL index_stats FOR A11;

PRO
PRO Indexes
PRO ~~~~~~~
PRO Count and rollup of indexes grouped by the following 2 attributes:
PRO 1. Corresponding table size according to number of rows. 2. Index has CBO statistics.

SELECT COUNT(*) indexes,
       table_size,
       index_stats
  FROM &&schema_owner..siebel_indexes_v
 GROUP BY
       ROLLUP(table_size, index_stats)
 ORDER BY
       DECODE(table_size,
       'UNKNOWN', 0,
       '<16', 1,
       '16-100', 2,
       '100-1000', 3,
       '1K-10K', 4,
       '10K-100K', 5,
       '100K-1M', 6,
       '1M-10M', 7,
       '10M-100M', 8,
       '100M-1B', 9,
       '>1B', 10) NULLS LAST,
       index_stats NULLS LAST;

COL indexes FOR 9999999;
COL table_size FOR A10;
COL stats_age_days FOR 99999999999999;

PRO
PRO Count and rollup of indexes grouped by the following 2 attributes:
PRO 1. Corresponding table size according to number of rows. 2. Age of index CBO statistics in days.

SELECT COUNT(*) indexes,
       table_size,
       stats_age_days
  FROM &&schema_owner..siebel_indexes_v
 WHERE index_stats = 'YES'
 GROUP BY
       ROLLUP(table_size, stats_age_days)
 ORDER BY
       DECODE(table_size,
       'UNKNOWN', 0,
       '<16', 1,
       '16-100', 2,
       '100-1000', 3,
       '1K-10K', 4,
       '10K-100K', 5,
       '100K-1M', 6,
       '1M-10M', 7,
       '10M-100M', 8,
       '100M-1B', 9,
       '>1B', 10) NULLS LAST,
       stats_age_days NULLS LAST;

COL table_stats FOR A11;
COL col_in_predicates FOR A17;
COL col_in_indexes FOR A14;
COL col_stats FOR A9;
COL col_histogram FOR A13;
COL columns FOR 9999999;

PRO
PRO Columns
PRO ~~~~~~~
PRO Count and rollup of columns grouped by the following 5 attributes:
PRO 1. Corresponding table has CBO statistics. 2. Column is referenced by at least one SQL predicate.
PRO 3. Column exists in at least an index. 4. Column has CBO statistics. 5. Column has a histogram.

SELECT COUNT(*) columns,
       table_stats, col_in_predicates, col_in_indexes, col_stats, col_histogram
  FROM &&schema_owner..siebel_tab_cols_v
 GROUP BY
       ROLLUP(table_stats, col_in_predicates, col_in_indexes, col_stats, col_histogram)
 ORDER BY
       table_stats DESC NULLS LAST,
       col_in_predicates DESC NULLS LAST,
       col_in_indexes DESC NULLS LAST,
       col_stats DESC NULLS LAST,
       col_histogram DESC NULLS LAST;

COL columns FOR 9999999;
COL stats_age_days FOR 99999999999999;
COL table_size FOR A10;

PRO
PRO Count and rollup of columns grouped by the following 2 attributes:
PRO 1. Corresponding table size according to number of rows. 2. Age of column CBO statistics in days.

SELECT COUNT(*) columns,
       table_size,
       stats_age_days
  FROM &&schema_owner..siebel_tab_cols_v
 WHERE col_stats = 'YES'
 GROUP BY
       ROLLUP(table_size, stats_age_days)
 ORDER BY
       DECODE(table_size,
       'UNKNOWN', 0,
       '<16', 1,
       '16-100', 2,
       '100-1000', 3,
       '1K-10K', 4,
       '10K-100K', 5,
       '100K-1M', 6,
       '1M-10M', 7,
       '10M-100M', 8,
       '100M-1B', 9,
       '>1B', 10) NULLS LAST,
       stats_age_days NULLS LAST;

SPO OFF;

/********************************* details *********************************/

SET COLSEP ',';

COL table_size FOR A10;
COL table_stats FOR A11;
COL partitioned FOR A11;
COL temporary FOR A9;
COL global_stats FOR A12;
COL stattype_locked FOR A15;
COL stale_stats FOR A11;

SPO &&schema_owner._&&current_time._&&process_type._profile_tables.csv;

SELECT table_name,
       table_size,
       num_rows,
       blocks,
       table_stats,
       stats_age_days,
       TO_CHAR(last_analyzed, 'YYYY/MM/DD HH24:MI:SS') last_analyzed,
       sample_size,
       avg_row_len,
       indexes_count,
       degree,
       partitioned,
       temporary,
       global_stats,
       stattype_locked,
       stale_stats,
       inserts,
       updates,
       deletes,
       TO_CHAR(timestamp, 'YYYY/MM/DD HH24:MI:SS') timestamp
  FROM &&schema_owner..siebel_tables_v
 WHERE :process_type = 'E'
 ORDER BY
       table_name;

SPO OFF;

COL index_type FOR A10;
COL table_size FOR A10;
COL index_stats FOR A11;
COL uniqueness FOR A10;
COL partitioned FOR A11;
COL temporary FOR A9;
COL global_stats FOR A12;

SPO &&schema_owner._&&current_time._&&process_type._profile_indexes.csv;

SELECT owner,
       index_name,
       index_type,
       table_name,
       table_size,
       uniqueness,
       blevel,
       num_rows,
       leaf_blocks,
       index_stats,
       stats_age_days,
       TO_CHAR(last_analyzed, 'YYYY/MM/DD HH24:MI:SS') last_analyzed,
       sample_size,
       distinct_keys,
       avg_leaf_blocks_per_key,
       avg_data_blocks_per_key,
       clustering_factor,
       degree,
       partitioned,
       temporary,
       global_stats,
       columns,
       column1,
       column2,
       column3,
       column4,
       column5,
       column6
  FROM &&schema_owner..siebel_indexes_v
 WHERE :process_type = 'E'
 ORDER BY
       owner,
       index_name;

SPO OFF;

COL table_size FOR A10;
COL col_stats FOR A9;
COL col_histogram FOR A13;
COL hidden_column FOR A13;
COL global_stats FOR A12;
COL col_in_predicates FOR A17;
COL col_in_indexes FOR A14;

SPO &&schema_owner._&&current_time._&&process_type._profile_tab_cols.csv;

SELECT table_name,
       table_size,
       column_id,
       column_name,
       col_stats,
       stats_age_days,
       TO_CHAR(last_analyzed, 'YYYY/MM/DD HH24:MI:SS') last_analyzed,
       sample_size,
       num_nulls,
       num_distinct,
       num_buckets,
       density,
       col_histogram,
       histogram,
       avg_col_len,
       global_stats,
       hidden_column,
       col_in_predicates,
       col_in_indexes,
       table_num_rows,
       indexes,
       predicates,
       equality_preds,
       equijoin_preds,
       nonequijoin_preds,
       range_preds,
       like_preds,
       null_preds,
       TO_CHAR(timestamp, 'YYYY/MM/DD HH24:MI:SS') timestamp
  FROM &&schema_owner..siebel_tab_cols_v
 WHERE :process_type = 'E'
 ORDER BY
       table_name,
       column_id NULLS LAST,
       column_name;

SPO OFF;

COL descend FOR A7;
COL table_size FOR A10;
COL col_stats FOR A9;
COL col_histogram FOR A13;
COL hidden_column FOR A13;
COL global_stats FOR A12;
COL col_in_predicates FOR A17;
COL col_in_indexes FOR A14;

SPO &&schema_owner._&&current_time._&&process_type._profile_ind_cols.csv;

SELECT table_name,
       index_name,
       column_position,
       column_name,
       descend,
       col_in_predicates,
       col_stats,
       col_histogram,
       stats_age_days,
       TO_CHAR(last_analyzed, 'YYYY/MM/DD HH24:MI:SS') last_analyzed,
       sample_size,
       num_nulls,
       num_distinct,
       num_buckets,
       density,
       histogram,
       avg_col_len,
       global_stats,
       hidden_column,
       table_size,
       table_num_rows,
       indexes,
       predicates,
       equality_preds,
       equijoin_preds,
       nonequijoin_preds,
       range_preds,
       like_preds,
       null_preds,
       TO_CHAR(timestamp, 'YYYY/MM/DD HH24:MI:SS') timestamp
  FROM &&schema_owner..siebel_ind_cols_v
 WHERE :process_type = 'E'
 ORDER BY
       table_name,
       index_name,
       column_position;

SPO OFF;

/********************************* zip *********************************/

HOS zip -m &&schema_owner._&&current_time._profile coe_siebel_profile.log &&schema_owner._&&current_time.*
HOS zip -d &&schema_owner._&&current_time._profile &&schema_owner._&&current_time._N*

/********************************* drop temp objects *********************************/

DROP VIEW &&schema_owner..siebel_ind_cols_v;
DROP VIEW &&schema_owner..siebel_tab_cols_v;
DROP VIEW &&schema_owner..siebel_indexes_v;
DROP VIEW &&schema_owner..siebel_tables_v;
DROP TABLE &&schema_owner..siebel_col_usage;
DROP TABLE &&schema_owner..siebel_ind_columns;
DROP TABLE &&schema_owner..siebel_indexes;
DROP TABLE &&schema_owner..siebel_tab_cols;
DROP TABLE &&schema_owner..siebel_tables;

/********************************* end *********************************/

SET TERM ON ECHO ON VER ON FEED ON PAGES 14 LIN 80 TRIMS OFF COLSEP ' ';
HOS unzip -l &&schema_owner._&&current_time._profile
PRO completed...
