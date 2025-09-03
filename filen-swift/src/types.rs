use filen_sdk_rs::fs::{dir::{HasContents, RemoteDirectory}, HasUUID};
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
            filen_sdk_rs::fs::dir::meta::DirectoryMeta::Decoded(meta)=> meta,
            _ => return Err(FilenClientError::TypeConversionError {
                msg: "Directory meta is not decrypted".into(),
            }),
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