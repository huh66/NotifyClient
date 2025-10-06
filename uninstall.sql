/*
 * Simple Message UDR - Uninstallation Script
 * 
 * Usage:
 *   isql -user SYSDBA -password <password> <database> -i uninstall.sql
 */

-- Remove procedure
DROP PROCEDURE NOTIFY_CLIENT;

COMMIT;

