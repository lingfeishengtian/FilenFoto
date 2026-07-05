use super::*;
use std::fs;
use std::path::PathBuf;

/// Create a temporary test database path that gets cleaned up automatically.
fn temp_db_path() -> (PathBuf, impl Drop) {
    let temp_dir = std::env::temp_dir().join(format!("blob-cache-test-{}", Uuid::new_v4()));
    let db_path = temp_dir.join("test.db");

    struct Cleanup(PathBuf);
    impl Drop for Cleanup {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.0);
        }
    }

    (db_path, Cleanup(temp_dir))
}

#[test]
fn test_open_creates_database() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    // The database file should exist after opening
    assert!(db_path.exists(), "Database file should exist");
}

#[test]
fn test_empty_database_has_zero_records() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let len = db.len().expect("Failed to get database length");
    assert_eq!(len, 0, "Empty database should have 0 records");
}

#[test]
fn test_empty_database_has_zero_size() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let total_size = db.total_size().expect("Failed to get total size");
    assert_eq!(total_size, 0, "Empty database should have 0 total size");
}

#[test]
fn test_upsert_and_get() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let key = Uuid::new_v4();
    let size = 1024;

    // Insert a record
    let record = db.upsert(key, size).expect("Failed to upsert record");
    assert_eq!(record.key, key);
    assert_eq!(record.size, size);

    // Retrieve the record
    let retrieved = db
        .get(&key)
        .expect("Failed to get record")
        .expect("Record should exist");
    assert_eq!(retrieved.key, key);
    assert_eq!(retrieved.size, size);
}

#[test]
fn test_get_nonexistent_returns_none() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let nonexistent_key = Uuid::new_v4();
    let result = db.get(&nonexistent_key).expect("Failed to query database");
    assert!(result.is_none(), "Should return None for nonexistent key");
}

#[test]
fn test_contains() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let key = Uuid::new_v4();
    let other_key = Uuid::new_v4();

    db.upsert(key, 512).expect("Failed to upsert");

    let contains = db.contains(&key).expect("Failed to check contains");
    assert!(contains, "Should contain the inserted key");

    let contains_other = db.contains(&other_key).expect("Failed to check contains");
    assert!(!contains_other, "Should not contain other key");
}

#[test]
fn test_upsert_updates_existing() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let key = Uuid::new_v4();

    // Insert with size 100
    db.upsert(key, 100).expect("Failed to upsert");
    let record1 = db
        .get(&key)
        .expect("Failed to get")
        .expect("Record should exist");
    assert_eq!(record1.size, 100);

    // Upsert with size 200 (should update)
    db.upsert(key, 200).expect("Failed to upsert");
    let record2 = db
        .get(&key)
        .expect("Failed to get")
        .expect("Record should exist");
    assert_eq!(record2.size, 200, "Size should be updated");

    // Database should still have only 1 record
    let len = db.len().expect("Failed to get length");
    assert_eq!(len, 1, "Should have only 1 record after update");
}

#[test]
fn test_update_size() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let key = Uuid::new_v4();
    db.upsert(key, 100).expect("Failed to upsert");

    // Update size
    let updated = db
        .update_size(&key, 500)
        .expect("Failed to update")
        .expect("Should return record");
    assert_eq!(updated.size, 500);

    // Verify the update
    let record = db
        .get(&key)
        .expect("Failed to get")
        .expect("Record should exist");
    assert_eq!(record.size, 500);
}

#[test]
fn test_update_size_nonexistent_returns_none() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let nonexistent_key = Uuid::new_v4();
    let result = db
        .update_size(&nonexistent_key, 100)
        .expect("Failed to update");
    assert!(result.is_none(), "Should return None for nonexistent key");
}

#[test]
fn test_delete() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let key = Uuid::new_v4();
    db.upsert(key, 100).expect("Failed to upsert");

    // Verify it exists
    let len_before = db.len().expect("Failed to get length");
    assert_eq!(len_before, 1);

    // Delete it
    let deleted = db.delete(&key).expect("Failed to delete");
    assert!(deleted, "Should return true when record is deleted");

    // Verify it's gone
    let len_after = db.len().expect("Failed to get length");
    assert_eq!(len_after, 0);

    let result = db.get(&key).expect("Failed to get");
    assert!(result.is_none(), "Record should not exist after deletion");
}

