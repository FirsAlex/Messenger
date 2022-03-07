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
    var contact = ContactStorage.shared
    var contactIndex: Int?
    
    deinit{
        removeForKeyboardNotifications()
        print("ChatController - deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //получение значение типа UINib, соответствующее xib-файлу кастомной ячейки
        let incommingCellNib = UINib(nibName: "MessageToUserCell", bundle: nil)
        tableView.register(incommingCellNib, forCellReuseIdentifier: "MessageToUserCell")
        let outgoingCellNib = UINib(nibName: "MessageFromUserCell", bundle: nil)
        tableView.register(outgoingCellNib, forCellReuseIdentifier: "MessageFromUserCell")
        registerForKeyboardNotifications()
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
        scrollView.contentOffset = CGPoint(x: 0, y: kbFrameSize.height)
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
    var chatCell: UITableViewCell!
        
        if indexPath.row % 2 == 0 {
            //получение переиспользуемой кастомной ячейки по ее идентификатору
            chatCell = tableView.dequeueReusableCell(withIdentifier: "MessageToUserCell", for: indexPath)
            (chatCell as! MessageToUserCell).incommingText.text = "\(indexPath.row) Трам пам пам очень большой прибольшой текстище текстовый такой здаровый здоровенный егегей!!!"
            (chatCell as! MessageToUserCell).incommingTime.text = "22:20"
        }
        else {
            chatCell = tableView.dequeueReusableCell(withIdentifier: "MessageFromUserCell", for: indexPath)
            (chatCell as! MessageFromUserCell).outgoingText.text = "\(indexPath.row) Трам пам пам очень большой прибольшой текстище текстовый такой здаровый здоровенный егегей!!!"
            (chatCell as! MessageFromUserCell).outgoingTime.text = "22:21"
            (chatCell as! MessageFromUserCell).symbol.attributedText = NSAttributedString(string: "\u{2713}\u{2713}", attributes: [.kern: -6])
        }
        
        return chatCell
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
    
    func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.section < self.numberOfSections && indexPath.row < self.numberOfRows(inSection: indexPath.section)
        && self.numberOfRows(inSection: indexPath.section) > 0
    }
    
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
    
}
