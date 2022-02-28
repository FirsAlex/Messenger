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
    
    // MARK: создание контакта для аккаунта текущего
    @IBAction func showNewContact() {
        // создание Alert Controller
        let alertController = UIAlertController(title: "Введите имя и телефон нового контакта", message: "(обязательные поля)", preferredStyle: .alert)
        // добавляем первое поле в Alert Controller
        alertController.addTextField { textField in
                                    textField.placeholder = "Имя"
        }
        alertController.addTextField { textField in
                                    textField.placeholder = "Телефон"
                                    textField.keyboardType = .phonePad
        }
        
        // кнопка создания контакта
        let createButton = UIAlertAction(title: "Сохранить", style: .default) {[self] _ in
            guard let name = alertController.textFields?[0].text,
                  let telephone = alertController.textFields?[1].text else { return }
            // создаем новый контакт
            if name != "" && telephone != "" {
                spinner = contact.startSpinner("Сохранение", self)
                groupWaitResponseHttp.enter()
                contact.saveContactToDB(group: groupWaitResponseHttp, telephone: telephone, name: name)
            }
            else { contact.sql.answerOnRequest = "Одно из обязательных полей не заполнено!" }
            
            groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
                tableView.reloadData()
                spinner?.dismiss(animated: true, completion: {contact.showAlertMessage("Сохранение", self)})
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

}
