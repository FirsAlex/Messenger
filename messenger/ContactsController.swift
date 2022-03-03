//
//  ContactsController.swift
//  messenger
//
//  Created by Alexander Firsov on 09.02.2022.
//

import UIKit

class ContactsController: UITableViewController {
    let groupWaitResponseHttp = DispatchGroup()
    var spinner: UIAlertController?
    var contact = ContactStorage.shared
    
    deinit{
        print("ContactsController - deinit")
    }
    
    override func loadView() {
        super.loadView()
        print("Contacts - loadView")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //получение значение типа UINib, соответствующее xib-файлу кастомной ячейки
        let chatsCellNib = UINib(nibName: "ContactsCell", bundle: nil)
        //регистрация кастомной ячейки в табличном представлении
        tableView.register(chatsCellNib, forCellReuseIdentifier: "ContactsCell")
        print("Contacts - viewDidLoad")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("Contacts - viewWillDisappear")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Contacts - viewWillAppear")
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.contact.contacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // загружаем прототип ячейки по идентификатору
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactsCell", for: indexPath) as! ContactsCell
        let currentContact = contact.contacts[indexPath.row]
        // изменяем текст в ячейке
        cell.nameContact.text = currentContact.name
        cell.telephoneContact.text = currentContact.telephone
        return cell
    }
    
    // MARK: создание/редактирование контакта для аккаунта текущего
    @IBAction func showNewContact() {
        editContact()
    }

    func editContact(contactID: Int? = nil) {
        // создание Alert Controller
        let alertController = UIAlertController(title: "Введите имя и телефон контакта", message: "(обязательные поля)", preferredStyle: .alert)
        // добавляем первое поле в Alert Controller
        alertController.addTextField { [self] textField in
            textField.placeholder = "Имя"
            textField.text = (contactID != nil) ? contact.contacts[contactID!].name : ""
        }
        alertController.addTextField { [self] textField in
            textField.placeholder = "Телефон"
            textField.text = (contactID != nil) ? contact.contacts[contactID!].telephone : ""
            textField.keyboardType = .phonePad
        }
        
        // кнопка создания контакта
        let createButton = UIAlertAction(title: "Сохранить", style: .default) {[self] _ in
            guard let name = alertController.textFields?[0].text,
                  let telephone = alertController.textFields?[1].text else { return }
            spinner = contact.startSpinner("Сохранение", self)
            // создаем новый контакт
            if name != "" && telephone != "" {
                groupWaitResponseHttp.enter()
                (contactID == nil) ? contact.saveContactToDB(group: groupWaitResponseHttp, telephone: telephone, name: name) : contact.updateContactFromDB(group: groupWaitResponseHttp, telephone: telephone, name: name, contactID: contactID!)
            }
            else { contact.sql.answerOnRequest = "Одно из обязательных полей не заполнено!" }
            
            groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
                spinner?.dismiss(animated: true, completion: {contact.showAlertMessage("Сохранение", self)})
                tableView.reloadData()
            }
        }
        // кнопка отмены
        let cancelButton = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        // добавляем кнопки в Alert Controller
        alertController.addAction(cancelButton)
        alertController.addAction(createButton)
        // отображаем Alert Controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: Обработка swipe влево - удаление
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // действие удаления
        let actionDelete = UIContextualAction(style: .destructive, title: "\u{1F5D1}") { [self] _,_,_ in
            spinner = contact.startSpinner("Удаление", self)
            groupWaitResponseHttp.enter()
            contact.deleteContactFromDB(group: groupWaitResponseHttp, contactID: indexPath.row)
            groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
                // удаляем строку, соответствующую задаче
                spinner?.dismiss(animated: true, completion: {contact.showAlertMessage("Удаление", self)})
                tableView.reloadData()
            }
        }
        // действие изменить
        let actionEdit = UIContextualAction(style: .normal, title: "\u{270D}") { [self] _,_,_ in
            editContact(contactID: indexPath.row)
        }
        // формируем экземпляр, описывающий доступные действия
        let actions = UISwipeActionsConfiguration(actions: [actionDelete, actionEdit])
        return actions
    }
    
    //MARK: обработка выделения строки
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ChatController") as! ChatController
        chatScreen.navigationItem.title = (tableView.cellForRow(at: indexPath) as! ContactsCell).nameContact.text
        // переход к экрану редактирования
        self.navigationController?.pushViewController(chatScreen, animated: true)
    }
    
}
