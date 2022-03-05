//
//  MessageToUserCell.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import UIKit

class MessageToUserCell: UITableViewCell {
    @IBOutlet weak var incommingText: UILabel!
    @IBOutlet weak var incommingTime: UILabel!
   
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
