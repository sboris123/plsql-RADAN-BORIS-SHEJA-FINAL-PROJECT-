--Step 1: Enable Archive Logging (CDB Level)
--Archive logging must be enabled on the CDB (it applies to all PDBs). This requires shutting down the CDB.
-- Shutdown the CDB
SHUTDOWN IMMEDIATE;

-- Startup in mount mode
STARTUP MOUNT;

-- Enable archive logging
ALTER DATABASE ARCHIVELOG;

-- Open the CDB
ALTER DATABASE OPEN;

-- Verify
SELECT log_mode FROM v$database;
-- Expected output: ARCHIVELOG

--Step 2: Create the Pluggable Database (PDB)

CREATE PLUGGABLE DATABASE tue_29096_boris_acovs_db
   ADMIN USER boris_admin IDENTIFIED BY admin
   FILE_NAME_CONVERT = (
      'C:\APP\ORADATA\XE\PDBSEED\', 
      'C:\APP\ORADATA\XE\tue_29096_boris_acovs_db\'
   );

-- Open the PDB
ALTER PLUGGABLE DATABASE tue_29096_boris_acovs_db OPEN;

--Step 3: Configure Tablespaces, Temporary Tablespace, and Autoextend
--Switch to the PDB and create the required tablespaces.

-- Switch to the PDB
ALTER SESSION SET CONTAINER = tue_29096_boris_acovs_db;

-- Create data tablespace with autoextend
CREATE TABLESPACE data_ts
  DATAFILE 'C:\APP\ORADATA\XE\tue_29096_boris_acovs_db\data_ts.dbf' SIZE 100M
  AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- Create index tablespace with autoextend
CREATE TABLESPACE index_ts
  DATAFILE 'C:\APP\ORADATA\XE\tue_29096_boris_acovs_db\index_ts.dbf' SIZE 50M
  AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- Create temporary tablespace with autoextend
CREATE TEMPORARY TABLESPACE temp_ts
  TEMPFILE 'C:\APP\ORADATA\XE\tue_29096_boris_acovs_db\temp_ts.dbf' SIZE 50M
  AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- Set as default temporary tablespace for the PDB
ALTER DATABASE DEFAULT TEMPORARY TABLESPACE temp_ts;

--Step 4: Configure Memory Parameters (SGA and PGA at PDB Level)
--These set minimum reservations and limits for the PDB.
-- Remain in the PDB session (CONTAINER = tue_29096_boris_acovs_db)

-- Set SGA target (minimum SGA reservation for this PDB)
ALTER SYSTEM SET sga_target = 1G SCOPE = BOTH;

-- Set PGA aggregate target and limit
ALTER SYSTEM SET pga_aggregate_target = 512M SCOPE = BOTH;
ALTER SYSTEM SET pga_aggregate_limit = 1G SCOPE = BOTH;

--Step 5: Grant Super Admin Privileges to the Admin User
--Enhance the admin user's privileges for full control within the PDB.
-- Remain in the PDB session

-- Grant DBA role for full administrative privileges
GRANT DBA TO boris_admin;

-- Grant SYSDBA for super admin access (local to PDB)
GRANT SYSDBA TO boris_admin CONTAINER = CURRENT;

-- Optional: Grant additional common privileges if needed
GRANT CREATE SESSION, CREATE TABLE, UNLIMITED TABLESPACE TO boris_admin;

--Step 6: Verification Queries
--Run these in the PDB to confirm the setup.
-- Switch to PDB if needed
ALTER SESSION SET CONTAINER = tue_29096_boris_acovs_db;

-- Verify tablespaces
SELECT tablespace_name, file_name, autoextensible FROM dba_data_files;
SELECT tablespace_name, file_name, autoextensible FROM dba_temp_files;

-- Verify default temporary tablespace
SELECT property_value FROM database_properties WHERE property_name = 'DEFAULT_TEMP_TABLESPACE';

-- Verify memory parameters
SHOW PARAMETER sga_target;
SHOW PARAMETER pga_aggregate_target;
SHOW PARAMETER pga_aggregate_limit;

-- Verify user privileges (run as SYS or with SELECT on DBA_SYS_PRIVS)
SELECT * FROM dba_sys_privs WHERE grantee = 'BORIS_ADMIN';
