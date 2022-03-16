//
//  ChatsUserController.swift
//  messenger
//
//  Created by Alexander Firsov on 07.02.2022.
//

import UIKit

class ChatsUserController: UITableViewController {
    var spinner: UIAlertController?
    var contact = ContactStorage.shared
    
    override func loadView() {
        super.loadView()        
        contact.loadMyUser()
        if contact.myUser == nil {
            showMyContact()
        }
        else {
            spinner = contact.startSpinner("Загрузка контактов", self)
            contact.loadContactsFromDB(){ [self] status, answerOnRequest in
                spinner?.dismiss(animated: true){ [self] in
                    if status != 200 {
                        contact.showAlertMessage("Загрузка контактов", answerOnRequest, self)
                    }
                }
                loadLastMessages()
            }
        }
        print("Chats - loadView")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        //получение значение типа UINib, соответствующее xib-файлу кастомной ячейки
        let chatsCellNib = UINib(nibName: "ChatsCell", bundle: nil)
        //регистрация кастомной ячейки в табличном представлении
        tableView.register(chatsCellNib, forCellReuseIdentifier: "ChatsCell")
        print("Chats - viewDidLoad")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController!.isToolbarHidden = true
        contact.messages = []
        print("Chats - viewWillDisappear")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController!.isToolbarHidden = false
        self.editButtonItem.title = "Изменить"
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        loadLastMessages()
        print("Chats - viewWillAppear")
    }
    
    //MARK: кнопка edit в режиме редактирования
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        if !editing {
            self.editButtonItem.title = "Изменить"
        }
        else {
            self.editButtonItem.title = "Применить"
        }
    }
    
    // MARK: создание учётной записи или загрузка текущей с сервера
    @IBAction func showMyContact() {
        var answerOnRequest: String?
        // создание Alert Controller
        let alertController = UIAlertController(title: "Введите Ваше имя и телефон", message: "(обязательные поля)", preferredStyle: .alert)
        // добавляем первое поле в Alert Controller
        alertController.addTextField { textField in
                                    textField.placeholder = "Имя"
                                    textField.text = self.contact.myUser?.name ?? ""
        }
        alertController.addTextField { textField in
                                    textField.placeholder = "Телефон"
                                    textField.text = self.contact.myUser?.telephone ?? ""
                                    textField.keyboardType = .phonePad
        }
        
        // кнопка создания контакта
        let createButton = UIAlertAction(title: "Сохранить", style: .default) {[self] _ in
            guard let name = alertController.textFields?[0].text,
                  let telephone = alertController.textFields?[1].text else { return }
            spinner = contact.startSpinner("Сохранение", self)
            // создаем новый контакт
            if name != "" && telephone != "" {
                if contact.myUser == nil {
                    contact.getMyUserFromDB(telephone: telephone){ statusNew, answerOnRequestNew in
                        answerOnRequest = answerOnRequestNew
                        if statusNew == 200 {
                            contact.loadContactsFromDB(){ _, answer in answerOnRequest! += "" + answer! }
                        }
                        else if statusNew == 404 {
                            contact.postMyUserToDB(telephone: telephone, name: name){ _, answer in answerOnRequest = answer}
                        }
                        spinner?.dismiss(animated: true, completion: {contact.showAlertMessage("Результат загрузки", answerOnRequest, self)})
                    }
                }
                else {
                    contact.patchMyUserFromDB(telephone: telephone, name: name){ _, answer in answerOnRequest = answer
                        spinner?.dismiss(animated: true, completion: {contact.showAlertMessage("Результат обновления", answerOnRequest, self)})
                    }
                }
            }
            else { spinner?.dismiss(animated: true, completion: {contact.showAlertMessage("Сохранение", "Не заполнено обязательное поле!", self)})}
        }
        // кнопка отмены
        let cancelButton = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        // добавляем кнопки в Alert Controller
        alertController.addAction(cancelButton)
        alertController.addAction(createButton)
        // отображаем Alert Controller
        self.present(alertController, animated: true)
    }
    
    func loadLastMessages() {
        guard contact.contacts.count != 0 else { return }
        for contactIndex in (0..<contact.contacts.count) {
            contact.getLastMessageContacts(contactIdInner: contactIndex){ [self] statusNew, answerOnRequestNew in
                if statusNew == 200 { tableView.reloadData() }
            }
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contact.messages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chatsCell = tableView.dequeueReusableCell(withIdentifier: "ChatsCell", for: indexPath) as! ChatsCell
        let message = contact.messages[indexPath.row]
        
        chatsCell.nameContact.text = contact.contacts[message.contactIdInner!].name
        chatsCell.lastMessageTime.text = message.createdAt
        if (message.type == .outgoing) {
            chatsCell.lastMessage.text = message.text
            if message.delivered {
                chatsCell.symbol.attributedText = NSAttributedString(string: "\u{2713}\u{2713}", attributes: [.kern: -6])
            }
            else { chatsCell.symbol.text = "\u{2713}" }
        }
        else if message.type == .incomming {
            chatsCell.lastMessage.text = message.text
            chatsCell.symbol.text = ""
        }
  
        return chatsCell
    }

}
