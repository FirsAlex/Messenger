//
//  ChatsCell.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import UIKit

class ChatsCell: UITableViewCell {
    @IBOutlet weak var nameContact: UILabel!
    @IBOutlet weak var lastMessageTime: UILabel!
    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var lastMessage: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
