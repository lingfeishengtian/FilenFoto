//
//  ErrorMessagesListView.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//
import SwiftUI

struct ErrorMessagesListView: View {
    @EnvironmentObject var photoContext: PhotoContext
    @Binding var expanded: Bool
    
    let geometry: GeometryProxy

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Errors")
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        // TODO: Fix this nested with animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            expanded = false
                        } completion: {
                            withAnimation {
                                photoContext.errorMessages.removeAll()
                            }
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title2)
                    }
                }

                ForEach(photoContext.errorMessages, id: \.self) { message in
                    Text(message)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}
