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
                    NavigationLink{
                        RootDirSelection(currentDirectory: directory)
                    } label: {
                        Image(systemName: "folder")
                            .foregroundStyle(directory.swiftColor() ?? .blue)
                        Text(directory.name)
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
                color: nil,
                createdAt: UInt64(Date.now.timeIntervalSince1970))
        ]
    )
}
