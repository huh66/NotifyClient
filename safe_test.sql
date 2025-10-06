/*
 * Sicherer Test nach Firebird Neustart
 */

-- Prozedur löschen falls vorhanden
DROP PROCEDURE NOTIFY_CLIENT;
COMMIT;

-- Prozedur neu erstellen
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

-- Test 1: Einfacher Test mit localhost
SELECT 
    RESULT,
    TIMESTAMP_VALUE,
    USED_IP_ADDRESS,
    SUMMARY_MESSAGE
FROM NOTIFY_CLIENT(
    'Test1',
    'INFO',
    'Einfacher Test',
    1,
    'Hallo Welt',
    '127.0.0.1',
    NULL
);

COMMIT;

-- Test 2: Mit automatischer IP-Ermittlung (leerer String)
SELECT 
    RESULT,
    TIMESTAMP_VALUE,
    USED_IP_ADDRESS,
    SUMMARY_MESSAGE
FROM NOTIFY_CLIENT(
    'Test2',
    'WARN',
    'Auto-IP Test',
    2,
    'IP wird automatisch ermittelt',
    '',
    NULL
);

COMMIT;

-- Test 3: Mit NULL IPv4 (automatische Ermittlung)
SELECT 
    RESULT,
    TIMESTAMP_VALUE,
    USED_IP_ADDRESS,
    SUMMARY_MESSAGE
FROM NOTIFY_CLIENT(
    'Test3',
    'ERROR',
    'NULL-IP Test',
    3,
    'Test mit NULL IP',
    NULL,
    NULL
);

COMMIT;

/*
 * Erwartete Ergebnisse:
 * 
 * RESULT-Werte:
 *   1  = Nachricht erfolgreich gesendet
 *   0  = Verbindung fehlgeschlagen (Client nicht erreichbar)
 *  -1  = Fehler in der UDR (Exception)
 *  -2  = Unbekannter Fehler
 * 
 * Wenn kein Client auf Port 1526 lauscht: RESULT = 0 (normal)
 */

