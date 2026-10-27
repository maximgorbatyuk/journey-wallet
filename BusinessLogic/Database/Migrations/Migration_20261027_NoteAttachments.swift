import Foundation
import SQLite

final class Migration20261027NoteAttachments {
    private let connection: Connection

    init(db connection: Connection) {
        self.connection = connection
    }

    func execute() throws {
        try connection.transaction {
            try connection.execute("""
            CREATE TABLE IF NOT EXISTS note_links (
                id TEXT PRIMARY KEY NOT NULL,
                note_id TEXT NOT NULL,
                title TEXT NOT NULL,
                url TEXT NOT NULL,
                sort_order INTEGER NOT NULL DEFAULT 0
            );
            CREATE INDEX IF NOT EXISTS note_links_note_order ON note_links(note_id, sort_order);
            CREATE TABLE IF NOT EXISTS note_documents (
                note_id TEXT NOT NULL,
                document_id TEXT NOT NULL,
                sort_order INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY (note_id, document_id)
            );
            CREATE INDEX IF NOT EXISTS note_documents_document ON note_documents(document_id);
            CREATE INDEX IF NOT EXISTS note_documents_note_order ON note_documents(note_id, sort_order);
            """)
            try createReferenceGuards()
            try createCleanupTriggers()
        }
    }

    private func createReferenceGuards() throws {
        try connection.execute("""
        CREATE TRIGGER IF NOT EXISTS note_links_require_note
        BEFORE INSERT ON note_links BEGIN
            SELECT RAISE(ABORT, 'Note does not exist')
            WHERE NOT EXISTS (SELECT 1 FROM notes WHERE id = NEW.note_id);
        END;
        CREATE TRIGGER IF NOT EXISTS note_documents_require_same_journey
        BEFORE INSERT ON note_documents BEGIN
            SELECT RAISE(ABORT, 'Document must belong to the note journey')
            WHERE NOT EXISTS (
                SELECT 1 FROM notes JOIN documents ON notes.journey_id = documents.journey_id
                WHERE notes.id = NEW.note_id AND documents.id = NEW.document_id
            );
        END;
        """)
    }

    private func createCleanupTriggers() throws {
        // Triggers also protect changes made by the Share Extension and bulk repository operations.
        try connection.execute("""
        CREATE TRIGGER IF NOT EXISTS notes_delete_attachments
        AFTER DELETE ON notes BEGIN
            DELETE FROM note_links WHERE note_id = OLD.id;
            DELETE FROM note_documents WHERE note_id = OLD.id;
        END;
        CREATE TRIGGER IF NOT EXISTS documents_delete_note_attachments
        AFTER DELETE ON documents BEGIN
            DELETE FROM note_documents WHERE document_id = OLD.id;
        END;
        CREATE TRIGGER IF NOT EXISTS notes_move_attachments
        AFTER UPDATE OF journey_id ON notes BEGIN
            DELETE FROM note_documents
            WHERE note_id = NEW.id AND document_id NOT IN (
                SELECT id FROM documents WHERE journey_id = NEW.journey_id
            );
        END;
        CREATE TRIGGER IF NOT EXISTS documents_move_note_attachments
        AFTER UPDATE OF journey_id ON documents BEGIN
            DELETE FROM note_documents
            WHERE document_id = NEW.id AND note_id NOT IN (
                SELECT id FROM notes WHERE journey_id = NEW.journey_id
            );
        END;
        CREATE TRIGGER IF NOT EXISTS journeys_delete_note_attachments
        AFTER DELETE ON journeys BEGIN
            DELETE FROM note_links WHERE note_id IN (SELECT id FROM notes WHERE journey_id = OLD.id);
            DELETE FROM note_documents
            WHERE note_id IN (SELECT id FROM notes WHERE journey_id = OLD.id)
                OR document_id IN (SELECT id FROM documents WHERE journey_id = OLD.id);
        END;
        """)
    }
}
