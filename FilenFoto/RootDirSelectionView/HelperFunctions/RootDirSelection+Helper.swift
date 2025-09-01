//
//  RootDirSelection+Helper.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import Foundation
import SwiftUI

extension RootDirSelection {
    func setCurrentDirectoryAsRoot() {
        guard let currentDirectory else {
            return
        }

        photoContext.rootPhotoDirectory = UUID(uuidString: currentDirectory.uuid)
    }

    func initDirectoryList() async {
        guard let filenClient = photoContext.filenClient else {
            directories = []
            return
        }

        let directory = currentDirectory?.uuid ?? filenClient.rootUuid()

        do {
            directories = try await filenClient.dirsInDir(dirUuid: directory)
            sortDirectories()
        } catch {
            photoContext.errorMessages.append("Failed to fetch directories: \(error.localizedDescription)")
        }
    }

    func sortDirectories() {
        directories?.sort { $0.name.lowercased() < $1.name.lowercased() }
    }

    func createNewFolder() {
        guard let filenClient = photoContext.filenClient else {
            return
        }

        let parentDirUuid = currentDirectory?.uuid ?? filenClient.rootUuid()
        isPendingCRUDOperation = true

        Task {
            do {
                let directory = try await filenClient.createDirInDir(parentUuid: parentDirUuid, name: newFolderName)
                directories?.append(directory)
                sortDirectories()
            } catch {
                photoContext.errorMessages.append("Failed to create directory: \(error.localizedDescription)")
            }

            DispatchQueue.main.async {
                isPendingCRUDOperation = false
                newFolderName = ""
            }
        }
    }
}
