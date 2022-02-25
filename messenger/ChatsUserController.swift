//
//  ChatsUserController.swift
//  messenger
//
//  Created by Alexander Firsov on 07.02.2022.
//

import UIKit

class ChatsUserController: UITableViewController {
    let spinner = UIActivityIndicatorView()
    let groupWaitResponseHttp = DispatchGroup()
    var contact = ContactStorage.shared
    
    override func loadView() {
        super.loadView()
        contact.loadMyUser()
        if self.contact.myUser == nil {
            showMyContact()
        }
        else {
            startSpinner(true)
            groupWaitResponseHttp.enter()
            contact.loadContactsFromDB(group: groupWaitResponseHttp)
            groupWaitResponseHttp.notify(qos: .background, queue: .main) { [self] in
                startSpinner(false)
                showAlertMessage("Результат подгрузки контактов")
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
        spinner.frame = CGRect(x: screenSize.width / 2, y: screenSize.height / 2, width: 20, height: 10)
        spinner.color = .systemBlue
        spinner.style = .large
        if let baseView = view.superview {
            baseView.addSubview(spinner)
        }
        print("Chats - viewDidLayoutSubviews")
    }
    
    // MARK: создание учётной записи или загрузка текущей с сервера
    @IBAction func showMyContact() {
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
                startSpinner(true)
                groupWaitResponseHttp.enter()
                if contact.myUser == nil {
                    contact.getMyUserFromDB(group: groupWaitResponseHttp, telephone: telephone, name: name)
                }
                else {
                    contact.patchMyUserFromDB(group: groupWaitResponseHttp, telephone: telephone, name: name)
                }
            }
            else {
                contact.sql.answerOnRequest = "Одно из обязательных полей не заполнено!"
            }
            
            groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
                startSpinner(false)
                showAlertMessage("Результат сохранения")
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
    
    func showAlertMessage (_ myTitle: String) {
        let alert = UIAlertController(title: myTitle, message: (contact.sql.answerOnRequest ?? "Неизвестный ответ сервера"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func startSpinner(_ onOf: Bool){
        if onOf {
            spinner.startAnimating()
            navigationController?.setNavigationBarHidden(true, animated: true)
            navigationController?.setToolbarHidden(true, animated: true)
        }
        else {
            spinner.stopAnimating()
            navigationController?.setNavigationBarHidden(false, animated: true)
            navigationController?.setToolbarHidden(false, animated: true)
        }
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
