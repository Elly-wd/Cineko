//
//  DynamicHeightTableViewCell.swift
//  Cineko
//
//  Created by Jovit Royeca on 12/04/2016.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit

class DynamicHeightTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dynamicLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
