//
//  ImageCollectionView.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/15/24.
//

import Foundation
import UIKit

class ImageCollectionView: UICollectionView, UICollectionViewDataSource {
    init() {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        dataSource = self
        register(TestViewCell.self, forCellWithReuseIdentifier: "TestViewCell")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        dataSource = self
        register(TestViewCell.self, forCellWithReuseIdentifier: "TestViewCell")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: "TestViewCell", for: indexPath) as! TestViewCell
        cell.configure(text: "\(indexPath.item)")
        return cell
    }
    
    
}

class TestViewCell: UICollectionViewCell {
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }
    
    func configure(text: String) {
        label.text = text
    }
}