#[test]
fn test_delete_nonexistent_returns_false() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let nonexistent_key = Uuid::new_v4();
    let deleted = db.delete(&nonexistent_key).expect("Failed to delete");
    assert!(!deleted, "Should return false when key doesn't exist");
}

#[test]
fn test_total_size_accumulates() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let key1 = Uuid::new_v4();
    let key2 = Uuid::new_v4();
    let key3 = Uuid::new_v4();

    db.upsert(key1, 100).expect("Failed to upsert");
    db.upsert(key2, 200).expect("Failed to upsert");
    db.upsert(key3, 300).expect("Failed to upsert");

    let total = db.total_size().expect("Failed to get total size");
    assert_eq!(total, 600, "Total size should be sum of all blob sizes");
}

#[test]
fn test_clear_removes_all_records() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let key1 = Uuid::new_v4();
    let key2 = Uuid::new_v4();

    db.upsert(key1, 100).expect("Failed to upsert");
    db.upsert(key2, 200).expect("Failed to upsert");

    let len_before = db.len().expect("Failed to get length");
    assert_eq!(len_before, 2);

    db.clear().expect("Failed to clear");

    let len_after = db.len().expect("Failed to get length");
    assert_eq!(len_after, 0, "Database should be empty after clear");

    let total = db.total_size().expect("Failed to get total size");
    assert_eq!(total, 0, "Total size should be 0 after clear");
}

#[test]
fn test_keys_returns_all_keys() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let key1 = Uuid::new_v4();
    let key2 = Uuid::new_v4();
    let key3 = Uuid::new_v4();

    db.upsert(key1, 100).expect("Failed to upsert");
    db.upsert(key2, 200).expect("Failed to upsert");
    db.upsert(key3, 300).expect("Failed to upsert");

    let keys = db.keys().expect("Failed to get keys");
    assert_eq!(keys.len(), 3, "Should have 3 keys");
    assert!(keys.contains(&key1));
    assert!(keys.contains(&key2));
    assert!(keys.contains(&key3));
}

#[test]
fn test_records_returns_all_records() {
    let (db_path, _cleanup) = temp_db_path();
    let db = BlobDatabase::open(&db_path).expect("Failed to open database");

    let key1 = Uuid::new_v4();
    let key2 = Uuid::new_v4();

    db.upsert(key1, 100).expect("Failed to upsert");
    db.upsert(key2, 200).expect("Failed to upsert");

    let records = db.records().expect("Failed to get records");
    assert_eq!(records.len(), 2, "Should have 2 records");

    let record1 = records
        .iter()
        .find(|r| r.key == key1)
        .expect("Should find key1");
    assert_eq!(record1.size, 100);

    let record2 = records
        .iter()
        .find(|r| r.key == key2)
        .expect("Should find key2");
    assert_eq!(record2.size, 200);
}

#[test]
fn test_multiple_databases_are_independent() {
    let (db_path1, _cleanup1) = temp_db_path();
    let (db_path2, _cleanup2) = temp_db_path();

    let db1 = BlobDatabase::open(&db_path1).expect("Failed to open db1");
    let db2 = BlobDatabase::open(&db_path2).expect("Failed to open db2");

    let key = Uuid::new_v4();

    db1.upsert(key, 100).expect("Failed to upsert in db1");

    // db2 should not have the record
    let result = db2.get(&key).expect("Failed to query db2");
    assert!(result.is_none(), "db2 should not have the record from db1");

    let len1 = db1.len().expect("Failed to get length");
    let len2 = db2.len().expect("Failed to get length");
    assert_eq!(len1, 1);
    assert_eq!(len2, 0, "Databases should be independent");
}

#[test]
fn test_reopen_database_persists_data() {
    let (db_path, _cleanup) = temp_db_path();
    let key = Uuid::new_v4();

    // First session: insert data
    {
        let db = BlobDatabase::open(&db_path).expect("Failed to open database");
        db.upsert(key, 999).expect("Failed to upsert");
    }

    // Second session: data should persist
    {
        let db = BlobDatabase::open(&db_path).expect("Failed to open database");
        let record = db
            .get(&key)
            .expect("Failed to query")
            .expect("Record should exist");
        assert_eq!(record.size, 999, "Data should persist across sessions");
    }
}
