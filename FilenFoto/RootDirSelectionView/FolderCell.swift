//
//  FolderCell.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import SwiftUI

struct FolderList: View {
    let directories: [Directory]

    var body: some View {
        List {
            Section {
                ForEach(directories) { directory in
                    NavigationLink(directory.name) {
                        RootDirSelection(currentDirectory: directory)
                    }
                }
            }
        }
    }
}

#Preview {
    FolderList(
        directories: [
            Directory(
                uuid: UUID().uuidString,
                name: "Test Folder",
                parentUuid: UUID().uuidString,
                favorited: true,
                createdAt: UInt64(Date.now.timeIntervalSince1970))
        ]
    )
}
