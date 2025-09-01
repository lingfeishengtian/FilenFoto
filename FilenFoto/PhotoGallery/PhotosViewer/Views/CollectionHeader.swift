//
//  CollectionHeader.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/1/25.
//

import Foundation
import UIKit

class CollectionHeader: UICollectionReusableView {
    let textLabel: UILabel = {
        let label = UILabel()
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        label.font = UIFont(descriptor: fontDescriptor.withSymbolicTraits(.traitBold)!, size: 0)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Photos"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
