//
//  RootDirSelection.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import SwiftUI

extension Directory: Identifiable {
    public var id: String { uuid }
}

struct RootDirSelection: View {
    @EnvironmentObject var photoContext: PhotoContext
    @State var directories: [Directory]?
    @State var isPendingCRUDOperation: Bool = false
    
    var currentDirectory: Directory?

    // MARK: Computed State Properties
    var isLoading: Bool { directories == nil }
    var hasNoSubdirectories: Bool { directories?.isEmpty ?? true }
    var isRootDirectory: Bool { currentDirectory == nil }
    var canSetCurrentDirectoryAsRoot: Bool { !isRootDirectory && !isLoading && hasNoSubdirectories }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if canSetCurrentDirectoryAsRoot {
                        Text("No directories found. You may use this folder as your photo storage.")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if isRootDirectory && hasNoSubdirectories {
                        Text("Create a folder in your cloud storage and use it to store photos.")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        FolderList(directories: directories ?? [])
                            .refreshable {
                                await initDirectoryList()
                            }
                    }
                }
                .onAppear{
                    Task {
                        await initDirectoryList()
                    }
                }
                .navigationTitle(currentDirectory?.name ?? String(localized: "Select Root Directory"))
                .toolbar { toolbar }
            }
            
            if isPendingCRUDOperation {
                Overlay()
                LoadingIndicator()
            }
        }
    }
    
    @State var shouldShowConfirmationDialog = false
    @State var shouldShowAddFolderDialog = false
    @State var newFolderName: String = ""

    var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                shouldShowAddFolderDialog = true
            } label: {
                Image(systemName: "plus")
            }.alert("Create Folder", isPresented: $shouldShowAddFolderDialog) {
                TextField("Folder Name", text: $newFolderName)
                Button("Create", action: createNewFolder)
                    .disabled(newFolderName.isEmpty)
                Button("Cancel", role: .cancel, action: {})
            }

            if canSetCurrentDirectoryAsRoot {
                Button {
                    shouldShowConfirmationDialog = true
                } label: {
                    Image(systemName: "checkmark")
                }.confirmationDialog("Confirm Selection", isPresented: $shouldShowConfirmationDialog) {
                    Button("Set as Root Directory", role: .destructive, action: setCurrentDirectoryAsRoot)
                }
            }
        }
    }
}

#Preview {
    RootDirSelection()
        .environmentObject(PhotoContext.shared)
}
