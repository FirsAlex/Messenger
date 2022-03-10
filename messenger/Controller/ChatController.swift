//
//  ChatController.swift
//  messenger
//
//  Created by Alexander Firsov on 03.03.2022.
//

import UIKit

class ChatController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var constraintTopTable: NSLayoutConstraint!
    @IBOutlet weak var dataTextField: UITextView!
    
    let groupWaitResponseHttp = DispatchGroup()
    var contact = ContactStorage.shared
    var contactIndex: Int!
    var httpTimer = MyTimer()
    
    deinit{
        print("ChatController - deinit")
    }
    override func loadView() {
        super.loadView()
        print("ChatController - loadView")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //получение значение типа UINib, соответствующее xib-файлу кастомной ячейки
        let incommingCellNib = UINib(nibName: "MessageToUserCell", bundle: nil)
        tableView.register(incommingCellNib, forCellReuseIdentifier: "MessageToUserCell")
        let outgoingCellNib = UINib(nibName: "MessageFromUserCell", bundle: nil)
        tableView.register(outgoingCellNib, forCellReuseIdentifier: "MessageFromUserCell")
        registerForKeyboardNotifications()
        httpTimer.start { self.loadMessages() }
        httpTimer.timer?.fire()
        print("ChatController - viewDidLoad")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.title = contact.contacts[contactIndex].name
        print("ChatController - viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ChatController - viewDidAppear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeForKeyboardNotifications()
        httpTimer.stop()
        contact.messages = []
        print("ChatController - viewWillDisappear")
    }
    
    // перейти к корневой сцене
    @IBAction func toRootScreen(_ sender: UIBarButtonItem) {
        self.navigationController?.popToRootViewController(animated: true)
   }
    
    // отправка
    @IBAction func send(_ sender: UIButton) {
        guard dataTextField.text != "" else { return }
        groupWaitResponseHttp.enter()
        httpTimer.stop()
        sender.configuration?.showsActivityIndicator = true
        contact.sendMessage(group: groupWaitResponseHttp, contactID: contactIndex, text: dataTextField.text)
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {[self] in
            if contact.sql.httpStatus?.statusCode == 200 {
                dataTextField.text = ""
                tableView.reloadData()
                tableView.scrollToBottom(isAnimated: true)
            }
            else { contact.showAlertMessage("Отправка сообщения", self) }
            sender.configuration?.showsActivityIndicator = false
            contact.sql.httpStatus = nil
            httpTimer.start { self.loadMessages() }
        }
    }

    func loadMessages() {
        groupWaitResponseHttp.enter()
        contact.getMessage(group: groupWaitResponseHttp, contactID: contactIndex)
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {[self] in
            if (contact.sql.httpStatus?.statusCode == 200) && (contact.messages.count != 0) {
                tableView.reloadData()
                tableView.scrollToBottom()
            }
            contact.sql.httpStatus = nil
        }
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
        constraintTopTable.constant = kbFrameSize.height
        tableView.scrollToBottom()
    }
    
    @objc func kbWillHide() {
        scrollView.contentOffset = CGPoint.zero
        constraintTopTable.constant = 0
    }
}

// MARK: - источник данных ChatController
extension ChatController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return contact.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var resultCell: UITableViewCell!
        let message = contact.messages[indexPath.row]
        
        if (message.type == .outgoing) {
            let outgoingCell = tableView.dequeueReusableCell(withIdentifier: "MessageFromUserCell", for: indexPath) as! MessageFromUserCell
            outgoingCell.outgoingText.text = message.text
            outgoingCell.outgoingTime.text = message.createdAt
                if message.delivered {
                    outgoingCell.symbol.attributedText = NSAttributedString(string: "\u{2713}\u{2713}", attributes: [.kern: -6])
                }
                else { outgoingCell.symbol.text = "\u{2713}" }
            resultCell = outgoingCell
        }
        else if message.type == .incomming {
            let incommingCell = tableView.dequeueReusableCell(withIdentifier: "MessageToUserCell", for: indexPath) as! MessageToUserCell
            incommingCell.incommingText.text = message.text
            incommingCell.incommingTime.text = message.createdAt
            resultCell = incommingCell
        }
        
        return resultCell
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
