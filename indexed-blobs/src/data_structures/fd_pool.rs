use std::{
    collections::{HashMap, VecDeque},
    io::{Read, Seek},
    path::PathBuf,
    sync::{Arc, Mutex, MutexGuard, RwLock},
};

use crate::err_type::BlobProviderError;

const MAX_OPEN_FILE_DESCRIPTORS: usize = 12;

pub(crate) struct FdPool {
    open_file_descriptors: RwLock<HashMap<usize, Arc<Mutex<std::fs::File>>>>,
    vec_deque: RwLock<VecDeque<usize>>,
}

impl FdPool {
    pub(crate) fn new() -> Self {
        Self {
            open_file_descriptors: HashMap::new().into(),
            vec_deque: VecDeque::new().into(),
        }
    }

    pub(crate) fn blocking_read(
        &self,
        index: usize,
        offset: u64,
        len: u64,
    ) -> Result<Vec<u8>, BlobProviderError> {
        let file_descriptor_mutex_lock = self.get_file_descriptor_mutex(index)?;
        let mut current_file_descriptor = file_descriptor_mutex_lock.lock()?;

        current_file_descriptor.seek(std::io::SeekFrom::Start(offset))?;

        let mut buffer = vec![0; len as usize];
        current_file_descriptor.read_exact(&mut buffer)?;

        Ok(buffer)
    }

    pub(crate) fn does_fd_exist(&self, index: usize) -> Result<bool, BlobProviderError> {
        let read_descriptor = self.open_file_descriptors.read()?;
        Ok(read_descriptor.contains_key(&index))
    }

    pub(crate) fn insert_fd(
        &self,
        index: usize,
        fd: std::fs::File,
    ) -> Result<(), BlobProviderError> {
        let read_descriptor = self.open_file_descriptors.read()?;
        if read_descriptor.contains_key(&index) {
            return Err(BlobProviderError::FileDescriptorAlreadyExists(index as u64));
        }

        let mut writing_descriptor = self.open_file_descriptors.write()?;
        let mut writing_vec_deque = self.vec_deque.write()?;

        // Remove the oldest file descriptor if we've reached the limit
        if writing_descriptor.len() >= MAX_OPEN_FILE_DESCRIPTORS {
            if let Some(removed_index) = writing_vec_deque.pop_front() {
                writing_descriptor.remove(&removed_index);
            }
        }

        writing_descriptor.insert(index, Arc::new(Mutex::new(fd)));
        writing_vec_deque.push_back(index);

        Ok(())
    }
}

// Private helper methods
impl FdPool {
    fn get_file_descriptor_mutex(
        &self,
        index: usize,
    ) -> Result<Arc<Mutex<std::fs::File>>, BlobProviderError> {
        Ok(self
            .open_file_descriptors
            .read()?
            .get(&index)
            .ok_or(BlobProviderError::InvalidChunkIndex(index as u64))?
            .clone())
    }
}
