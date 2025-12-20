# Oracle Pluggable Database Setup Guide
## Automated Customer Order Validation System

**Author:** SHEJA RADAN BORIS  
**Student ID:** 29096  
**Database:** Oracle 21c Express Edition  
**PDB Name:** `tue_29096_boris_acovs_db`

---

## 📋 Overview

This script configures a dedicated Oracle Pluggable Database (PDB) for the Automated Customer Order Validation System with:
- Archive logging enabled for backup/recovery
- Custom tablespaces with auto-extend
- Optimized memory allocation (SGA/PGA)
- Super admin privileges for full control

---

## 🚀 Quick Setup

### Prerequisites
- Oracle 21c Express Edition installed
- SYSDBA access
- Windows environment (paths are Windows-specific)

### Installation Steps

```sql
-- 1. Connect as SYSDBA
sqlplus / as sysdba

-- 2. Run the complete setup script
@DB_Phase_4.sql
```

---

## 📂 What Gets Created

### 1. **Pluggable Database**
- **Name:** `tue_29096_boris_acovs_db`
- **Admin User:** `boris_admin`
- **Password:** `admin`
- **Location:** `C:\APP\ORADATA\XE\tue_29096_boris_acovs_db\`

### 2. **Tablespaces**
| Tablespace | Size | Auto-Extend | Purpose |
|------------|------|-------------|---------|
| `data_ts` | 100 MB | +10 MB increments | Table data storage |
| `index_ts` | 50 MB | +10 MB increments | Index storage |
| `temp_ts` | 50 MB | +10 MB increments | Temporary operations |

### 3. **Memory Configuration**
- **SGA Target:** 1 GB (System Global Area)
- **PGA Aggregate Target:** 512 MB (Program Global Area)
- **PGA Aggregate Limit:** 1 GB (Maximum PGA)

### 4. **User Privileges**
Admin user `boris_admin` granted:
- ✅ DBA role (full database administration)
- ✅ SYSDBA privilege (super admin access)
- ✅ CREATE SESSION, CREATE TABLE, UNLIMITED TABLESPACE

---

## 🔐 Archive Logging

**Status:** ENABLED (ARCHIVELOG mode)

**Benefits:**
- Point-in-time recovery
- Online backups without downtime
- Complete transaction history
- Disaster recovery capability

**Verification:**
```sql
SELECT log_mode FROM v$database;
-- Expected: ARCHIVELOG
```

---

## ✅ Verification Checklist

After running the script, verify setup:

```sql
-- 1. Check PDB exists and is open
SHOW PDBS;
-- Expected: TUE_29096_BORIS_ACOVS_DB - READ WRITE

-- 2. Switch to PDB
ALTER SESSION SET CONTAINER = tue_29096_boris_acovs_db;

-- 3. Verify tablespaces
SELECT tablespace_name, file_name, autoextensible 
FROM dba_data_files;
-- Expected: 3 tablespaces, all with AUTOEXTENSIBLE = YES

-- 4. Check memory settings
SHOW PARAMETER sga_target;
-- Expected: 1G

