//
//  ChatsUserController.swift
//  messenger
//
//  Created by Alexander Firsov on 07.02.2022.
//

import UIKit

class ChatsUserController: UITableViewController {
    var contact = ContactStorage.shared
    let sql = SqlRequest()
    let groupWaitResponseHttp = DispatchGroup()
    
    override func loadView() {
        super.loadView()
        if self.contact.myUser == nil {
            showMyContact()
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
        //self.navigationController!.isToolbarHidden = true
        print("Chats - viewWillDisappear")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //self.navigationController!.isToolbarHidden = false
        self.editButtonItem.title = "Изменить"
        self.navigationItem.leftBarButtonItem = self.editButtonItem
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
            groupWaitResponseHttp.enter()
            guard let name = alertController.textFields?[0].text,
                  let telephone = alertController.textFields?[1].text else { return }
            // создаем новый контакт
            if name != "" && telephone != "" {
                if contact.myUser == nil {
                    //GET
                    sql.sendRequest("users/by_telephone/" + telephone, [:], "GET") { responseJson in
                        if sql.httpStatus?.statusCode == 502 {
                            answerOnRequest = "Нет связи с сервером\n502 Bad Gateway!"
                        }
                        else if sql.httpStatus?.statusCode == 404 {
                            //POST
                            sql.sendRequest("users", ["name":name, "telephone":telephone], "POST") { responseJson in
                                if sql.httpStatus?.statusCode == 200 {
                                    contact.myUser = User(id: responseJson?["id"] as? String, telephone: telephone, name: name)
                                    answerOnRequest = "Новая УЗ сохранена!"
                                }
                                else { answerOnRequest = "Новая УЗ не сохранена!" }
                            }
                            
                        }
                        else if sql.httpStatus?.statusCode == 200 {
                            contact.myUser = User(id: responseJson?["id"] as? String, telephone: telephone,
                                                  name: responseJson?["name"] as? String ?? "")
                            answerOnRequest = "Найдена УЗ в БД с таким же номером телефона!"
                        }
                        else if sql.httpStatus?.statusCode == nil {
                            answerOnRequest = "Сервер не ответил на запрос!"
                        }
                        groupWaitResponseHttp.leave()
                    }
                }
                else {
                    //PATCH
                    sql.sendRequest("users/"+(contact.myUser!.id ?? ""), ["name":name, "telephone":telephone], "PATCH"){
                        responseJson in
                        if sql.httpStatus?.statusCode == 200 {
                            contact.myUser?.name = name
                            contact.myUser?.telephone = telephone
                            answerOnRequest = "УЗ обновлена!"
                        }
                        else if sql.httpStatus?.statusCode == 502 {
                            answerOnRequest = "Нет связи с сервером 502 Bad Gateway!"
                        }
                        else {
                            answerOnRequest = "Не удалось обновить запись в таблице пользователей!"
                        }
                        groupWaitResponseHttp.leave()
                    }
                }
            }
            else {
                answerOnRequest = "Одно из обязательных полей не заполнено!"
                groupWaitResponseHttp.leave()
            }
            groupWaitResponseHttp.wait()
            showAlertMessage("Результат сохранения", answerOnRequest ?? "Неизвестный ответ сервера")
            answerOnRequest = nil
        }
        
        // кнопка отмены
        let cancelButton = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        // добавляем кнопки в Alert Controller
        alertController.addAction(cancelButton)
        alertController.addAction(createButton)
        // отображаем Alert Controller
        self.present(alertController, animated: true)
    }
    
    func showAlertMessage (_ myTitle: String, _ myMessage: String) {
        let alert = UIAlertController(title: myTitle, message: myMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
