/*
 * NotifyClient UDR - Installation Script
 * 
 * Usage:
 *   isql -user SYSDBA -password <password> <database> -i install.sql
 */

SET TERM ^ ;

-- Create procedure (or replace if exists)
CREATE OR ALTER PROCEDURE NOTIFY_CLIENT (
    HEADER VARCHAR(200),
    LEVEL VARCHAR(50),
    SUBJECT VARCHAR(200),
    REFERENZ INTEGER,
    MESSAGE VARCHAR(1000),
    IPV4_ADDRESS VARCHAR(15),
    PORT INTEGER
)
RETURNS (
    RESULT INTEGER,
    TIMESTAMP_VALUE TIMESTAMP,
    USED_IP_ADDRESS VARCHAR(15),
    SUMMARY_MESSAGE VARCHAR(1500)
)
EXTERNAL NAME 'notify_client_udr!notify_client'
ENGINE UDR
^

-- Add comment
COMMENT ON PROCEDURE NOTIFY_CLIENT IS 
'Sends a message over TCP/1526 to the calling client.
Input Parameters:
  HEADER       - Message header
  LEVEL        - Level (e.g. INFO/WARN/ERROR)
  SUBJECT      - Message subject
  REFERENZ     - Reference number (Integer)
  MESSAGE      - Message text
  IPV4_ADDRESS - Optional: IPv4 address (e.g. "192.168.1.100")
                If empty or invalid, 127.0.0.1 will be used
  PORT         - Optional: Port number (e.g. 1526)
                If NULL or <= 0, 1526 will be used
Return Parameters:
  RESULT            - 1 for successful transmission, 0 for error
  TIMESTAMP_VALUE   - Execution timestamp
  USED_IP_ADDRESS   - Actually used IP address
  SUMMARY_MESSAGE   - Summarized message: "Header | Level | Subject | Referenz | Message"
The message is formatted as JSON and sent to the IP address.'
^

SET TERM ; ^

COMMIT;

/* Test call (commented out)
EXECUTE PROCEDURE NOTIFY_CLIENT(
    'TestHeader', 
    'TestSubject', 
    123, 
    'Hallo vom Firebird Server!'
);
*/

