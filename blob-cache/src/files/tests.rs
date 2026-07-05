use std::fs;
use std::path::Path;
use tempfile::TempDir;

use uuid::Uuid;

use crate::files::FileStorage;

#[test]
fn test_file_storage_creation() {
    let temp_dir = TempDir::new().unwrap();
    let root_path = temp_dir.path().to_str().unwrap().to_string();

    let file_storage = FileStorage::new(root_path.clone());

    assert_eq!(file_storage.root_path, root_path);
}

#[test]
fn test_write_blob() {
    let temp_dir = TempDir::new().unwrap();
    let root_path = temp_dir.path().to_str().unwrap().to_string();
    let file_storage = FileStorage::new(root_path.clone());

    let key = Uuid::new_v4();
    let data = b"Hello, world!";

    let result = file_storage.write_blob(&key, data, None);
    assert!(result.is_ok());

    // Verify the file was created and contains correct data
    let file_path = file_storage.blob_file_path(&key);
    let written_data = fs::read_to_string(&file_path).unwrap();
    assert_eq!(written_data, String::from_utf8_lossy(data));
}

#[test]
fn test_blob_file_exists() {
    let temp_dir = TempDir::new().unwrap();
    let root_path = temp_dir.path().to_str().unwrap().to_string();
    let file_storage = FileStorage::new(root_path.clone());

    let key = Uuid::new_v4();
    let data = b"Test data";

    // Write the blob first
    let result = file_storage.write_blob(&key, data, None);
    print!("{:?}", result);
    assert!(result.is_ok());

    // Check if file exists
    let file_path_result = file_storage.blob_file(&key);
    assert!(file_path_result.is_ok());

    let file_path = file_path_result.unwrap();
    assert!(Path::new(&file_path).exists());
}

#[test]
fn test_blob_file_not_exists() {
    let temp_dir = TempDir::new().unwrap();
    let root_path = temp_dir.path().to_str().unwrap().to_string();
    let file_storage = FileStorage::new(root_path.clone());

    let key = Uuid::new_v4();

    // Try to get a non-existent file
    let file_path_result = file_storage.blob_file(&key);
    assert!(file_path_result.is_err());
}

#[test]
fn test_delete_blob() {
    let temp_dir = TempDir::new().unwrap();
    let root_path = temp_dir.path().to_str().unwrap().to_string();
    let file_storage = FileStorage::new(root_path.clone());

    let key = Uuid::new_v4();
    let data = b"Delete test";

    // Write the blob first
    let result = file_storage.write_blob(&key, data, None);
    assert!(result.is_ok());

    // Verify it exists
    let file_path_result = file_storage.blob_file(&key);
    assert!(file_path_result.is_ok());

    // Delete the blob
    let delete_result = file_storage.delete_blob(&key);
    assert!(delete_result.is_ok());

    // Verify it no longer exists
    let file_path_result = file_storage.blob_file(&key);
    assert!(file_path_result.is_err());
}

#[test]
fn test_write_blob_with_starting_position() {
    let temp_dir = TempDir::new().unwrap();
    let root_path = temp_dir.path().to_str().unwrap().to_string();
    let file_storage = FileStorage::new(root_path.clone());

    let key = Uuid::new_v4();
    let data1 = b"Hello";
    let data2 = b"World";

    // Write first part
    let result = file_storage.write_blob(&key, data1, None);
    assert!(result.is_ok());

    // Write second part at the end
    let result = file_storage.write_blob(&key, data2, Some(data1.len() as u64));
    assert!(result.is_ok());

    // Verify combined content
    let file_path = file_storage.blob_file_path(&key);
    let written_data = fs::read_to_string(&file_path).unwrap();
    assert_eq!(written_data, "HelloWorld");
}

#[test]
fn test_write_blob_overwrite() {
    let temp_dir = TempDir::new().unwrap();
    let root_path = temp_dir.path().to_str().unwrap().to_string();
    let file_storage = FileStorage::new(root_path.clone());

    let key = Uuid::new_v4();
    let data1 = b"First content";
    let data2 = b"Second content";

    // Write first content
    let result = file_storage.write_blob(&key, data1, None);
    assert!(result.is_ok());

    // Write second content (should overwrite)
    let result = file_storage.write_blob(&key, data2, None);
    assert!(result.is_ok());

    // Verify that the file contains only the second content
    let file_path = file_storage.blob_file_path(&key);
    let written_data = fs::read_to_string(&file_path).unwrap();
    assert_eq!(written_data, String::from_utf8_lossy(data2));
}

#[test]
fn test_blob_file_path() {
    let temp_dir = TempDir::new().unwrap();
    let root_path = temp_dir.path().to_str().unwrap().to_string();
    let file_storage = FileStorage::new(root_path.clone());

    let key = Uuid::parse_str("550e8400-e29b-41d4-a716-446655440000").unwrap();
    let expected_path = format!("{}/55/550e8400-e29b-41d4-a716-446655440000", root_path);

    let actual_path = file_storage.blob_file_path(&key);
    assert_eq!(actual_path, expected_path);
}
