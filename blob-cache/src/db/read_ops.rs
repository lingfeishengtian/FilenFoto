use rusqlite::{Connection, OptionalExtension, params, types::Type};
use uuid::Uuid;

use crate::db::{
    model::BlobRecord,
    row::record_from_row,
    sql::{
        COUNT_RECORDS_SQL, SELECT_BY_KEY_SQL, SELECT_KEYS_SQL, SELECT_RECORDS_SQL, TOTAL_SIZE_SQL,
    },
    uuid_blob::UuidBlobExt,
};

pub(crate) fn len(connection: &Connection) -> rusqlite::Result<usize> {
    let count: i64 = connection.query_row(COUNT_RECORDS_SQL, [], |row| row.get(0))?;
    usize::try_from(count).map_err(|error| {
        rusqlite::Error::FromSqlConversionFailure(0, Type::Integer, Box::new(error))
    })
}

pub(crate) fn total_size(connection: &Connection) -> rusqlite::Result<usize> {
    let size: i64 = connection.query_row(TOTAL_SIZE_SQL, [], |row| row.get(0))?;
    usize::try_from(size).map_err(|error| {
        rusqlite::Error::FromSqlConversionFailure(0, Type::Integer, Box::new(error))
    })
}

pub(crate) fn get(connection: &Connection, key: &Uuid) -> rusqlite::Result<Option<BlobRecord>> {
    connection
        .query_row(SELECT_BY_KEY_SQL, params![key.to_blob()], record_from_row)
        .optional()
}

pub(crate) fn keys(connection: &Connection) -> rusqlite::Result<Vec<Uuid>> {
    let mut statement = connection.prepare(SELECT_KEYS_SQL)?;
    statement
        .query_map([], |row| {
            let key_blob: Vec<u8> = row.get(0)?;
            Uuid::from_blob(key_blob)
        })?
        .collect()
}

pub(crate) fn records(connection: &Connection) -> rusqlite::Result<Vec<BlobRecord>> {
    let mut statement = connection.prepare(SELECT_RECORDS_SQL)?;
    statement.query_map([], record_from_row)?.collect()
}
