//
//  ChatController.swift
//  messenger
//
//  Created by Alexander Firsov on 03.03.2022.
//

import UIKit

class ChatController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //получение значение типа UINib, соответствующее xib-файлу кастомной ячейки
        let chatsCellNib = UINib(nibName: "ChatsCell", bundle: nil)
        //регистрация кастомной ячейки в табличном представлении
        tableView.register(chatsCellNib, forCellReuseIdentifier: "ChatsCell")
        print("Chats - viewDidLoad")
    }
    
    // перейти к корневой сцене
       @IBAction func toRootScreen(_ sender: UIBarButtonItem) {
       self.navigationController?.popToRootViewController(animated: true)
   }

}

// MARK: - источник данных
extension ChatController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //получение переиспользуемой кастомной ячейки по ее идентификатору
        let chatsCell = tableView.dequeueReusableCell(withIdentifier: "ChatsCell", for: indexPath) as! ChatsCell
        //заполняем ячейку данными
        chatsCell.nameContact.text = "Юлька"
        chatsCell.lastMessageTime.text = "01.02.2022"
        chatsCell.symbol.attributedText = NSAttributedString(string: "\u{2713}\u{2713}", attributes: [.kern: -6])
        chatsCell.lastMessage.text = "Вы: Трам пам пам очень большой прибольшой текстище текстовый такой здаровый здоровенный егегей!!!"
        return chatsCell
    }
}

// MARK: - делегирование
extension ChatController: UITableViewDelegate {

}
