use std::io::{Seek, Write};
use std::path::Path;

use uuid::Uuid;

use crate::error::BlobCacheError;

pub struct FileStorage {
    root_path: String,
}

impl FileStorage {
    pub fn new(root_path: String) -> Self {
        FileStorage { root_path }
    }

    pub fn write_blob(
        &self,
        key: &Uuid,
        data: &[u8],
        starting_pos: Option<u64>,
    ) -> Result<(), BlobCacheError> {
        let file_path = self.blob_file_path(key);
        if let Some(parent) = Path::new(&file_path).parent() {
            std::fs::create_dir_all(parent)?;
        }

        let mut file = std::fs::OpenOptions::new()
            .create(true)
            .write(true)
            .open(file_path)?;

        let current_file_size = file.metadata()?.len();

        if let Some(pos) = starting_pos {
            if pos > current_file_size {
                return Err(BlobCacheError::InvalidStartingPosition);
            }

            file.seek(std::io::SeekFrom::Start(pos))?;
        } else {
            file.seek(std::io::SeekFrom::Start(0))?;
        }

        file.write_all(data)?;

        Ok(())
    }

    pub fn blob_file(&self, key: &Uuid) -> Result<String, BlobCacheError> {
        let file_path = self.blob_file_path(key);

        if !std::fs::metadata(&file_path).map_or(false, |m| m.is_file()) {
            return Err(BlobCacheError::BlobNotFound);
        }

        Ok(file_path)
    }

    pub fn delete_blob(&self, key: &Uuid) -> Result<(), BlobCacheError> {
        let file_path = self.blob_file_path(key);

        std::fs::remove_file(file_path)?;

        Ok(())
    }

    /// Utility Functions

    pub fn blob_file_path(&self, key: &Uuid) -> String {
        let prefix = key.to_string()[..2].to_string();

        format!("{}/{}/{}", self.root_path, prefix, key.to_string())
    }
}

#[cfg(test)]
mod tests;
