use boltffi::export;
use std::{io::Read, sync::atomic::AtomicUsize};

use crate::{db::BlobDatabase, error::BlobCacheError, files::FileStorage, types::SimplifiedUuid};

struct BlobCache {
    max_cache_size: usize,
    current_cache_size: AtomicUsize,
    file_storage: FileStorage,
    db: BlobDatabase,
    // TODO: Fields
}

const FILE_BUFFER_SIZE: usize = 1024 * 1024; // 1 MB

#[export]
impl BlobCache {
    pub fn new(root_path: String, max_cache_size: usize) -> Self {
        // TODO: call database calculate cache size from blobs
        let db = BlobDatabase::open(format!("{root_path}/cache.db"))
            .expect("Failed to open blob cache database");
        let current_cache_size = db
            .total_size()
            .expect("Failed to calculate initial cache size from database");

        Self {
            max_cache_size,
            current_cache_size: AtomicUsize::new(current_cache_size),
            file_storage: FileStorage::new(root_path),
            db,
        }
    }

    /// Returns the current size of the cache in bytes. This is the total size of all blobs currently stored in the cache.
    pub fn cache_size(&self) -> usize {
        self.current_cache_size
            .load(std::sync::atomic::Ordering::Relaxed)
    }

    /// Puts a chunk of data into the blob associated with the given key. If `starting_pos` is provided,
    /// the chunk will be put starting from that position in the blob, overwriting existing data. However,
    /// note that if `starting_pos` is larger than the current size of the blob an error will be thrown,
    /// as an accidental value of `starting_pos` could wreak havoc on the filesystem (although technically
    /// APFS supports sparse files, this cache is not intended to be used with sparse files). If `starting_pos`
    /// is not provided, the chunk will be appended to the end of the blob.
    ///
    /// If the key doesn't exist, a new blob will be created with the given key and the chunk will be put into it,
    /// starting from position 0, if `starting_pos` is provided and is not 0, an error will be thrown.
    pub fn put(
        &self,
        key_uuid: &SimplifiedUuid,
        partial_blob: &[u8],
        starting_pos: Option<u64>,
    ) -> Result<(), BlobCacheError> {
        let key = &key_uuid.convert_to_native_uuid();
        // get blob associated with key
        let existing_blob = self.db.get(key)?;

        // If this is a new blob, create it in the database
        if existing_blob.is_none() {
            // Create new blob record with size of partial_blob
            self.db.upsert(*key, partial_blob.len())?;

            // write chunk to filesystem
            self.file_storage
                .write_blob(key, partial_blob, starting_pos)?;

            // update cache size - add the full size of the new blob
            self.current_cache_size
                .fetch_add(partial_blob.len(), std::sync::atomic::Ordering::Relaxed);
        } else {
            let blob = existing_blob.unwrap();

            // get blob information - if starting_pos is provided and is larger than the current size of the blob, throw an error
            if let Some(pos) = starting_pos {
                if pos > blob.size as u64 {
                    return Err(BlobCacheError::InvalidStartingPosition);
                }
            }

            // write chunk to filesystem then commit to db
            self.file_storage
                .write_blob(key, partial_blob, starting_pos)?;

            // When we're overwriting an existing blob (full replacement),
            // we should update the cache size with the difference between new and old sizes
            let new_size = partial_blob.len();

            // Calculate size delta: new_size - old_size (this handles both increases and decreases)
            let size_delta = new_size as isize - blob.size as isize;

            if size_delta != 0 {
                self.current_cache_size.fetch_add(
                    size_delta.unsigned_abs(),
                    std::sync::atomic::Ordering::Relaxed,
                );
            }

            // Update database with new size
            self.db.update_size(&blob.key, new_size)?;
        }

        Ok(())
    }

    /// Retrieves the blob's file path associated with the given key. If no blob exists for the given key, this function returns `None`.
    ///
    /// Note that this function returns the file path of the blob, not the blob's data itself. This is because the blob's data is stored
    /// in a file on disk, and returning the file path allows the caller to read the blob's data directly from the file without having to
    // load it all into memory at once.
    pub fn get(&self, key_uuid: &SimplifiedUuid) -> Option<String> {
        let key = &key_uuid.convert_to_native_uuid();

        self.file_storage.blob_file(key).ok()
    }

    /// Deletes the blob associated with the given key. If no blob exists for the given key, this function returns an error.
    pub fn delete(&self, key_uuid: &SimplifiedUuid) -> Result<(), BlobCacheError> {
        let key = &key_uuid.convert_to_native_uuid();
        // get blob associated with key
        // if blob doesn't exist, return
        let did_delete_blob = self.file_storage.delete_blob(key).is_ok();

        if !did_delete_blob {
            return Err(BlobCacheError::BlobNotFound);
        }

        // delete from db then delete from filesystem
        let db_record = self.db.get(key)?.ok_or(BlobCacheError::BlobNotFound)?;
        self.db.delete(key)?;
        self.current_cache_size
            .fetch_sub(db_record.size, std::sync::atomic::Ordering::Relaxed);

        // update current cache size
        Ok(())
    }

    /// Clears the entire cache, deleting all blobs. Use with caution!
    pub fn clear_all(&self) {}

    pub fn validate(&self) {
        // Iterate all blobs in the cache

        // check if the file exists on disk. If a blob's file is missing, delete the blob from the cache.
        // check if the file size matches the blob's size in the database. If a blob's file size doesn't match the database, delete the blob from the cache.
        // store in a set the keys of all valid blobs that are found during this iteration

        // Iterate all files in the cache directory

        // check if the file has a corresponding blob in the database (check the set). If a file doesn't have a corresponding blob, delete the file from disk.
    }

    /// Functions below are convenience functions

    /// Puts a blob into the cache from a file. This is a convenience function that reads the file in chunks.
    pub fn put_from_file(&self, key: &SimplifiedUuid, file_path: &str) {
        let mut file = std::fs::File::open(file_path).expect("Failed to open file");
        let mut buffer = vec![0; FILE_BUFFER_SIZE];

        let mut starting_pos = 0;
        loop {
            let bytes_read = file.read(&mut buffer).expect("Failed to read file");
            if bytes_read == 0 {
                break; // EOF
            }
            let _ = self.put(key, &buffer[..bytes_read], Some(starting_pos));
            starting_pos += bytes_read as u64;
        }
    }
}

#[cfg(test)]
mod tests;
