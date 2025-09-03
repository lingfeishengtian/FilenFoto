use filen_types::fs::UuidStr;
use std::{str::FromStr, sync::Arc};
use tokio::runtime::Builder;

use crate::types::Directory;
use filen_sdk_rs::{
    auth::StringifiedClient,
    fs::{dir::{HasContents, HasUUIDContents}, HasUUID},
};

#[derive(uniffi::Object)]
pub struct FilenClient {
    pub(crate) tokio_runtime: tokio::runtime::Runtime,
    pub(crate) client: Arc<filen_sdk_rs::auth::Client>,
}

#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum FilenClientError {
    #[error("Login failed: {msg}")]
    LoginError { msg: String },

    #[error("Runtime error: {msg}")]
    RuntimeError { msg: String },

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
        let root_id = self.root_uuid();

        self.tokio_runtime
            .handle()
            .spawn(async move {
                let dir: &dyn HasContents = if dir_uuid == root_id {
                    client.root()
                } else {
                    let uuid = UuidStr::from_str(&dir_uuid).map_err(|_| {
                        FilenClientError::RuntimeError {
                            msg: "Invalid UUID format".into(),
                        }
                    })?;

                    &client
                        .get_dir(uuid)
                        .await
                        .map_err(|error| FilenClientError::RuntimeError {
                            msg: format!("Failed to get directory: {}", error),
                        })?
                };

                let result =
                    client
                        .list_dir(dir)
                        .await
                        .map_err(|error| FilenClientError::RuntimeError {
                            msg: format!("Failed to list directory: {}", error),
                        })?;

                Ok(result
                    .0
                    .iter()
                    .map(Directory::from_remote_dir)
                    .collect::<Result<Vec<_>, _>>()?)
            })
            .await
            .map_err(|e| FilenClientError::RuntimeError {
                msg: format!("Failed to list directory: {}", e),
            })?
    }

    pub async fn create_dir_in_dir(
        &self,
        parent_uuid: String,
        name: String,
    ) -> Result<Directory, FilenClientError> {
        let client = self.client.clone();
        let root_id = self.root_uuid();

        self.tokio_runtime
            .handle()
            .spawn(async move {
                let dir: &dyn HasUUIDContents = if parent_uuid == root_id {
                    client.root()
                } else {
                    let uuid = UuidStr::from_str(&parent_uuid).map_err(|_| {
                        FilenClientError::RuntimeError {
                            msg: "Invalid UUID format".into(),
                        }
                    })?;

                    &client
                        .get_dir(uuid)
                        .await
                        .map_err(|error| FilenClientError::RuntimeError {
                            msg: format!("Failed to get directory: {}", error),
                        })?
                };

                let result = client.create_dir(dir, name).await.map_err(|error| {
                    FilenClientError::RuntimeError {
                        msg: format!("Failed to create directory: {}", error),
                    }
                })?;

                Ok(Directory::from_remote_dir(&result).map_err(|e| {
                    FilenClientError::RuntimeError {
                        msg: format!("Failed to convert directory: {}", e),
                    }
                })?)
            })
            .await
            .map_err(|e| FilenClientError::RuntimeError {
                msg: format!("Failed to create directory: {}", e),
            })?
    }
}
