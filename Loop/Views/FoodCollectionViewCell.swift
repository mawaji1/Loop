//
//  FoodCollectionViewCell.swift
//  Loop
//
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import Foundation
import UIKit

final class FoodCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var foodLabel: UILabel?
    
    @IBOutlet weak var carbLabel: UILabel?
    
    override func prepareForReuse() {
        self.imageView.image = nil
        self.backgroundColor = UIColor.lightGray
        if self.foodLabel != nil {
            self.foodLabel!.text = "???"
        }
        if self.carbLabel != nil {
            self.carbLabel!.text = ""
        }
    }
}
