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
            .frame(width: size.rawValue * 2.5, height: size.rawValue * 2.5)
            .overlay(
                Image(systemName: iconSystemName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(10 + (iconSystemName == "square.and.arrow.up" ? 0 : 2))
                    .padding([.bottom], iconSystemName == "square.and.arrow.up" ? 5 : 0)
                    .foregroundColor(.white)
                    .font(.system(size: size.rawValue, weight: .bold))
            )
    }
}
