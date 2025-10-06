/*
 * Erweiterte Test-Skripte für NOTIFY_CLIENT Prozedur
 * Mit neuen Parametern: IPv4-Adresse und erweiterte Rückgabewerte
 */

-- Test 1: Mit bereitgestellter IPv4-Adresse
SELECT 
    RESULT,
    TIMESTAMP_VALUE,
    USED_IP_ADDRESS,
    SUMMARY_MESSAGE
FROM NOTIFY_CLIENT(
    'Test-Header',
    'INFO',
    'Test-Betreff',
    123,
    'Hallo vom Firebird Server!',
    '192.168.1.100',  -- Bereitgestellte IP
    NULL              -- Standard-Port 1526
);

COMMIT;

-- Test 2: Ohne IPv4-Adresse (automatische Ermittlung)
SELECT 
    RESULT,
    TIMESTAMP_VALUE,
    USED_IP_ADDRESS,
    SUMMARY_MESSAGE
FROM NOTIFY_CLIENT(
    'Auto-IP Test',
    'INFO',
    'Automatische IP-Ermittlung',
    456,
    'Die IP wird automatisch ermittelt',
    '',    -- Leere IP -> Fallback 127.0.0.1
    8080   -- Eigener Port
);

COMMIT;

-- Test 3: Mit ungültiger IPv4-Adresse (Fallback auf automatische Ermittlung)
SELECT 
    RESULT,
    TIMESTAMP_VALUE,
    USED_IP_ADDRESS,
    SUMMARY_MESSAGE
FROM NOTIFY_CLIENT(
    'Invalid IP Test',
    'WARN',
    'Ungültige IP-Adresse',
    789,
    'Ungültige IP wird ignoriert',
    '999.999.999.999',  -- Ungültige IP
    NULL                -- Standard-Port 1526
);

COMMIT;

-- Test 4: In einer Transaktion mit RETURNING_VALUES
SET TERM ^ ;
EXECUTE BLOCK
AS
    DECLARE result_code INTEGER;
    DECLARE timestamp_val TIMESTAMP;
    DECLARE used_ip VARCHAR(15);
    DECLARE summary_msg VARCHAR(1500);
BEGIN
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'Block Test',
        'ERROR',
        'Mit RETURNING_VALUES',
        1000,
        'Test in einem Block',
        '10.0.0.1',
        9000
    ) RETURNING_VALUES 
        :result_code,
        :timestamp_val,
        :used_ip,
        :summary_msg;
    
    -- Hier könnten Sie die Werte verwenden
    -- z.B. Logging, weitere Verarbeitung etc.
END ^
SET TERM ; ^

COMMIT;

-- Test 5: Mehrere Nachrichten in einer Schleife
SET TERM ^ ;
EXECUTE BLOCK
AS
    DECLARE i INTEGER = 1;
    DECLARE result_code INTEGER;
    DECLARE used_ip VARCHAR(15);
    DECLARE summary_msg VARCHAR(1500);
BEGIN
    WHILE (i <= 3) DO
    BEGIN
        EXECUTE PROCEDURE NOTIFY_CLIENT(
            'Schleifen-Test ' || i,
            'INFO',
            'Nachricht Nr. ' || i,
            i,
            'Dies ist Test-Nachricht Nummer ' || i,
            '127.0.0.1',
            NULL
        ) RETURNING_VALUES 
            :result_code,
            NULL,  -- timestamp
            :used_ip,
            :summary_msg;
        
        i = i + 1;
    END
END ^
SET TERM ; ^

COMMIT;

/*
 * Hinweise:
 * 
 * 1. RESULT = 1 bedeutet erfolgreiche Übertragung
 *    RESULT = 0 bedeutet Fehler (z.B. Client nicht erreichbar)
 * 
 * 2. TIMESTAMP_VALUE zeigt die Ausführungszeit
 * 
 * 3. USED_IP_ADDRESS zeigt die tatsächlich verwendete IP:
 *    - Bereitgestellte IP (wenn gültig)
 *    - Automatisch ermittelte Client-IP
 *    - "127.0.0.1" als Fallback
 * 
 * 4. SUMMARY_MESSAGE enthält: "Header | Subject | Referenz | Message"
 * 
 * 5. Für IPv4-Validierung: Format "x.x.x.x" mit Zahlen 0-255
 */
