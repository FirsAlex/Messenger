//
//  MessageFromUserCell.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import UIKit

class MessageFromUserCell: UITableViewCell {
    @IBOutlet weak var outgoingText: UILabel!
    @IBOutlet weak var outgoingTime: UILabel!
    @IBOutlet weak var symbol: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
