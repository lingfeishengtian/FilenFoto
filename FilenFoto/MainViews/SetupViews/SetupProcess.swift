//
//  SetupProcess.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import SwiftUI
import FilenSDK

struct SetupFolderRoot : View {
    @State var baseFolderUuid: String? = nil
    @Binding var hasPhotoFolder: Bool
    
    func retrieveBaseFolderUuid() {
        Task {
            do {
                baseFolderUuid = try await getFilenClientWithUserDefaultConfig()!.baseFolder().uuid
            } catch {
                print(error)
                retrieveBaseFolderUuid()
            }
        }
    }
    
    var body: some View {
        if baseFolderUuid == nil {
            Text("Getting base folder uuid")
                .onAppear {
                    retrieveBaseFolderUuid()
                }
        } else {
            SetupFolder(currentFolderUuid: baseFolderUuid!, onSelected: {uuid in
                filenPhotoFolderUUID = uuid
                hasPhotoFolder = true
            })
        }
    }
    
}

struct SetupFolder: View {
    let currentFolderUuid: String
    let folderName: String?
    let onSelected: (String) -> Void
    let requiresEmptyFolder: Bool
    
    init(currentFolderUuid: String, onSelected: @escaping (String) -> Void, folderName: String? = nil, requiresEmptyFolder: Bool = true) {
        self.currentFolderUuid = currentFolderUuid
        self.folderName = folderName
        self.onSelected = onSelected
        self.requiresEmptyFolder = requiresEmptyFolder
    }
    
    let filenClient = getFilenClientWithUserDefaultConfig()!
    
    @State var currentDirectory: [DirContentFolder] = []
    @State var currentFiles: [DirContentFolder] = []
    @State var isEmptyFolder = false
    @State var errorMessage = ""
    @State var errorPresented: Bool = false
    @State var isLoading: Bool = true
    
    @State var startCreatingNewFolder: Bool = false
    @State var newFolderName: String = ""
    
    func enumerateFolder(uuid: String) {
        Task {
            do {
                let resCont = (try await filenClient.dirContent(uuid: uuid))
                currentDirectory = resCont.folders
                isEmptyFolder = resCont.uploads.count == 0 && resCont.folders.count == 0
                for (index, _) in currentDirectory.enumerated() {
                    currentDirectory[index].name = try filenClient.decryptFolderName(name: currentDirectory[index].name)
                    print(currentDirectory[index].uuid)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    var body: some View {
        QuickLoadingView(isLoading: isLoading) {
            NavigationStack {
                List {
                    ForEach(currentDirectory, id: \.name) { folder in
                        NavigationLink(){
                            SetupFolder(currentFolderUuid: folder.uuid, onSelected: onSelected, folderName: folder.name, requiresEmptyFolder: requiresEmptyFolder)
                        } label: {
                            Text(folder.name)
                        }
                    }
                    if currentDirectory.isEmpty && !isEmptyFolder {
                        Text("This folder is not empty.")
                    }
                }
                .navigationTitle(folderName ?? "Select Folder")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        /// folderName should always be nil for the root folder
                        if folderName != nil && (!requiresEmptyFolder || isEmptyFolder) {
                            Button("", systemImage: "checkmark.circle") {
                                onSelected(currentFolderUuid)
                            }
                        }
                        Button("", systemImage: "plus.circle") {
                            startCreatingNewFolder = true
                        }
                    }
                }
            }.onAppear {
                enumerateFolder(uuid: currentFolderUuid)
            }
            .alert(errorMessage, isPresented: $errorPresented, actions: {})
            .alert("New Folder Name", isPresented: $startCreatingNewFolder, actions: {
                TextField("Enter name", text: $newFolderName)
                    .autocorrectionDisabled()
                
                Button("OK", action: {
                    isLoading = true
                    Task {
                        do {
                            // The API lets this through for some reaosn...
                            if newFolderName.count <= 0 {
                                errorMessage = "Must enter a name"
                                errorPresented = true
                            } else {
                                let _ = try await filenClient.createFolder(name: newFolderName, parent: currentFolderUuid)
                                enumerateFolder(uuid: currentFolderUuid)
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            errorPresented = true
                        }
                        isLoading = false
                    }
                })
            })
        }
    }
}
