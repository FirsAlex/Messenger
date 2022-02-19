//
//  ChatsCell.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import UIKit

class ChatsCell: UITableViewCell {
    @IBOutlet var nameContact: UILabel!
    @IBOutlet var lastMessageTime: UILabel!
    @IBOutlet var symbol: UILabel!
    @IBOutlet var lastMessage: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
