use std::sync::PoisonError;

#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum BlobProviderError {
    #[error("Invalid blob directory path")]
    InvalidPath,

    #[error("Invalid blob file prefix")]
    InvalidPrefix,

    #[error("I/O error {0}")]
    IoError(String),

    #[error("Invalid blob file with name {0}")]
    InvalidBlobFile(String),

    #[error("Uneven number of blob chunks")]
    UnevenBlobChunks,

    #[error("Internal Error: Invalid chunk index {0}")]
    InvalidChunkIndex(u64),

    #[error("Concurrency Error: {0}")]
    ConcurrencyError(String),

    #[error("File descriptor already exists: {0}")]
    FileDescriptorAlreadyExists(u64),

    #[error("Invalid MIdx File")]
    InvalidMIdx,
}

impl From<std::io::Error> for BlobProviderError {
    fn from(err: std::io::Error) -> Self {
        BlobProviderError::IoError(err.to_string())
    }
}

impl<T> From<PoisonError<T>> for BlobProviderError {
    fn from(err: PoisonError<T>) -> Self {
        BlobProviderError::ConcurrencyError(err.to_string())
    }
}
