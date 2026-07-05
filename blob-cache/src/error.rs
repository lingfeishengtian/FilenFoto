use boltffi::error;

#[error]
#[derive(Debug, Clone)]
pub enum BlobCacheError {
    InvalidStartingPosition,
    BlobNotFound,
    IoError(String),
    DatabaseError(String),
}

impl From<std::io::Error> for BlobCacheError {
    fn from(error: std::io::Error) -> Self {
        BlobCacheError::IoError(error.to_string())
    }
}

impl From<rusqlite::Error> for BlobCacheError {
    fn from(error: rusqlite::Error) -> Self {
        BlobCacheError::DatabaseError(error.to_string())
    }
}
