use rusqlite::types::Type;
use uuid::Uuid;

use crate::db::{model::BlobRecord, uuid_blob::UuidBlobExt};

pub(crate) fn record_from_row(row: &rusqlite::Row<'_>) -> rusqlite::Result<BlobRecord> {
    let key_blob: Vec<u8> = row.get(0)?;
    let size_value: i64 = row.get(1)?;

    let key = Uuid::from_blob(key_blob)?;
    let size = usize::try_from(size_value).map_err(|error| {
        rusqlite::Error::FromSqlConversionFailure(1, Type::Integer, Box::new(error))
    })?;

    Ok(BlobRecord::new(key, size))
}
