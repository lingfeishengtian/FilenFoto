//
//  PopularCategoryTags.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/18/24.
//

import SwiftUI

struct PopularCategoryTags: View {
    @State var tags: [String] = []
    // TODO: Make multi tag search
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { item in
                    Text(item.replacingOccurrences(of: "_", with: " ").capitalized)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(6)
                        .padding([.leading, .trailing], 6)
                        .background(Color(UIColor.darkGray).opacity(0.8))
                        .cornerRadius(25)
                }
            }
        }
        .onAppear {
            tags = PhotoDatabase.shared.getMostPopularObjects()
        }
    }
}

#Preview {
    PopularCategoryTags()
}