-- 5. Verify admin privileges
SELECT * FROM dba_sys_privs WHERE grantee = 'BORIS_ADMIN';
-- Expected: DBA, SYSDBA, CREATE SESSION, etc.
```

---

## 📊 Database Specifications

### System Resources
```
Total SGA: 1,610,609,432 bytes (~1.5 GB)
Fixed Size: 9,855,768 bytes
Variable Size: 989,855,744 bytes
Database Buffers: 603,979,776 bytes
Redo Buffers: 6,918,144 bytes
```

### Tablespace Autoextend
- **Increment:** 10 MB per extension
- **Max Size:** UNLIMITED
- **Prevents:** "Out of space" errors during growth

---

## 🔌 Connection Strings

### Connect as Super Admin
```bash
sqlplus boris_admin/admin@localhost:1521/tue_29096_boris_acovs_db as sysdba
```

### Connect as Regular Admin
```bash
sqlplus boris_admin/admin@localhost:1521/tue_29096_boris_acovs_db
```

### SQL Developer Connection
```
Connection Name: ACOVS_PDB
Username: boris_admin
Password: admin
Hostname: localhost
Port: 1521
Service Name: tue_29096_boris_acovs_db
```

---

## 📁 File Locations

All database files stored in:
```
C:\APP\ORADATA\XE\tue_29096_boris_acovs_db\
```

**Files Created:**
- `system01.dbf` - System tablespace
- `sysaux01.dbf` - System auxiliary
- `undotbs01.dbf` - Undo tablespace
- `data_ts.dbf` - Custom data tablespace (100 MB)
- `index_ts.dbf` - Custom index tablespace (50 MB)
- `temp_ts.dbf` - Temporary tablespace (50 MB)

---

## 🛠️ Troubleshooting

### Issue: PDB not opening
```sql
ALTER PLUGGABLE DATABASE tue_29096_boris_acovs_db OPEN;
```

### Issue: Cannot connect as SYSDBA
```sql
-- Reconnect to CDB first
CONNECT / AS SYSDBA
ALTER SESSION SET CONTAINER = tue_29096_boris_acovs_db;
GRANT SYSDBA TO boris_admin CONTAINER = CURRENT;
```

### Issue: Tablespace full
- Auto-extend is enabled (UNLIMITED)
- Check disk space: Ensure Windows drive has free space
- Verify: `SELECT * FROM dba_data_files;`

### Issue: Archive destination full
```sql
-- Check archive log destination
SHOW PARAMETER db_recovery_file_dest;
-- Increase size if needed
ALTER SYSTEM SET db_recovery_file_dest_size = 20G;
```

---

## 🔄 Next Steps

After successful setup:

1. **Create application schema**
   ```sql
   CREATE USER order_user IDENTIFIED BY password;
   GRANT CONNECT, RESOURCE TO order_user;
   ALTER USER order_user QUOTA UNLIMITED ON data_ts;
   ```

2. **Run table creation scripts**
   ```sql
   @01_create_tables.sql
   @02_create_sequences.sql
   @03_create_indexes.sql
   ```

3. **Load sample data**
   ```sql
   @04_insert_data.sql
   ```

4. **Create PL/SQL objects**
   ```sql
   @05_functions.sql
   @06_procedures.sql
   @07_packages.sql
   @08_triggers.sql
   ```

---

## 📊 Setup Execution Results

Based on the provided screenshots, here's what was successfully configured:

### ✅ Archive Logging
```
LOG_MODE
------------
ARCHIVELOG
```
**Status:** Enabled successfully

### ✅ PDB Creation
```
Pluggable database created.
```
**PDB Name:** TUE_29096_BORIS_ACOVS_DB  
**Status:** MOUNTED initially, then OPENED

### ✅ Tablespace Creation
```
Tablespace created. (x3)
```
**Created:**
- `data_ts` - 100 MB with autoextend
- `index_ts` - 50 MB with autoextend  
- `temp_ts` - 50 MB with autoextend (set as default)

### ✅ Memory Configuration
```
sga_target = 1G
pga_aggregate_target = 512M
pga_aggregate_limit = 1G
```
**All parameters:** System altered successfully

### ✅ User Privileges
```
Grant succeeded. (x3)
```
**boris_admin granted:**
- DBA role
- SYSDBA privilege
- CREATE SESSION, CREATE TABLE, UNLIMITED TABLESPACE

### ✅ Verification Results

**Tablespaces (dba_data_files):**
```
SYSTEM     - C:\...\SYSTEM01.DBF     - YES
SYSAUX     - C:\...\SYSAUX01.DBF     - YES
UNDOTBS1   - C:\...\UNDOTBS01.DBF    - YES
DATA_TS    - C:\...\DATA_TS.DBF      - YES ✓
INDEX_TS   - C:\...\INDEX_TS.DBF     - YES ✓
```

**Temp Tablespaces (dba_temp_files):**
```
TEMP       - C:\...\TEMP01...DBF     - YES
TEMP_TS    - C:\...\TEMP_TS.DBF      - YES ✓
```

**Default Temporary Tablespace:**
```
PROPERTY_VALUE
--------------
TEMP_TS ✓
```

---

## 📦 Database File Summary

### Data Files (Total: 5)
1. **SYSTEM** - 250 MB (Oracle system tablespace)
2. **SYSAUX** - 190 MB (System auxiliary)
3. **UNDOTBS1** - 70 MB (Undo tablespace)
4. **DATA_TS** - 100 MB (Custom data) ✓
5. **INDEX_TS** - 50 MB (Custom indexes) ✓

### Temp Files (Total: 2)
1. **TEMP** - 36 MB (Default temporary)
2. **TEMP_TS** - 50 MB (Custom temporary) ✓

**Total Database Size:** ~746 MB initial allocation  
**Growth:** Unlimited with 10 MB increments

---

## 🎯 Performance Tuning

### Memory Allocation
```
Component               Size
----------------------  --------
SGA Target              1 GB
PGA Aggregate Target    512 MB
PGA Aggregate Limit     1 GB
Total Allocated         ~2.5 GB
```

### Recommendations
- **Small workload (< 100 concurrent users):** Current settings optimal
- **Medium workload (100-500 users):** Increase SGA to 2 GB
- **Large workload (500+ users):** Increase SGA to 4 GB, PGA to 1 GB

---

## 🔍 Monitoring Commands

### Check PDB Status
```sql
SELECT name, open_mode, restricted, open_time 
FROM v$pdbs 
WHERE name = 'TUE_29096_BORIS_ACOVS_DB';
```

### Check Tablespace Usage
```sql
SELECT 
    tablespace_name,
    ROUND(SUM(bytes)/1024/1024, 2) AS size_mb,
    ROUND(SUM(maxbytes)/1024/1024, 2) AS max_size_mb,
    COUNT(*) AS datafiles
