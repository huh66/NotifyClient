/*
 * Example triggers for NOTIFY_CLIENT procedure
 * 
 * These triggers show how NOTIFY_CLIENT can be used in various scenarios
 * to inform clients about changes.
 */

SET TERM ^ ;

-- Example 1: Trigger on INSERT with client IP detection
-- Assumption: BESTELLUNGEN table with fields BESTELL_NR, KUNDE, BETRAG

CREATE OR ALTER TRIGGER BESTELLUNG_INSERTED
AFTER INSERT ON BESTELLUNGEN
AS
DECLARE client_ip VARCHAR(15);
BEGIN
    -- Get client IP from Firebird context
    client_ip = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
    
    -- If client IP is not available, use empty string for automatic detection
    IF (client_ip IS NULL OR client_ip = '') THEN
        client_ip = '';
    
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'New Order',
        'INFO',
        'Order Recorded',
        NEW.BESTELL_NR,
        'New order No. ' || NEW.BESTELL_NR || 
        ' for customer ' || NEW.KUNDE || 
        ' with amount ' || NEW.BETRAG || ' EUR has been recorded.',
        client_ip,  -- Use detected client IP
        NULL
    );
END
^

-- Example 2: Trigger on UPDATE with client IP detection
CREATE OR ALTER TRIGGER BESTELLUNG_UPDATED
AFTER UPDATE ON BESTELLUNGEN
AS
DECLARE client_ip VARCHAR(15);
BEGIN
    IF (OLD.STATUS <> NEW.STATUS) THEN
    BEGIN
        -- Get client IP from Firebird context
        client_ip = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
        
        -- If client IP is not available, use empty string for automatic detection
        IF (client_ip IS NULL OR client_ip = '') THEN
            client_ip = '';
        
        EXECUTE PROCEDURE NOTIFY_CLIENT(
            'Status Change',
            'WARN',
            'Order Updated',
            NEW.BESTELL_NR,
            'Status of order No. ' || NEW.BESTELL_NR || 
            ' has been changed from "' || OLD.STATUS || '" to "' || NEW.STATUS || '"',
            client_ip,  -- Use detected client IP
            NULL
        );
    END
END
^

-- Example 3: Trigger on DELETE with client IP detection
CREATE OR ALTER TRIGGER BESTELLUNG_DELETED
AFTER DELETE ON BESTELLUNGEN
AS
DECLARE client_ip VARCHAR(15);
BEGIN
    -- Get client IP from Firebird context
    client_ip = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
    
    -- If client IP is not available, use empty string for automatic detection
    IF (client_ip IS NULL OR client_ip = '') THEN
        client_ip = '';
    
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'Order Deleted',
        'ERROR',
        'Record Removed',
        OLD.BESTELL_NR,
        'Order No. ' || OLD.BESTELL_NR || 
        ' for customer ' || OLD.KUNDE || ' has been deleted.',
        client_ip,  -- Use detected client IP
        NULL
    );
END
^

-- Example 4: Trigger with condition (only for high amounts) and client IP detection
CREATE OR ALTER TRIGGER BESTELLUNG_HIGH_VALUE
AFTER INSERT ON BESTELLUNGEN
AS
DECLARE client_ip VARCHAR(15);
BEGIN
    IF (NEW.BETRAG > 10000) THEN
    BEGIN
        -- Get client IP from Firebird context
        client_ip = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
        
        -- If client IP is not available, use empty string for automatic detection
        IF (client_ip IS NULL OR client_ip = '') THEN
            client_ip = '';
        
        EXECUTE PROCEDURE NOTIFY_CLIENT(
            'HIGH VALUE',
            'ERROR',
            'High Value Order',
            NEW.BESTELL_NR,
            'ATTENTION: High value order of ' || NEW.BETRAG || 
            ' EUR has been recorded!',
            client_ip,  -- Use detected client IP
            NULL
        );
    END
END
^

-- Example 5: Trigger with client IP detection and custom port
CREATE OR ALTER TRIGGER BESTELLUNG_SPECIFIC_CLIENT
AFTER INSERT ON BESTELLUNGEN
AS
DECLARE client_ip VARCHAR(15);
BEGIN
    -- Get client IP from Firebird context
    client_ip = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
    
    -- If client IP is not available, use fallback IP
    IF (client_ip IS NULL OR client_ip = '') THEN
        client_ip = '192.168.1.100';  -- Fallback to specific client IP
    
    -- Send to detected client IP with custom port
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'New Order',
        'INFO',
        'Order Notification',
        NEW.BESTELL_NR,
        'Order ' || NEW.BESTELL_NR || ' has been created.',
        client_ip,  -- Use detected client IP or fallback
        8080        -- Custom port
    );
END
^

