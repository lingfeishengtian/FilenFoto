//
//  LoadingIndicator.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import SwiftUI

struct LoadingIndicator: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            .scaleEffect(2.0)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground).opacity(0.8))
                    .shadow(radius: 10)
            )
    }
}

#Preview {
    LoadingIndicator()
}
