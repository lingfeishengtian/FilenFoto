pub(crate) const COUNT_RECORDS_SQL: &str = "SELECT COUNT(*) FROM blobs";
pub(crate) const TOTAL_SIZE_SQL: &str = "SELECT COALESCE(SUM(size), 0) FROM blobs";
pub(crate) const SELECT_BY_KEY_SQL: &str = "SELECT key, size FROM blobs WHERE key = ?1";
pub(crate) const UPSERT_SQL: &str = r#"
		INSERT INTO blobs (key, size)
		VALUES (?1, ?2)
		ON CONFLICT(key) DO UPDATE SET
			size = excluded.size
	"#;
pub(crate) const UPDATE_SIZE_SQL: &str = "UPDATE blobs SET size = ?2 WHERE key = ?1";
pub(crate) const DELETE_BY_KEY_SQL: &str = "DELETE FROM blobs WHERE key = ?1";
pub(crate) const CLEAR_SQL: &str = "DELETE FROM blobs";
pub(crate) const SELECT_KEYS_SQL: &str = "SELECT key FROM blobs ORDER BY key";
pub(crate) const SELECT_RECORDS_SQL: &str = "SELECT key, size FROM blobs ORDER BY key";