FROM dba_data_files
GROUP BY tablespace_name;
```

### Check Memory Usage
```sql
SELECT 
    name,
    ROUND(value/1024/1024, 2) AS value_mb
FROM v$parameter
WHERE name IN ('sga_target', 'pga_aggregate_target', 'pga_aggregate_limit');
```

### Check Archive Log Usage
```sql
SELECT 
    ROUND(SUM(blocks * block_size)/1024/1024, 2) AS archive_size_mb,
    COUNT(*) AS archive_count
FROM v$archived_log
WHERE first_time > SYSDATE - 7;
```

---

## 📞 Support & Contact

**Database Administrator:** SHEJA RADAN BORIS  
**Student ID:** 29096  
**Email:** boris.sheja@student.auca.ac.rw  
**Institution:** Adventist University of Central Africa (AUCA)  
**Project:** Automated Customer Order Validation System

---

## 📄 Related Documentation

- [Main Project README](../README.md)
- [Installation Guide](../documentation/installation_guide.md)
- [Data Dictionary](../documentation/data_dictionary.md)
- [SQL Scripts](../database/scripts/)

---

## ⚠️ Important Notes

1. **Security:** Change default password `admin` before production use
2. **Backup:** Configure RMAN backups after initial setup
3. **Monitoring:** Set up alerts for tablespace usage and archive log space
4. **Maintenance:** Schedule regular statistics gathering and index rebuilds
5. **Documentation:** Update this README if configuration changes

---

## ✅ Final Status

**PDB Setup:** ✅ COMPLETE  
**Archive Logging:** ✅ ENABLED  
**Tablespaces:** ✅ CREATED (3/3)  
**Memory Config:** ✅ OPTIMIZED  
**Admin User:** ✅ CONFIGURED  
**Verification:** ✅ ALL PASSED  

**System Status:** 🟢 READY FOR APPLICATION DEPLOYMENT

---

**Setup Date:** December 2024  
**Oracle Version:** 21c Express Edition Release 21.0.0.0.0  
**Configuration File:** DB_Phase_4.sql  
**Documentation Version:** 1.0

---

## 🎉 Success!

Your Oracle Pluggable Database is now configured and ready for the Automated Customer Order Validation System!

Next step: Deploy the application tables and PL/SQL objects.

```sql
-- Quick connection test
CONNECT boris_admin/admin@localhost:1521/tue_29096_boris_acovs_db

-- You should see:
-- Connected.
```

---

**END OF README**