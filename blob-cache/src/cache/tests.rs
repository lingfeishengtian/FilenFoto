// use std::fs;
// use std::path::Path;
// use std::sync::Arc;
// use tempfile::TempDir;

// use crate::cache::BlobCache;
// use uuid::Uuid;

// #[cfg(test)]
// mod tests {
//     use super::*;
//     use std::thread;

//     #[test]
//     fn test_cache_initialization() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024); // 1MB max

//         // Should initialize with zero size
//         assert_eq!(cache.cache_size(), 0);

//         // Database should be created
//         let db_path = format!("{}/cache.db", cache_path);
//         assert!(Path::new(&db_path).exists());
//     }

//     #[test]
//     fn test_database_sizing() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024);

//         // Test empty database size
//         assert_eq!(cache.cache_size(), 0);

//         // Add a blob and verify exact cache size
//         let key = Uuid::new_v4();
//         let data = vec![b'X'; 100];

//         cache.put(&key, &data, None).unwrap();

//         // Cache size should equal exactly the size of our blob (100 bytes)
//         assert_eq!(cache.cache_size(), 100);
//     }

//     #[test]
//     fn test_file_location_storage() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024);

//         let key = Uuid::new_v4();
//         let data = vec![b'A'; 50];

//         cache.put(&key, &data, None).unwrap();

//         // Check that the file was created in the correct location
//         let file_path = cache.file_storage.blob_file_path(&key);
//         assert!(Path::new(&file_path).exists());

//         // Verify directory structure
//         let prefix = key.to_string()[..2].to_string();
//         assert!(file_path.contains(&format!("/{}/", prefix)));
//     }

//     #[test]
//     fn test_cache_size_synchronization() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024);

//         // Add multiple blobs and verify exact cache size
//         let key1 = Uuid::new_v4();
//         let data1 = vec![b'1'; 100];

//         let key2 = Uuid::new_v4();
//         let data2 = vec![b'2'; 200];

//         cache.put(&key1, &data1, None).unwrap();
//         cache.put(&key2, &data2, None).unwrap();

//         // Cache size should equal exactly the sum of both blob sizes (300 bytes)
//         assert_eq!(cache.cache_size(), 300);
//     }

//     #[test]
//     fn test_blob_retrieval() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024);

//         let key = Uuid::new_v4();
//         let data = vec![b'T'; 75];

//         cache.put(&key, &data, None).unwrap();

//         // Retrieve the file path
//         let file_path = cache.get(&key).unwrap();
//         assert!(file_path.contains(key.to_string().as_str()));

//         // Verify file exists
//         assert!(Path::new(&file_path).exists());
//     }

//     #[test]
//     fn test_blob_deletion() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024);

//         let key = Uuid::new_v4();
//         let data = vec![b'D'; 50];

//         cache.put(&key, &data, None).unwrap();

//         // Verify file exists before deletion
//         let file_path = cache.file_storage.blob_file_path(&key);
//         assert!(Path::new(&file_path).exists());

//         // Delete the blob
//         cache.delete(&key).unwrap();

//         // Verify file is deleted
//         assert!(!Path::new(&file_path).exists());

//         // Cache size should be back to 0 after deletion
//         assert_eq!(cache.cache_size(), 0);
//     }

//     #[test]
//     fn test_concurrent_access() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = Arc::new(BlobCache::new(cache_path.clone(), 1024 * 1024));

//         // Spawn multiple threads that perform cache operations
//         let handles: Vec<_> = (0..5)
//             .map(|i| {
//                 let cache_clone = Arc::clone(&cache);
//                 thread::spawn(move || {
//                     let key = Uuid::new_v4();
//                     let data = vec![i as u8; 25];
//                     cache_clone.put(&key, &data, None).unwrap();
//                 })
//             })
//             .collect();

//         // Wait for all threads to complete
//         for handle in handles {
//             handle.join().unwrap();
//         }

//         // Cache size should equal exactly the sum of all data sizes (125 bytes)
//         assert_eq!(cache.cache_size(), 125); // 5 blobs of 25 bytes each
//     }

//     #[test]
//     fn test_cache_size_limits() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let max_size = 100;
//         let cache = BlobCache::new(cache_path.clone(), max_size);

//         // Add a blob that's under the limit
//         let key1 = Uuid::new_v4();
//         let data1 = vec![b'1'; 50];
//         cache.put(&key1, &data1, None).unwrap();

//         // Add another blob that keeps us under the limit
//         let key2 = Uuid::new_v4();
//         let data2 = vec![b'2'; 30];
//         cache.put(&key2, &data2, None).unwrap();

//         // Cache size should equal exactly the sum of both blob sizes (80 bytes)
//         assert_eq!(cache.cache_size(), 80);
//     }

//     #[test]
//     fn test_put_from_file() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024);

//         // Create a temporary file with test data
//         let test_file = temp_dir.path().join("test_data.txt");
//         fs::write(&test_file, "Hello, World!").unwrap();

//         let key = Uuid::new_v4();
//         cache.put_from_file(&key, test_file.to_str().unwrap());

//         // Verify file was stored
//         let retrieved_path = cache.get(&key).unwrap();
//         assert!(Path::new(&retrieved_path).exists());

//         // Cache size should equal exactly the size of the file (13 bytes)
//         assert_eq!(cache.cache_size(), 13); // Length of "Hello, World!"
//     }

//     #[test]
//     fn test_database_consistency() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024);

//         // Add a few blobs and verify exact cache size
//         let key1 = Uuid::new_v4();
//         let data1 = vec![b'A'; 100];

//         let key2 = Uuid::new_v4();
//         let data2 = vec![b'B'; 150];

//         cache.put(&key1, &data1, None).unwrap();
//         cache.put(&key2, &data2, None).unwrap();

//         // Check that database records exist
//         assert!(cache.db.contains(&key1).unwrap());
//         assert!(cache.db.contains(&key2).unwrap());

//         // Cache size should equal exactly the sum of both blob sizes (250 bytes)
//         assert_eq!(cache.cache_size(), 250);
//     }

//     #[test]
//     fn test_empty_cache_operations() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024);

//         // Test getting non-existent blob
//         let key = Uuid::new_v4();
//         assert!(cache.get(&key).is_none());

//         // Test deleting non-existent blob (should return error)
//         assert!(cache.delete(&key).is_err());

//         // Cache size should remain zero
//         assert_eq!(cache.cache_size(), 0);
//     }

//     #[test]
//     fn test_overriding_existing_keys() {
//         let temp_dir = TempDir::new().unwrap();
//         let cache_path = temp_dir.path().to_str().unwrap().to_string();

//         let cache = BlobCache::new(cache_path.clone(), 1024 * 1024);

//         // Add a blob with key1
//         let key1 = Uuid::new_v4();
//         let data1 = vec![b'A'; 100];
//         cache.put(&key1, &data1, None).unwrap();

//         // Verify cache size is 100 bytes
//         assert_eq!(cache.cache_size(), 100);

//         // Override the same key with a different sized blob (larger)
//         let data2 = vec![b'B'; 150];  // Larger blob
//         cache.put(&key1, &data2, None).unwrap();

//         // Cache size should now be 150 bytes (the size of the new blob)
//         assert_eq!(cache.cache_size(), 150);
//     }
// }
