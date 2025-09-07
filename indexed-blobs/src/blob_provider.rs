use core::num;
use std::{
    iter::Map,
    path::{Path, PathBuf},
};

use crate::err_type::BlobProviderError;

#[derive(uniffi::Object)]
pub struct BlobProvider {
    pub(crate) root_blob_dir: PathBuf,
    pub(crate) blob_file_prefix: String,
    pub(crate) num_chunks: usize,
    pub(crate) midx: crate::data_structures::mmap_midx::MIdx,
    pub(crate) idx_fd_pool: crate::data_structures::fd_pool::FdPool,
    pub(crate) dat_fd_pool: crate::data_structures::fd_pool::FdPool,
}

#[uniffi::export]
pub fn new_blob_provider(path: String, prefix: String) -> Result<BlobProvider, BlobProviderError> {
    let root_blob_dir = Path::new(&path);

    if path.is_empty() || !root_blob_dir.exists() || !root_blob_dir.is_dir() {
        return Err(BlobProviderError::InvalidPath);
    }

    if prefix.is_empty() {
        return Err(BlobProviderError::InvalidPrefix);
    }

    let num_chunks = BlobProvider::get_num_chunks(root_blob_dir.to_path_buf(), &prefix)?;
    let midx_name = format!("{}.midx", prefix);

    Ok(BlobProvider {
        root_blob_dir: root_blob_dir.to_path_buf(),
        blob_file_prefix: prefix,
        num_chunks,
        midx: crate::data_structures::mmap_midx::open_or_create_midx(
            &root_blob_dir.join(midx_name),
        )?,
        idx_fd_pool: crate::data_structures::fd_pool::FdPool::new(),
        dat_fd_pool: crate::data_structures::fd_pool::FdPool::new(),
    })
}

#[uniffi::export]
impl BlobProvider {}
