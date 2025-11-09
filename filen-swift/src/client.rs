pub use crate::with_client;
use dashmap::{DashMap, DashSet};
use filen_types::fs::{ParentUuid, UuidStr};
use std::{str::FromStr, sync::Arc};
use tokio_util::{
    compat::{TokioAsyncReadCompatExt, TokioAsyncWriteCompatExt},
    sync::CancellationToken,
};

use crate::types::{Directory, DirectoryAsHasContents, RemoteFile};
use filen_sdk_rs::fs::{HasUUID, dir::RemoteDirectory};

#[derive(uniffi::Object)]
pub struct FilenClient {
    pub(crate) tokio_runtime: tokio::runtime::Runtime,
    pub(crate) client: Arc<filen_sdk_rs::auth::Client>,
    // pub(crate) files_paths_in_progress: DashSet<String>,
    pub(crate) downloads_to_cancellation_tokens: DashMap<String, CancellationToken>,
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

    pub async fn list_dir(&self, dir_uuid: String) -> Result<ListDir, FilenClientError> {
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

    pub async fn cancellable_download_file_to_path(
        &self,
        file_uuid: String,
        path: String,
    ) -> Result<(), FilenClientError> {
        let client = self.client.clone();

        let cancellation_token = CancellationToken::new();
        let cloned_uuid = file_uuid.clone();
        self.downloads_to_cancellation_tokens
            .insert(cloned_uuid.clone(), cancellation_token.clone());

        let path_for_removal = path.clone();
        let res = with_client!(self, {
            let file = client.get_file(UuidStr::from_str(&file_uuid)?).await?;

            let mut async_writer = tokio::fs::File::create(path).await?.compat_write();

            tokio::select! {
                biased;

                _ = cancellation_token.cancelled() => {
                    drop(async_writer);
                    let _ = tokio::fs::remove_file(&path_for_removal).await;
                    return Err(FilenClientError::ConcurrencyError { msg: "Download cancelled".to_string() });
                }
                res = client.download_file_to_writer(&file, &mut async_writer, None) => {
                    res?
                }
            }

            Ok(())
        })?;

        self.downloads_to_cancellation_tokens.remove(&cloned_uuid);
        res
    }

    pub fn cancel_download(&self, uuid: String) {
        if let Some((_, token)) = self.downloads_to_cancellation_tokens.remove(&uuid) {
            token.cancel();
        }
    }

    pub fn cancel_all_downloads(&self) {
        for entry in self.downloads_to_cancellation_tokens.iter() {
            entry.value().cancel();
        }
        self.downloads_to_cancellation_tokens.clear();
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

    pub async fn delete_dir(&self, dir_uuid: String) -> Result<(), FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            // The sdk limits us for some reason to only delete directories retrieved from the sdk and doesn't have a function to delete by uuid, so we trick it :3
            let remote_dir = RemoteDirectory {
                uuid: UuidStr::from_str(&dir_uuid)?,
                meta: filen_sdk_rs::fs::dir::meta::DirectoryMeta::DecryptedRaw(
                    std::borrow::Cow::Borrowed(&[]),
                ),
                parent: ParentUuid::Uuid(*client.root().uuid()),
                favorited: false,
                color: None,
            };

            client.delete_dir_permanently(remote_dir).await?;
            Ok(())
        })?
    }

    pub async fn delete_file(&self, file_uuid: String) -> Result<(), FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            // The sdk limits us for some reason to only delete files retrieved from the sdk and doesn't have a function to delete by uuid, so we trick it :3
            let remote_file = filen_sdk_rs::fs::file::RemoteFile {
                uuid: UuidStr::from_str(&file_uuid)?,
                meta: filen_sdk_rs::fs::file::meta::FileMeta::DecryptedRaw(
                    std::borrow::Cow::Borrowed(&[]),
                ),
                parent: ParentUuid::Uuid(*client.root().uuid()),
                size: 0,
                favorited: false,
                region: "".to_string(),
                bucket: "".to_string(),
                chunks: 0,
            };

            client.delete_file_permanently(remote_file).await?;
            Ok(())
        })?
    }

    pub async fn get_dir_info(&self, dir_uuid: String) -> Result<Directory, FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            let dir = client.get_dir(UuidStr::from_str(&dir_uuid)?).await?;
            Ok(Directory::from_remote_dir(&dir)?)
        })?
    }

    pub async fn get_file_info(&self, file_uuid: String) -> Result<RemoteFile, FilenClientError> {
        let client = self.client.clone();

        with_client!(self, {
            let file = client.get_file(UuidStr::from_str(&file_uuid)?).await?;
            Ok(RemoteFile::from_remote_file(&file)?)
        })?
    }
}
