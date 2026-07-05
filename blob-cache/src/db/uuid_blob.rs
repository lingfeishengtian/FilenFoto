use rusqlite::types::Type;
use uuid::Uuid;

/// UUID helpers for converting to and from SQLite BLOB values.
pub(crate) trait UuidBlobExt {
    fn to_blob(&self) -> [u8; 16];
    fn from_blob(key_blob: Vec<u8>) -> rusqlite::Result<Uuid>;
}

impl UuidBlobExt for Uuid {
    fn to_blob(&self) -> [u8; 16] {
        *self.as_bytes()
    }

    fn from_blob(key_blob: Vec<u8>) -> rusqlite::Result<Uuid> {
        Uuid::from_slice(&key_blob).map_err(|error| {
            rusqlite::Error::FromSqlConversionFailure(0, Type::Blob, Box::new(error))
        })
    }
}
