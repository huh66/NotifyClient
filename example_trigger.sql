/*
 * Example triggers for NOTIFY_CLIENT procedure
 * 
 * These triggers show how NOTIFY_CLIENT can be used in various scenarios
 * to inform clients about changes.
 */

SET TERM ^ ;

-- Example 1: Trigger on INSERT
-- Assumption: BESTELLUNGEN table with fields BESTELL_NR, KUNDE, BETRAG

CREATE OR ALTER TRIGGER BESTELLUNG_INSERTED
AFTER INSERT ON BESTELLUNGEN
AS
BEGIN
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'Neue Bestellung',
        'Bestellung erfasst',
        NEW.BESTELL_NR,
        'Neue Bestellung Nr. ' || NEW.BESTELL_NR || 
        ' für Kunde ' || NEW.KUNDE || 
        ' über ' || NEW.BETRAG || ' EUR wurde erfasst.'
    );
END
^

-- Example 2: Trigger on UPDATE
CREATE OR ALTER TRIGGER BESTELLUNG_UPDATED
AFTER UPDATE ON BESTELLUNGEN
AS
BEGIN
    IF (OLD.STATUS <> NEW.STATUS) THEN
    BEGIN
        EXECUTE PROCEDURE NOTIFY_CLIENT(
            'Statusänderung',
            'Bestellung aktualisiert',
            NEW.BESTELL_NR,
            'Status von Bestellung Nr. ' || NEW.BESTELL_NR || 
            ' wurde von "' || OLD.STATUS || '" auf "' || NEW.STATUS || '" geändert.'
        );
    END
END
^

-- Example 3: Trigger on DELETE
CREATE OR ALTER TRIGGER BESTELLUNG_DELETED
AFTER DELETE ON BESTELLUNGEN
AS
BEGIN
    EXECUTE PROCEDURE NOTIFY_CLIENT(
        'Bestellung gelöscht',
        'Datensatz entfernt',
        OLD.BESTELL_NR,
        'Bestellung Nr. ' || OLD.BESTELL_NR || 
        ' für Kunde ' || OLD.KUNDE || ' wurde gelöscht.'
    );
END
^

-- Example 4: Trigger with condition (only for high amounts)
CREATE OR ALTER TRIGGER BESTELLUNG_HIGH_VALUE
AFTER INSERT ON BESTELLUNGEN
AS
BEGIN
    IF (NEW.BETRAG > 10000) THEN
    BEGIN
        EXECUTE PROCEDURE NOTIFY_CLIENT(
            'WICHTIG',
            'Hochwertige Bestellung',
            NEW.BESTELL_NR,
            'ACHTUNG: Hochwertige Bestellung über ' || NEW.BETRAG || 
            ' EUR wurde erfasst!'
        );
    END
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
 */

