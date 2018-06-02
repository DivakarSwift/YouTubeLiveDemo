//
//  CommentsCell.swift
//  DemoSwift
//
//  Created by Sohil on 02/06/18.
//  Copyright © 2018 gao. All rights reserved.
//

import UIKit

class CommentsCell: UITableViewCell {
    
    @IBOutlet weak var viewComment: UIView! {
        didSet {
            viewComment.clipsToBounds = true
            viewComment.layer.cornerRadius = 2
        }
    }
    @IBOutlet weak var lblComment: UILabel!
}
