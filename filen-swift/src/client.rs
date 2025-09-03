pub use crate::with_client;
use filen_types::fs::UuidStr;
use std::{str::FromStr, sync::Arc};

use crate::types::{Directory, DirectoryAsHasContents};
use filen_sdk_rs::fs::HasUUID;

#[derive(uniffi::Object)]
pub struct FilenClient {
    pub(crate) tokio_runtime: tokio::runtime::Runtime,
    pub(crate) client: Arc<filen_sdk_rs::auth::Client>,
}

#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum FilenClientError {
    #[error("Concurrency Error: {msg}")]
    ConcurrencyError { msg: String },

    #[error("Filen client error: {msg}")]
    FilenClientError { msg: String },

    #[error("Type conversion error: {msg}")]
    TypeConversionError { msg: String },
}


#[uniffi::export]
impl FilenClient {
    pub fn root_uuid(&self) -> String {
        self.client.root().uuid().to_string()
    }

    pub async fn dirs_in_dir(&self, dir_uuid: String) -> Result<Vec<Directory>, FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            let dir = DirectoryAsHasContents { uuid: UuidStr::from_str(&dir_uuid)? };
            let result = client.list_dir(&dir).await?;
            Ok(result
                .0
                .iter()
                .map(Directory::from_remote_dir)
                .collect::<Result<Vec<_>, _>>()?)
        })?
    }

    pub async fn create_dir_in_dir(
        &self,
        parent_uuid: String,
        name: String,
    ) -> Result<Directory, FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            let dir = DirectoryAsHasContents { uuid: UuidStr::from_str(&parent_uuid)? };
            let result = client.create_dir(&dir, name).await?;
            Ok(Directory::from_remote_dir(&result)?)
        })?
    }
}
