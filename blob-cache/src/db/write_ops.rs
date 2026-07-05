use rusqlite::{Connection, params};
use uuid::Uuid;

use crate::db::{
    model::BlobRecord,
    sql::{CLEAR_SQL, DELETE_BY_KEY_SQL, UPDATE_SIZE_SQL, UPSERT_SQL},
    uuid_blob::UuidBlobExt,
};

pub(crate) fn upsert(
    connection: &Connection,
    key: Uuid,
    size: usize,
) -> rusqlite::Result<BlobRecord> {
    connection.execute(
        UPSERT_SQL,
        params![
            key.to_blob(),
            i64::try_from(size).expect("blob size exceeds i64")
        ],
    )?;

    Ok(BlobRecord::new(key, size))
}

pub(crate) fn update_size(
    connection: &Connection,
    key: &Uuid,
    size: usize,
) -> rusqlite::Result<Option<BlobRecord>> {
    let rows_affected = connection.execute(
        UPDATE_SIZE_SQL,
        params![
            key.to_blob(),
            i64::try_from(size).expect("blob size exceeds i64")
        ],
    )?;

    if rows_affected == 0 {
        return Ok(None);
    }

    Ok(Some(BlobRecord::new(*key, size)))
}

pub(crate) fn delete(connection: &Connection, key: &Uuid) -> rusqlite::Result<bool> {
    Ok(connection.execute(DELETE_BY_KEY_SQL, params![key.to_blob()])? > 0)
}

pub(crate) fn clear(connection: &Connection) -> rusqlite::Result<()> {
    connection.execute(CLEAR_SQL, [])?;
    Ok(())
}
