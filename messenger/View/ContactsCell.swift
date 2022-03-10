//
//  ContactsCell.swift
//  messenger
//
//  Created by Alexander Firsov on 09.02.2022.
//

import UIKit

class ContactsCell: UITableViewCell {
    @IBOutlet weak var nameContact: UILabel!
    @IBOutlet weak var telephoneContact: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
