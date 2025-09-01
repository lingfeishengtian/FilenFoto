use filen_sdk_rs::fs::dir::{DecryptedDirectoryMeta, RemoteDirectory};

use crate::client::FilenClientError;

#[derive(uniffi::Record)]
pub struct Directory {
    uuid: String,
    name: String,

    parent_uuid: String,
    favorited: bool,

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
            created_at: meta_decrypted.created().map(|t| t.timestamp() as u64),
        })
    }
}