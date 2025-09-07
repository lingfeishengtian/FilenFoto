use std::{
    fs::OpenOptions,
    ops::{Index, IndexMut},
    path::{Path, PathBuf},
};

use memmap2::{Mmap, MmapMut};

use crate::err_type::BlobProviderError;

#[repr(u16)]
#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum Version {
    V1 = 1,
}

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct MIdxEntry {
    num_entries: u32,
    reserved: u16,
    version: Version,
}

const _: () = assert!(size_of::<MIdxEntry>() == 8);

pub struct MIdx {
    file_path: PathBuf,
    mmap: MmapMut,
}

pub fn open_or_create_midx(path: &Path) -> Result<MIdx, BlobProviderError> {
    let file = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .open(path)?;

    let mmap = unsafe { MmapMut::map_mut(&file)? };

    // Check entry count
    if mmap.len() % std::mem::size_of::<MIdxEntry>() != 0 {
        return Err(BlobProviderError::InvalidMIdx);
    }

    Ok(MIdx {
        file_path: path.to_path_buf(),
        mmap,
    })
}

impl Index<usize> for MIdx {
    type Output = MIdxEntry;

    fn index(&self, index: usize) -> &Self::Output {
        &self.entries()[index]
    }
}

impl IndexMut<usize> for MIdx {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        &mut self.entries_mut()[index]
    }
}

impl MIdx {
    fn entry_count(&self) -> usize {
        self.mmap.len() / std::mem::size_of::<MIdxEntry>()
    }

    fn entries(&self) -> &[MIdxEntry] {
        unsafe {
            std::slice::from_raw_parts(self.mmap.as_ptr() as *const MIdxEntry, self.entry_count())
        }
    }

    fn entries_mut(&mut self) -> &mut [MIdxEntry] {
        unsafe {
            std::slice::from_raw_parts_mut(
                self.mmap.as_mut_ptr() as *mut MIdxEntry,
                self.entry_count(),
            )
        }
    }

    fn add_entry(&mut self, entry: MIdxEntry) -> Result<(), BlobProviderError> {
        let entry_count = self.entry_count();
        let new_len = entry_count + 1;
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .open(&self.file_path)?;

        file.set_len((new_len * std::mem::size_of::<MIdxEntry>()) as u64)?;

        self.mmap = unsafe { MmapMut::map_mut(&file)? };
        self.entries_mut()
            .last_mut()
            .ok_or(BlobProviderError::InvalidMIdx)?
            .clone_from(&entry);

        Ok(())
    }
}
