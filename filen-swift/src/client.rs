pub use crate::with_client;
use filen_types::fs::UuidStr;
use std::{str::FromStr, sync::Arc};
use tokio_util::compat::{TokioAsyncReadCompatExt, TokioAsyncWriteCompatExt};

use crate::types::{Directory, DirectoryAsHasContents, RemoteFile};
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

    #[error("IO Error: {msg}")]
    IoError { msg: String },
}

#[derive(uniffi::Record)]
pub struct ListDir {
    pub directories: Vec<Directory>,
    pub files: Vec<RemoteFile>,
}

#[uniffi::export]
impl FilenClient {
    pub fn root_uuid(&self) -> String {
        self.client.root().uuid().to_string()
    }

    pub async fn dirs_in_dir(&self, dir_uuid: String) -> Result<ListDir, FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            let dir = DirectoryAsHasContents {
                uuid: UuidStr::from_str(&dir_uuid)?,
            };
            let result = client.list_dir(&dir).await?;

            Ok(ListDir {
                directories: result
                    .0
                    .iter()
                    .map(Directory::from_remote_dir)
                    .collect::<Result<Vec<_>, _>>()?,
                files: result
                    .1
                    .iter()
                    .map(RemoteFile::from_remote_file)
                    .collect::<Result<Vec<_>, _>>()?,
            })
        })?
    }

    pub async fn create_dir_in_dir(
        &self,
        parent_uuid: String,
        name: String,
    ) -> Result<Directory, FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            let dir = DirectoryAsHasContents {
                uuid: UuidStr::from_str(&parent_uuid)?,
            };
            let result = client.create_dir(&dir, name).await?;
            Ok(Directory::from_remote_dir(&result)?)
        })?
    }

    pub async fn download_file_to_path(
        &self,
        file_uuid: String,
        path: String,
    ) -> Result<(), FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            let file = client.get_file(UuidStr::from_str(&file_uuid)?).await?;
            let mut async_writer = tokio::fs::File::create(path).await?.compat_write();

            client
                .download_file_to_writer(&file, &mut async_writer, None)
                .await?;
            Ok(())
        })?
    }

    pub async fn upload_file_from_path(
        &self,
        dir_uuid: String,
        file_path: String,
        file_name: String,
    ) -> Result<RemoteFile, FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            let dir = DirectoryAsHasContents {
                uuid: UuidStr::from_str(&dir_uuid)?,
            };
            let file_builder = client.make_file_builder(file_name, &dir);
            let base_file = Arc::new(file_builder.build());
            let mut async_reader = tokio::fs::File::open(file_path).await?.compat();

            let uploaded_file = &client
                .upload_file_from_reader(base_file, &mut async_reader, None, None)
                .await?;
            Ok(RemoteFile::from_remote_file(uploaded_file)?)
        })?
    }
}
