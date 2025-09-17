use filen_sdk_rs::fs::{
    HasName, HasUUID,
    dir::{HasContents, RemoteDirectory},
    file::traits::HasFileInfo,
};
use filen_types::fs::UuidStr;

use crate::client::FilenClientError;

#[derive(uniffi::Record)]
pub struct Directory {
    uuid: String,
    name: String,

    parent_uuid: String,
    favorited: bool,
    color: Option<String>,

    created_at: Option<u64>,
}

impl Directory {
    pub fn from_remote_dir(remote_dir: &RemoteDirectory) -> Result<Self, FilenClientError> {
        let meta_decrypted = match &remote_dir.meta {
            filen_sdk_rs::fs::dir::meta::DirectoryMeta::Decoded(meta) => meta,
            _ => {
                return Err(FilenClientError::TypeConversionError {
                    msg: "Directory meta is not decrypted".into(),
                });
            }
        };

        Ok(Directory {
            uuid: remote_dir.uuid.to_string(),
            name: meta_decrypted.name().to_string(),
            parent_uuid: remote_dir.parent.to_string(),
            favorited: remote_dir.favorited,
            color: remote_dir.color.clone(),
            created_at: meta_decrypted.created().map(|t| t.timestamp() as u64),
        })
    }
}

#[derive(uniffi::Record)]
pub struct RemoteFile {
    pub uuid: String,

    // From DecryptedFileMeta
    pub name: String,
    pub mime: String,
    pub last_modified: u64,
    pub created: u64,

    pub parent: String,
    pub size: u64,
    pub favorited: bool,
    pub region: String,
    pub bucket: String,
    pub chunks: u64,
}

impl RemoteFile {
    pub fn from_remote_file(
        remote_file: &filen_sdk_rs::fs::file::RemoteFile,
    ) -> Result<Self, FilenClientError> {
        Ok(RemoteFile {
            uuid: remote_file.uuid.to_string(),
            name: remote_file.name().unwrap_or_default().to_string(),
            mime: remote_file.mime().unwrap_or_default().to_string(),
            last_modified: remote_file.last_modified().unwrap_or_default().timestamp() as u64,
            created: remote_file.created().unwrap_or_default().timestamp() as u64,
            parent: remote_file.parent.to_string(),
            size: remote_file.size,
            favorited: remote_file.favorited,
            region: remote_file.region.to_string(),
            bucket: remote_file.bucket.to_string(),
            chunks: remote_file.chunks,
        })
    }
}

impl From<filen_sdk_rs::error::Error> for FilenClientError {
    fn from(err: filen_sdk_rs::error::Error) -> Self {
        FilenClientError::FilenClientError {
            msg: format!("{}", err),
        }
    }
}

impl From<uuid::Error> for FilenClientError {
    fn from(err: uuid::Error) -> Self {
        FilenClientError::TypeConversionError {
            msg: format!("UUID conversion error: {}", err),
        }
    }
}

impl From<std::io::Error> for FilenClientError {
    fn from(err: std::io::Error) -> Self {
        FilenClientError::IoError {
            msg: format!("IO error: {}", err),
        }
    }
}

pub struct DirectoryAsHasContents {
    pub uuid: UuidStr,
}

impl HasContents for DirectoryAsHasContents {
    fn uuid_as_parent(&self) -> filen_types::fs::ParentUuid {
        filen_types::fs::ParentUuid::from(self.uuid)
    }
}

impl HasUUID for DirectoryAsHasContents {
    fn uuid(&self) -> &UuidStr {
        &self.uuid
    }
}
