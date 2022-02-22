//
//  ChatsUserController.swift
//  messenger
//
//  Created by Alexander Firsov on 07.02.2022.
//

import UIKit

class ChatsUserController: UITableViewController {
    let spinner = UIActivityIndicatorView()
    var contact = ContactStorage.shared
    let sql = SqlRequest()
    
    
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
    
    //MARK: subView spinner
    override func viewDidLayoutSubviews() {
        let screenSize = UIScreen.main.bounds
        spinner.frame = CGRect(x: screenSize.width / 2, y: screenSize.height / 2, width: 5, height: 5)
        spinner.color = .systemBlue
        spinner.style = .large
        if let baseView = view.superview {
            baseView.addSubview(spinner)
        }
        print("Chats - viewDidLayoutSubviews")
    }
    
    // MARK: создание учётной записи или загрузка текущей с сервера
    @IBAction func showMyContact() {
        let groupWaitResponseHttp = DispatchGroup()
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
            // создаем новый контакт
            if name != "" && telephone != "" {
                spinner.startAnimating()
                navigationController?.setNavigationBarHidden(true, animated: true)
                navigationController?.setToolbarHidden(true, animated: true)
                groupWaitResponseHttp.enter()
                if contact.myUser == nil {
                    //GET
                    sql.sendRequest("users/by_telephone/" + telephone, [:], "GET") {
                        let responseJSON = sql.responseJSON as? [String:String]
                        if sql.httpStatus?.statusCode == 502 {
                            sql.answerOnRequest = "Нет связи с сервером 502 Bad Gateway!"
                            groupWaitResponseHttp.leave()
                        }
                        else if sql.httpStatus?.statusCode == 200 {
                            contact.myUser = User(id: responseJSON?["id"], telephone: telephone,
                                                  name: responseJSON?["name"] ?? "")
                            sql.answerOnRequest = "Найден аккаунт в БД с таким же номером телефона!"
                            groupWaitResponseHttp.leave()
                        }
                        else if sql.httpStatus?.statusCode == nil {
                            sql.answerOnRequest = "Сервер не ответил на запрос!"
                            groupWaitResponseHttp.leave()
                        }
                        //POST
                        else if sql.httpStatus?.statusCode == 404 {
                            sql.sendRequest("users", ["name":name, "telephone":telephone], "POST") {
                                if sql.httpStatus?.statusCode == 200 {
                                    contact.myUser = User(id: responseJSON?["id"], telephone: telephone, name: name)
                                    sql.answerOnRequest = "Новый аккаунт сохранён!"
                                }
                                else { sql.answerOnRequest = "Новый аккаунт не сохранён!" }
                                groupWaitResponseHttp.leave()
                            }
                        }
                    }
                    
                }
                else {
                    //PATCH
                    sql.sendRequest("users/"+(contact.myUser!.id ?? ""), ["name":name, "telephone":telephone], "PATCH"){
                        if sql.httpStatus?.statusCode == 200 {
                            contact.myUser?.name = name
                            contact.myUser?.telephone = telephone
                            sql.answerOnRequest = "Аккаунт обновлён!"
                        }
                        else if sql.httpStatus?.statusCode == 502 {
                            sql.answerOnRequest = "Нет связи с сервером 502 Bad Gateway!"
                        }
                        else {
                            sql.answerOnRequest = "Не удалось обновить запись в таблице пользователей!"
                        }
                        groupWaitResponseHttp.leave()
                    }
                }
            }
            else {
                sql.answerOnRequest = "Одно из обязательных полей не заполнено!"
            }
            
            groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
                spinner.stopAnimating()
                navigationController?.setNavigationBarHidden(false, animated: true)
                navigationController?.setToolbarHidden(false, animated: true)
                showAlertMessage("Результат сохранения", (sql.answerOnRequest ?? "Неизвестный ответ сервера") + "\n\nИмя: \(contact.myUser?.name ?? "")" + "\nТелефон: \(contact.myUser?.telephone ?? "")")
                sql.answerOnRequest = nil
                sql.httpStatus = nil
            }
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
        return 10
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
