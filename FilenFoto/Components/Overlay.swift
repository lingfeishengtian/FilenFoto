//
//  Overlay.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import SwiftUI

struct Overlay: View {
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
    }
}

#Preview {
    Overlay()
}
