//
//  ErrorMessages.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import SwiftUI

struct ErrorMessages: View {
    @EnvironmentObject var photoContext: PhotoContext

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Spacer()
                    if !photoContext.errorMessages.isEmpty {
                        ErrorMessagesPopupButton(geometry: geometry)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(20)
            }
        }
    }
}

#Preview {
    let photoContext = {
        let photoContext = PhotoContext.shared
        photoContext.errorMessages.append("This is an error message.")
        photoContext.errorMessages.append("This is another error message that is quite long and should be truncated.")
        for i in 1...10 {
            photoContext.errorMessages.append("Error message \(i)")
        }

        return photoContext
    }()

    ErrorMessages()
        .environmentObject(photoContext)
}
