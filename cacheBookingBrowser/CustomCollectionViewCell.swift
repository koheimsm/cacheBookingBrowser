//
//  CustomCollectionCellCollectionViewCell.swift
//  cacheBookingBrowser
//
//  Created by Kohei Masumi on 2019/03/22.
//  Copyright © 2019年 Kohei Masumi. All rights reserved.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: CustomCollectionViewCellDelegate!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btnDelete: UIButton!

    var urlStr: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    public func configure(with model: TabData) {
        urlStr = model.dataListUrl
    }
    @IBAction func buttonTapped(_ sender: UIButton) {
        delegate.onClickDelete(sender.tag)
    }
    
}

