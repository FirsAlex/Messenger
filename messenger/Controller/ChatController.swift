//
//  ChatController.swift
//  messenger
//
//  Created by Alexander Firsov on 03.03.2022.
//

import UIKit

class ChatController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dataTextField: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    deinit{
        removeForKeyboardNotifications()
        print("ChatController - deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //получение значение типа UINib, соответствующее xib-файлу кастомной ячейки
        let chatsCellNib = UINib(nibName: "ChatsCell", bundle: nil)
        //регистрация кастомной ячейки в табличном представлении
        tableView.register(chatsCellNib, forCellReuseIdentifier: "ChatsCell")
        
        registerForKeyboardNotifications()
        
        dataTextField.layer.borderColor = UIColor.lightGray.cgColor
        dataTextField.layer.cornerRadius = 15
        dataTextField.layer.borderWidth = 0.5
        print("ChatController - viewDidLoad")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.scrollToBottom()
        print("ChatController - viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ChatController - viewDidAppear")
    }
    
    // перейти к корневой сцене
    @IBAction func toRootScreen(_ sender: UIBarButtonItem) {
        self.navigationController?.popToRootViewController(animated: true)
   }
    
    // отправка
    @IBAction func send() {
        print("WORK!!!")
    }
    
    //MARK: обрабатываем нотификации от клавиатуры
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func kbWillShow(_ notification: Notification) {
        let userInfo = notification.userInfo
        let kbFrameSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        scrollView.contentOffset = CGPoint(x: 0, y: kbFrameSize.height) //
    }
    
    @objc func kbWillHide() {
        scrollView.contentOffset = CGPoint.zero
    }

}

// MARK: - источник данных ChatController
extension ChatController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //получение переиспользуемой кастомной ячейки по ее идентификатору
        let chatsCell = tableView.dequeueReusableCell(withIdentifier: "ChatsCell", for: indexPath) as! ChatsCell
        //заполняем ячейку данными
        chatsCell.nameContact.text = "Юлька \(indexPath.row)"
        chatsCell.lastMessageTime.text = "01.02.2022"
        chatsCell.symbol.attributedText = NSAttributedString(string: "\u{2713}\u{2713}", attributes: [.kern: -6])
        chatsCell.lastMessage.text = "Вы: Трам пам пам очень большой прибольшой текстище текстовый такой здаровый здоровенный егегей!!!"
        return chatsCell
    }
}

// MARK: - делегирование ChatController
extension ChatController: UITableViewDelegate {
    
    //обработка выделения строки
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dataTextField.resignFirstResponder()
        // снимаем выделение со строки
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK: - расширение TableView
extension UITableView {

    func scrollToBottom(isAnimated: Bool = false){
        DispatchQueue.main.async {
            let indexPath = IndexPath(
                row: self.numberOfRows(inSection:  self.numberOfSections-1) - 1,
                section: self.numberOfSections - 1)
            if self.hasRowAtIndexPath(indexPath: indexPath) {
                self.scrollToRow(at: indexPath, at: .bottom, animated: isAnimated)
            }
        }
    }

    func scrollToTop(isAnimated:Bool = false) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            if self.hasRowAtIndexPath(indexPath: indexPath) {
                self.scrollToRow(at: indexPath, at: .top, animated: isAnimated)
           }
        }
    }

    func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.section < self.numberOfSections && indexPath.row < self.numberOfRows(inSection: indexPath.section)
        && self.numberOfRows(inSection: indexPath.section) > 0
    }
}
