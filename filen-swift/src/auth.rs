use std::sync::Arc;
use tokio::runtime::Builder;
use filen_sdk_rs::auth::StringifiedClient;

use crate::client::{FilenClient, FilenClientError};

pub trait ToCbor {
    fn to_cbor(&self) -> Vec<u8>;
    fn from_cbor(bytes: &[u8]) -> Option<Self> where Self: Sized;
}

impl ToCbor for StringifiedClient {
    fn to_cbor(&self) -> Vec<u8> {
        serde_cbor::to_vec(self).unwrap_or_default()
    }

    fn from_cbor(bytes: &[u8]) -> Option<Self> {
        serde_cbor::from_slice(bytes).ok()
    }
}

fn generate_tokio_runtime() -> Result<tokio::runtime::Runtime, FilenClientError> {
    Builder::new_multi_thread()
        .enable_all()
        .build()
        .map_err(|e| FilenClientError::ConcurrencyError {
            msg: format!("Failed to create Tokio runtime: {}", e),
        })
}

#[uniffi::export]
pub fn client_from_credentials(client_credentials: Vec<u8>) -> Result<FilenClient, FilenClientError> {
    let client = filen_sdk_rs::auth::Client::from_stringified(StringifiedClient::from_cbor(&client_credentials).ok_or_else(|| {
        FilenClientError::TypeConversionError {
            msg: "Failed to parse client credentials".into(),
        }
    })?).map_err(|e| FilenClientError::TypeConversionError {
        msg: format!("Failed to create client from credentials: {}", e),
    })?;

    let tokio_runtime = generate_tokio_runtime()?;

    Ok(FilenClient {
        client: Arc::new(client),
        tokio_runtime,
    })
}

#[uniffi::export]
pub async fn login(
    email: String,
    pwd: String,
    two_factor_code: String,
) -> Result<FilenClient, FilenClientError> {
    let tokio_runtime = generate_tokio_runtime()?;

    let handle = tokio_runtime.handle().spawn(async move {
        filen_sdk_rs::auth::Client::login(email, &pwd, &two_factor_code).await
    }).await.map_err(|e| FilenClientError::ConcurrencyError {
        msg: format!("Runtime task (login) failed: {}", e),
    })?;

    Ok(FilenClient {
        client: Arc::new(handle?),
        tokio_runtime,
    })
}

#[uniffi::export]
impl FilenClient {
    pub fn export_credentials(&self) -> Vec<u8> {
        self.client.to_stringified().to_cbor()
    }
}