-- Example 6: Trigger with client IP detection and custom port
CREATE OR ALTER TRIGGER BESTELLUNG_CUSTOM_PORT
AFTER UPDATE ON BESTELLUNGEN
AS
DECLARE client_ip VARCHAR(15);
BEGIN
    -- Get client IP from Firebird context
    client_ip = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
    
    -- If client IP is not available, use empty string for automatic detection
    IF (client_ip IS NULL OR client_ip = '') THEN
        client_ip = '';
    
    -- Use detected client IP with custom port
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'Order Updated',
        'INFO',
        'Order Modified',
        NEW.BESTELL_NR,
        'Order ' || NEW.BESTELL_NR || ' has been updated.',
        client_ip,  -- Use detected client IP or empty string
        9000        -- Custom port
    );
END
^

-- Example 7: Trigger for different notification levels with client IP detection
CREATE OR ALTER TRIGGER BESTELLUNG_NOTIFICATION_LEVELS
AFTER INSERT ON BESTELLUNGEN
AS
DECLARE client_ip VARCHAR(15);
BEGIN
    -- Get client IP from Firebird context once for all conditions
    client_ip = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
    
    -- If client IP is not available, use empty string for automatic detection
    IF (client_ip IS NULL OR client_ip = '') THEN
        client_ip = '';
    
    IF (NEW.BETRAG < 100) THEN
    BEGIN
        -- Low value order - INFO level
        EXECUTE PROCEDURE NOTIFY_CLIENT(
            'Low Value Order',
            'INFO',
            'Small Order',
            NEW.BESTELL_NR,
            'Small order ' || NEW.BESTELL_NR || ' for ' || NEW.BETRAG || ' EUR.',
            client_ip,  -- Use detected client IP
            NULL
        );
    END
    ELSE IF (NEW.BETRAG > 10000) THEN
    BEGIN
        -- High value order - ERROR level
        EXECUTE PROCEDURE NOTIFY_CLIENT(
            'High Value Order',
            'ERROR',
            'Large Order Alert',
            NEW.BESTELL_NR,
            'LARGE ORDER: ' || NEW.BESTELL_NR || ' for ' || NEW.BETRAG || ' EUR!',
            client_ip,  -- Use detected client IP
            NULL
        );
    END
    ELSE
    BEGIN
        -- Normal order - WARN level
        EXECUTE PROCEDURE NOTIFY_CLIENT(
            'Normal Order',
            'WARN',
            'Standard Order',
            NEW.BESTELL_NR,
            'Order ' || NEW.BESTELL_NR || ' for ' || NEW.BETRAG || ' EUR processed.',
            client_ip,  -- Use detected client IP
            NULL
        );
    END
END
^

-- Example 8: Advanced trigger with client IP logging and conditional notifications
CREATE OR ALTER TRIGGER BESTELLUNG_ADVANCED_CLIENT_DETECTION
AFTER INSERT ON BESTELLUNGEN
AS
DECLARE client_ip VARCHAR(15);
DECLARE client_name VARCHAR(255);
BEGIN
    -- Get comprehensive client information
    client_ip = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
    client_name = rdb$get_context('SYSTEM', 'CLIENT_PROCESS');
    
    -- Log client information (optional)
    -- INSERT INTO AUDIT_LOG (CLIENT_IP, CLIENT_NAME, ORDER_NR, TIMESTAMP) 
    -- VALUES (client_ip, client_name, NEW.BESTELL_NR, CURRENT_TIMESTAMP);
    
    -- Send notification with client information
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'Order from ' || COALESCE(client_name, 'Unknown Client'),
        'INFO',
        'Client-Specific Order',
        NEW.BESTELL_NR,
        'Order ' || NEW.BESTELL_NR || ' from IP ' || COALESCE(client_ip, 'Unknown') ||
        ' (Process: ' || COALESCE(client_name, 'Unknown') || ') - Amount: ' || NEW.BETRAG || ' EUR',
        COALESCE(client_ip, ''),  -- Use detected IP or fallback to empty string
        NULL
    );
END
^

SET TERM ; ^

COMMIT;

/*
 * Notes:
 * 
 * 1. Adapt table names and field names to your database
 * 2. Triggers are executed asynchronously - there is no guarantee
 *    that the client receives the message
 * 3. If the client is not reachable, the transaction will still
 *    be completed successfully (Fire-and-Forget principle)
 * 4. For productive environments you should add error handling
 * 5. IP Address Parameter:
 *    - Empty string ('') = automatic IP detection
 *    - Specific IP ('192.168.1.100') = send to that client
 * 6. Port Parameter:
 *    - NULL = use default port 1526
 *    - Specific number (8080) = use that port
 * 7. Level Parameter:
 *    - 'INFO' = informational messages
 *    - 'WARN' = warning messages  
 *    - 'ERROR' = error/critical messages
 * 8. Client IP Detection with rdb$get_context:
 *    - rdb$get_context('SYSTEM', 'CLIENT_ADDRESS') returns the client IP
 *    - This is more reliable than automatic detection in the UDR
 *    - Falls back to empty string if IP cannot be determined
 *    - Examples 1 and 2 demonstrate this approach
 */

