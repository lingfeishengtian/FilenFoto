//
//  SearchView.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/9/24.
//
import SwiftUI

struct SearchView : View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @StateObject var fullImageState = FullImageViewState()
    @State private var fanOut = false
    @Binding var searchBarShow: Bool
    @Binding var searchText: String
    @FocusState.Binding var keyboardFocus: Bool
    let animation: Namespace.ID
    
    @State private var showingAsset: DBPhotoAsset? = nil
    @State private var offset: CGSize = .zero
    
    var body: some View {
        VStack {
            HStack {
                Text("Search")
                    .font(.largeTitle)
                    .bold()
                    .padding([.leading], 10)
                    .padding([.bottom], 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Button {
                    withAnimation {
                        searchBarShow = false
                        keyboardFocus = false
                    }
                } label: {
                    IconView(size: .small, iconSystemName: "xmark")
                }
            }
            if searchText.count == 0 {
                Text("Popular Categories")
                    .font(.subheadline)
                    .bold()
                    .padding([.leading], 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                PopularCategoryTags(category: .object)
                    .padding([.leading, .trailing])
                    .animation(.easeInOut, value: searchText.count == 0)
                Text("Common Text")
                    .font(.subheadline)
                    .bold()
                    .padding([.leading], 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                PopularCategoryTags(category: .text)
                    .padding([.leading, .trailing])
                    .animation(.easeInOut, value: searchText.count == 0)
                Spacer()
                FanOutListView(
                    history: photoEnvironment.searchHistoryCache,
                    onChangeValueClicked: { val in
                        withAnimation {
                            fanOut = false
                            searchText = val
                            photoEnvironment.addNewSearchHistory(searchQuery: val)
                        }
                    })
            } else {
                if photoEnvironment.searchArray.isEmpty {
                    Spacer()
                    Text("No Search Results")
                        .font(.title2)
                        .bold()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [.init(.adaptive(minimum: 80, maximum: .infinity), spacing: 5)]) {
                            ForEach(photoEnvironment.searchArray, id: \.self) { dbPhotoAsset in
                                Color.clear.background(
                                    Image(
                                        uiImage: UIImage(contentsOfFile: dbPhotoAsset.thumbnailURL.path) ?? UIImage()
                                    )
                                    .resizable()
                                    .matchedGeometryEffect(
                                        id: "searchBarThumbnailImageTransition"
                                        + dbPhotoAsset.localIdentifier,
                                        in: animation,
                                        isSource: true
                                    )
                                    .scaledToFill()
                                    .clipped()
                                )
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerSize: .init(width: 10, height: 10)))
                                .clipped()
                                .opacity(showingAsset == dbPhotoAsset ? 0 : 1)
                                .onTapGesture {
                                    withAnimation {
                                        showingAsset = dbPhotoAsset
                                        Task {
                                            await fullImageState.getView(selectedDbPhotoAsset: dbPhotoAsset)
                                        }
                                        keyboardFocus = false
                                    }
                                }
                                .onAppear {
                                    if dbPhotoAsset == photoEnvironment.searchArray.last {
                                        Task {
                                            photoEnvironment.addMoreSearchResults()
                                        }
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
            TextField("Search", text: $searchText)
                .paddedRounded(fill: Color(UIColor.darkGray).opacity(0.7))
                .foregroundStyle(.white)
                .focused($keyboardFocus)
                .onChange(of: keyboardFocus) {
                    withAnimation {
                        fanOut = keyboardFocus
                    }
                }
                .matchedGeometryEffect(id: "searchbar", in: animation)
                .onChange(of: searchText) {
                    if searchText.count > 0 {
                        Task {
                            photoEnvironment.searchStream(searchQuery: searchText)
                        }
                    } else {
                        Task {
                            photoEnvironment.defaultStream()
                        }
                    }
                }
                .onAppear {
                    keyboardFocus = true
                }
                .onSubmit {
                    withAnimation {
                        if searchText.count == 0 {
                            searchBarShow = false
                            keyboardFocus = false
                        } else {
                            withAnimation {
                                photoEnvironment.addNewSearchHistory(
                                    searchQuery: searchText)
                            }
                        }
                    }
                }
        }
        .padding()
        .overlay{
            if showingAsset != nil {
                fullImageState.imageViewGeneration.generateView(dbPhotoAsset: showingAsset, isPinching: $fullImageState.isPinching)
                .matchedGeometryEffect(
                    id: "searchBarThumbnailImageTransition"
                    + (showingAsset?.localIdentifier ?? ""),
                    in: animation
                ).offset(offset)
                .gesture(DragGesture().onChanged { value in
                    offset = value.translation
                }.onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation {
                            showingAsset = nil
                            offset = .zero
                        }
                    } else {
                        withAnimation {
                            offset = .zero
                        }
                    }
                })
            }
        }
    }
}
