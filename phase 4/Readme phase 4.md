# Oracle Pluggable Database Setup Guide
## Automated Customer Order Validation System
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

### Installation Steps

```sql
--  Connect as SYSDBA
system / as sysdba

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


- **Increment:** 10 MB per extension
- **Max Size:** UNLIMITED
- **Prevents:** "Out of space" errors during growth

---

## 🔌 Connection Strings

### Connect as Super Admin
```bash
sqlplus boris_admin/admin@localhost:1521/tue_29096_boris_acovs_db as sysdba
```

### SQL Developer Connection
```
Connection Name: DB
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
<img width="960" height="425" alt="CREATE PLUGGABLE DATABASE" src="https://github.com/user-attachments/assets/cef42791-fbfa-44e4-af35-c0256caf1905" />

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
<img width="960" height="504" alt="open pdb and creating tablespace " src="https://github.com/user-attachments/assets/69250d6a-a1ca-4643-bbcb-01db294cf786" />
```
### ✅ Memory Configuration
```
sga_target = 1G
pga_aggregate_target = 512M
pga_aggregate_limit = 1G
<img width="960" height="205" alt="onfigure Memory Parameters (SGA and PGA at PDB Level)" src="https://github.com/user-attachments/assets/9c32f1c8-85d5-4776-9f89-322c90d77982" />

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
<img width="960" height="207" alt="Grant Super Admin Privileges to the Admin User" src="https://github.com/user-attachments/assets/b93abf09-5899-42d8-8154-33f4bc231742" />

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

**END OF README**
