use boltffi::{custom_type, data};

/// To prevent creating new strings over and over again, use a simplified struct of a UUID, this prevents a string allocation every FFI call.
/// We could also use a tuple, but using explicit field names makes it more clear what the fields represent.
#[data]
#[derive(Copy, Clone)]
pub struct SimplifiedUuid {
    high_bits: u64,
    low_bits: u64,
}

impl SimplifiedUuid {
    pub fn convert_to_native_uuid(&self) -> uuid::Uuid {
        uuid::Uuid::from_u64_pair(self.high_bits, self.low_bits)
    }
    
    /// Create a SimplifiedUuid from a regular UUID
    pub fn from_uuid(uuid: &uuid::Uuid) -> Self {
        let (high_bits, low_bits) = uuid.as_u64_pair();
        SimplifiedUuid { high_bits, low_bits }
    }
}

// TODO: Boltffi exported has conflict with Swift's UUID type
// custom_type!(
//     pub Uuid,
//     remote = uuid::Uuid,
//     repr = SimplifiedUuid,
//     into_ffi = |uuid: &uuid::Uuid| {
//         let (high_bits, low_bits) = uuid.as_u64_pair();
//         SimplifiedUuid { high_bits, low_bits }
//     }
//     try_from_ffi = |simplified_uuid: SimplifiedUuid| {
//         let uuid = uuid::Uuid::from_u64_pair(simplified_uuid.high_bits, simplified_uuid.low_bits);
//         Ok(uuid)
//     }
// );
