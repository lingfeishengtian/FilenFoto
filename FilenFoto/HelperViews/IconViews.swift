//
//  IconViews.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/18/24.
//

import SwiftUI

struct IconView : View {
    enum Size : CGFloat {
        case small = 15
        case medium = 20
        case large = 25
    }
    
    let size: Size
    let iconSystemName: String
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.35))
            .frame(width: size.rawValue * 2, height: size.rawValue * 2)
            .overlay(
                Image(systemName: iconSystemName)
                    .foregroundColor(.white)
                    .font(.system(size: size.rawValue, weight: .bold))
            )
    }
}
