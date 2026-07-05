use rusqlite::Connection;

pub(crate) const CREATE_TABLE_SQL: &str = r#"
		CREATE TABLE IF NOT EXISTS blobs (
			key BLOB PRIMARY KEY NOT NULL,
			size INTEGER NOT NULL CHECK(size >= 0)
		)
	"#;

pub(crate) fn initialize(connection: &Connection) -> rusqlite::Result<()> {
    connection.execute_batch(CREATE_TABLE_SQL)?;
    Ok(())
}
