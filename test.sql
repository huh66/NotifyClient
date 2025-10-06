/*
 * Test script for NOTIFY_CLIENT procedure
 */

-- Test 1: Simple call with EXECUTE PROCEDURE
SET TERM ^ ;
EXECUTE BLOCK
AS
BEGIN
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'Test-Header',
        'INFO',
        'Test-Betreff',
        123,
        'Hallo vom Firebird Server!',
        '',
        NULL
    );
END ^
SET TERM ; ^

COMMIT;

-- Test 2: Call with return value
SELECT RESULT 
FROM NOTIFY_CLIENT(
    'Test-Header 2',
    'WARN',
    'Test-Betreff 2',
    456,
    'Dies ist eine Test-Nachricht',
    '',
    NULL
);

COMMIT;

-- Test 3: In a transaction with multiple calls
SET TERM ^ ;
EXECUTE BLOCK
AS
    DECLARE result_code INTEGER;
BEGIN
    -- First message
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'Nachricht 1',
        'INFO',
        'Erste Testnachricht',
        100,
        'Dies ist die erste Nachricht',
        '',
        NULL
    ) RETURNING_VALUES :result_code;
    
    -- Second message
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'Nachricht 2',
        'ERROR',
        'Zweite Testnachricht',
        200,
        'Dies ist die zweite Nachricht',
        '',
        NULL
    ) RETURNING_VALUES :result_code;
    
    -- Output of last status
    -- 1 = successful, 0 = error
END ^
SET TERM ; ^

COMMIT;

