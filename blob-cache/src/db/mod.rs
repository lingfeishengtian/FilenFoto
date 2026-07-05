//! Database support for the blob cache.
//!
//! The blob payloads themselves live on disk through [`crate::files::FileStorage`],
//! but the cache still needs a metadata layer to answer questions like:
//!
//! - Does a blob exist for this key?
//! - What size should the blob have?
//! - Which records are safe to keep, repair, or delete during validation?
//!
//! This module is the home for that bookkeeping boundary. It intentionally stays
//! separate from the file-system code so the cache can treat metadata and payloads
//! as two different responsibilities.
//!
//! ## What belongs here
//!
//! - Blob metadata records and any lightweight indexing structures.
//! - Size accounting used by cache initialization and validation.
//! - Lookup, insert, update, and delete operations for blob records.
//! - Integrity checks that help reconcile disk state with cached metadata.
//!
//! ## What does not belong here
//!
//! - Reading or writing blob bytes on disk.
//! - Cache policy decisions such as eviction or high-level sync flows.
//! - UI or FFI concerns.
//!
//! ## Design intent
//!
//! Keep the API small and explicit. The cache layer should be able to ask for a
//! blob record, update the record after a write, remove the record after a delete,
//! and iterate records during validation without knowing anything about the actual
//! storage format used underneath.
//!
//! ## Status
//!
//! This module uses SQLite as the persistence backend.

use std::{path::Path, sync::Mutex};

use rusqlite::Connection;
use uuid::Uuid;

mod model;
mod read_ops;
mod row;
mod schema;
mod sql;
mod uuid_blob;
mod write_ops;

pub use model::BlobRecord;

/// SQLite-backed metadata storage for blobs.
///
/// The database is intentionally small and purpose-built. It stores one row per
/// blob and keeps the blob size alongside the UUID so the cache can make metadata
/// decisions without opening the blob file itself. The UUID is stored as a 16-byte
/// SQLite BLOB so the value stays binary rather than text-based.
pub struct BlobDatabase {
    connection: Mutex<Connection>,
}

impl BlobDatabase {
    /// Opens or creates the SQLite database at the provided path.
    ///
    /// The parent directory is created automatically when needed.
    pub fn open(database_path: impl AsRef<Path>) -> rusqlite::Result<Self> {
        let database_path = database_path.as_ref();

        if let Some(parent_dir) = database_path.parent() {
            std::fs::create_dir_all(parent_dir)
                .map_err(|error| rusqlite::Error::ToSqlConversionFailure(Box::new(error)))?;
        }

        let connection = Connection::open(database_path)?;
        schema::initialize(&connection)?;

        Ok(Self {
            connection: Mutex::new(connection),
        })
    }

    fn connection(&self) -> std::sync::MutexGuard<'_, Connection> {
        self.connection
            .lock()
            .expect("blob database connection lock poisoned")
    }

    /// Returns the number of blob rows currently stored.
    pub fn len(&self) -> rusqlite::Result<usize> {
        let connection = self.connection();
        read_ops::len(&connection)
    }

    /// Returns the total tracked size of all blobs in bytes.
    pub fn total_size(&self) -> rusqlite::Result<usize> {
        let connection = self.connection();
        read_ops::total_size(&connection)
    }

    /// Returns the record for the provided key, if one exists.
    pub fn get(&self, key: &Uuid) -> rusqlite::Result<Option<BlobRecord>> {
        let connection = self.connection();
        read_ops::get(&connection, key)
    }

    /// Returns `true` when a record exists for the provided key.
    pub fn contains(&self, key: &Uuid) -> rusqlite::Result<bool> {
        let connection = self.connection();
        Ok(read_ops::get(&connection, key)?.is_some())
    }

    /// Inserts or replaces a blob record.
    ///
    /// This is the main entry point for write paths that need to keep metadata in
    /// sync with file writes.
    pub fn upsert(&self, key: Uuid, size: usize) -> rusqlite::Result<BlobRecord> {
        let connection = self.connection();
        write_ops::upsert(&connection, key, size)
    }

    /// Updates just the stored size for an existing record.
    ///
    /// Returns the updated record when the key exists, or `None` when the key is
    /// unknown.
    pub fn update_size(&self, key: &Uuid, size: usize) -> rusqlite::Result<Option<BlobRecord>> {
        let connection = self.connection();
        write_ops::update_size(&connection, key, size)
    }

    /// Removes a blob record from the database.
    pub fn delete(&self, key: &Uuid) -> rusqlite::Result<bool> {
        let connection = self.connection();
        write_ops::delete(&connection, key)
    }

    /// Removes all blob records from the database.
    pub fn clear(&self) -> rusqlite::Result<()> {
        let connection = self.connection();
        write_ops::clear(&connection)
    }

    /// Returns the keys for all tracked records.
    pub fn keys(&self) -> rusqlite::Result<Vec<Uuid>> {
        let connection = self.connection();
        read_ops::keys(&connection)
    }

    /// Returns a snapshot of all records currently stored.
    pub fn records(&self) -> rusqlite::Result<Vec<BlobRecord>> {
        let connection = self.connection();
        read_ops::records(&connection)
    }
}

#[cfg(test)]
mod tests;
