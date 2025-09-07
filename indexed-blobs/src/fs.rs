use std::path::PathBuf;

use crate::{blob_provider::BlobProvider, err_type::BlobProviderError};

impl BlobProvider {
    pub fn get_num_chunks(
        root_blob_dir: PathBuf,
        blob_file_prefix: &str,
    ) -> Result<usize, BlobProviderError> {
        let mut num_chunks = 0;

        for file in std::fs::read_dir(root_blob_dir)? {
            let file_path = file?.path();
            let file_name = file_path
                .file_name()
                .unwrap_or_default()
                .to_str()
                .unwrap_or_default();

            if !file_path.is_file() {
                return Err(BlobProviderError::InvalidBlobFile(file_name.to_owned()));
            }

            if !file_name.starts_with(blob_file_prefix) {
                return Err(BlobProviderError::InvalidBlobFile(file_name.to_owned()));
            }

            num_chunks += 1;
        }

        if num_chunks % 2 != 0 {
            return Err(BlobProviderError::UnevenBlobChunks);
        }

        Ok(num_chunks / 2)
    }
}
