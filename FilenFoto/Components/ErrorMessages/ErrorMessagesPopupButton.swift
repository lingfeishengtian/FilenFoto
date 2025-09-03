//
//  ErrorMessagesPopupButton.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//
import SwiftUI

struct ErrorMessagesPopupButton: View {
    @EnvironmentObject var photoContext: PhotoContext
    @State private var expanded = false

    let geometry: GeometryProxy

    var body: some View {
        Button {
            withAnimation {
                expanded.toggle()
            }
        } label: {
            if expanded {
                ErrorMessagesListView(expanded: $expanded, geometry: geometry)
                    .frame(maxHeight: geometry.size.height * 0.4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
            }
        }
        .padding(expanded ? 20 : 14)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: expanded ? 24 : 50))
        .contextMenu {
            Button(role: .destructive) {
                withAnimation {
                    photoContext.errorMessages.removeAll() // TODO: This animation sucks
                }
            } label: {
                Label("Clear All Error Messages", systemImage: "trash")
            }
        }
    }
}
