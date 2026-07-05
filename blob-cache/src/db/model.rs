use uuid::Uuid;

/// A single blob metadata record stored in SQLite.
///
/// The cache stores blob bytes on disk, while SQLite keeps the durable metadata
/// needed to find those blobs and account for their size.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BlobRecord {
    /// The stable UUID that identifies the blob.
    pub key: Uuid,
    /// The number of bytes currently tracked for the blob.
    pub size: usize,
}

impl BlobRecord {
    /// Creates a new blob metadata record.
    pub fn new(key: Uuid, size: usize) -> Self {
        Self { key, size }
    }
}
