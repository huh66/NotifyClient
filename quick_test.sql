/*
 * Quick test: Reload and test procedure
 */

-- Delete procedure if exists
DROP PROCEDURE NOTIFY_CLIENT;
COMMIT;

-- Recreate procedure
SET TERM ^ ;

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
EXTERNAL NAME 'simple_message_udr!send_message'
ENGINE UDR
^

SET TERM ; ^

COMMIT;

-- Test
SELECT 
    RESULT,
    TIMESTAMP_VALUE,
    USED_IP_ADDRESS,
    SUMMARY_MESSAGE
FROM NOTIFY_CLIENT(
    'Test',
    'INFO',
    'Schnelltest',
    999,
    'Dies ist ein Schnelltest',
    '127.0.0.1',
    NULL
);

COMMIT;

