//
//  Contact.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import Foundation
import UIKit

protocol ContactStorageProtocol {
    func loadContactsFromDB(group: DispatchGroup)
    func saveContactToDB(group: DispatchGroup, telephone: String, name: String)
    func deleteContactFromDB(group: DispatchGroup, contactID: Int)
    func updateContactFromDB(group: DispatchGroup, telephone: String, name: String, contactID: Int)
    
    func loadMyUser()
    func saveMyUser(_ user: UserProtocol)
    
    func getMyUserFromDB(group: DispatchGroup, telephone: String, name: String)
    func postMyUserToDB(group: DispatchGroup, telephone: String, name: String)
    func patchMyUserFromDB(group: DispatchGroup, telephone: String, name: String)
    
    func getMessage(group: DispatchGroup, contactID: Int, delivered: String)
    func getMessageFromDB(group: DispatchGroup, contactID: String, delivered: String)
    func updateMessageFromDB(group: DispatchGroup, contactID: String)
    func sendMessage(group: DispatchGroup, contactID: Int, text: String)
    func sendMessageToDB(group: DispatchGroup, contactID: String, text: String)
    func isodateFromString(_ isoString: String) -> String
}

class ContactStorage: ContactStorageProtocol {
    static let shared = ContactStorage()
    let sql = SqlRequest()
    
    var contacts: [UserProtocol] = []
    var messages: [MessageProtocol] = []
    
    var myUser: UserProtocol? {
        didSet {
            self.saveMyUser(myUser!)
        }
    }
    
    // Ссылка на хранилище для локальной УЗ
    private var storageMyUser = UserDefaults.standard
    // Ключ, по которому будет происходить сохранение и загрузка хранилища из User Defaults
    var storageMyUserKey: String = "myMessenger"
    
    init (){
    }
    
    //MARK: работа с аккаунтом
    func saveMyUser(_ user: UserProtocol) {
        var newElementForStorage: Dictionary<String, String> = [:]
        newElementForStorage["telephone"] = user.telephone
        newElementForStorage["name"] = user.name
        newElementForStorage["id"] = user.id
        storageMyUser.set(newElementForStorage, forKey: storageMyUserKey)
    }
    
    func loadMyUser() {
        let myUserFromStorage = storageMyUser.dictionary(forKey: storageMyUserKey) as? [String : String] ?? [:]
        let id = myUserFromStorage["id"]
        guard let telephone = myUserFromStorage["telephone"],
              let name = myUserFromStorage["name"] else { return}
        myUser = User(id: id, telephone: telephone, name: name)
    }
    
    func getMyUserFromDB(group: DispatchGroup, telephone: String, name: String){
        //GET
        sql.sendRequest("users/by_telephone/" + telephone, [:], "GET") { [self] in
            let responseJSON = sql.responseJSON as? [String:String]
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                myUser = User(id: responseJSON?["id"], telephone: telephone, name: (responseJSON?["name"] ?? ""))
                sql.answerOnRequest = "Найден аккаунт в БД с таким же номером телефона!" + "\nИмя: \(myUser?.name ?? "")" + "\nТелефон: \(myUser?.telephone ?? "")\n"
                loadContactsFromDB(group: group)
            }
            else if sql.httpStatus?.statusCode == 404 {
                postMyUserToDB(group: group, telephone: telephone, name: name)
            }
        }
    }

    func postMyUserToDB(group: DispatchGroup, telephone: String, name: String){
        //POST
        sql.sendRequest("users", ["name":name, "telephone":telephone], "POST") { [self] in
            let responseJSON = sql.responseJSON as? [String:String]
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                myUser = User(id: responseJSON?["id"], telephone: telephone, name: name)
                sql.answerOnRequest = "Новый аккаунт сохранён!"
                group.leave()
            }
        }
    }
    
    func patchMyUserFromDB(group: DispatchGroup, telephone: String, name: String) {
        //PATCH
        sql.sendRequest("users/"+(myUser!.id ?? ""), ["name":name, "telephone":telephone], "PATCH"){ [self] in
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                myUser?.name = name
                myUser?.telephone = telephone
                sql.answerOnRequest = "Аккаунт обновлён!"
                group.leave()
            }
        }
    }
    
    //MARK: работа с контактами аккаунта
    func loadContactsFromDB(group: DispatchGroup) {
        sql.sendRequest("contacts/by_user/" + (myUser?.id ?? ""), [:], "GET") { [self] in
            let responseJSON = sql.responseJSON as? [[String:Any]] ?? []
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                for contact in responseJSON {
                    contacts.append(User(id: contact["id"] as? String, telephone: (contact["telephone"] as? String ?? ""),
                                         name: (contact["name"] as? String ?? "")))
                }
                if responseJSON.count != 0 {
                    sql.answerOnRequest = "\(sql.answerOnRequest ?? "")" + "Контакты аккаунта загружены!"
                }
                else {
                    sql.answerOnRequest = "\(sql.answerOnRequest ?? "")" + "У аккаунта не найдено контактов!"
                }
                group.leave()
            }
        }
    }
    
    func saveContactToDB(group: DispatchGroup, telephone: String, name: String) {
        if (self.contacts.filter{$0.telephone == telephone}.count == 0) {
            //POST
            sql.sendRequest("contacts/by_user/" + (myUser?.id ?? ""), ["name":name, "telephone":telephone], "POST") { [self] in
                let responseJSON = sql.responseJSON as? [String:Any]
                sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
                if sql.httpStatus?.statusCode == 200 {
                    contacts.append(User(id: responseJSON?["id"] as? String, telephone: telephone, name: name))
                    sql.answerOnRequest = "Новый контакт сохранён!"
                    group.leave()
                }
            }
        }
        else { sql.answerOnRequest = "Указанный номер телефона присутствует среди Ваших контактов!"; group.leave() }
    }
    
    func deleteContactFromDB(group: DispatchGroup, contactID: Int) {
        //DELETE
        sql.sendRequest("contacts/" + (contacts[contactID].id ?? ""), [:], "DELETE"){ [self] in
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                contacts.remove(at: contactID)
                sql.answerOnRequest = "Контакт удалён!"
                group.leave()
            }
        }
    }
    
    func updateContactFromDB(group: DispatchGroup, telephone: String, name: String, contactID: Int) {
        let indexFind = self.contacts.firstIndex(where: {$0.telephone == telephone})
        if (indexFind == contactID || indexFind == nil) {
            //PATCH
            sql.sendRequest("contacts/" + (contacts[contactID].id ?? ""), ["name":name, "telephone":telephone], "PATCH") { [self] in
                sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
                if sql.httpStatus?.statusCode == 200 {
                    contacts[contactID].name = name
                    contacts[contactID].telephone = telephone
                    sql.answerOnRequest = "Контакт изменён!"
                    group.leave()
                }
            }
        }
        else { sql.answerOnRequest = "Указанный номер телефона присутствует среди Ваших контактов!"; group.leave() }
    }
    
    //MARK: работа с сообщениями
    func getMessage(group: DispatchGroup, contactID: Int, delivered: String) {
        sql.sendRequest("users/by_telephone/" + contacts[contactID].telephone, [:], "GET") { [self] in
            let responseJSON = sql.responseJSON as? [String:Any]
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                contacts[contactID].userID = responseJSON?["id"] as? String
                getMessageFromDB(group: group, contactID: responseJSON?["id"] as! String, delivered: delivered)
            }
            else if sql.httpStatus?.statusCode == 404 {
                sql.answerOnRequest = "Контакт не зарегистрирован в системе!"
                group.leave()
            }
        }
        
    }
    
    func getMessageFromDB(group: DispatchGroup, contactID: String, delivered: String) {
        sql.sendRequest("messages/between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID + "&delivered=" + delivered, [:], "GET") { [self] in
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            let responseJSON = sql.responseJSON as? [[String:Any]] ?? []
            if sql.httpStatus?.statusCode == 200 {
                for message in responseJSON {
                    let toUser = (message["toUser"] as! Dictionary<String, String>)["id"]
                    let type = toUser == (myUser?.id ?? "") ? MessageType.incomming : MessageType.outgoing
                    let contact = type == .incomming ? contactID : myUser?.id
                    messages.append(Message(id: message["id"] as! String, text: message["text"] as! String,
                                            delivered: message["delivered"] as! Bool, contactID: contact ?? "",
                            createdAt: isodateFromString(message["createdAt"] as! String), type: type))
                }
                if responseJSON.count != 0 {
                    sql.answerOnRequest = "Сообщения получены!"
                    updateMessageFromDB(group: group, contactID: contactID)
                }
            }
        }
    }
    
    func updateMessageFromDB(group: DispatchGroup, contactID: String) {
      sql.sendRequest("messages/between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID, [:], "PATCH") { [self] in
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                sql.answerOnRequest = "Сообщения обновлены!"
                group.leave()
            }
      }
    }
    
    func sendMessage(group: DispatchGroup, contactID: Int, text: String){
        sql.sendRequest("users/by_telephone/" + contacts[contactID].telephone, [:], "GET") { [self] in
            let responseJSON = sql.responseJSON as? [String:Any]
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                contacts[contactID].userID = responseJSON?["id"] as? String
                sendMessageToDB(group: group, contactID: responseJSON?["id"] as! String, text: text)
            }
            else if sql.httpStatus?.statusCode == 404 {
                sql.answerOnRequest = "Контакт не зарегистрирован в системе!"
                group.leave()
            }
        }
    }
    
    func sendMessageToDB(group: DispatchGroup, contactID: String, text: String) {
        sql.sendRequest("messages", ["text":text, "fromUserID": myUser!.id ?? "", "toUserID": contactID], "POST") { [self] in
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            let responseJSON = sql.responseJSON as? [String:Any]
            if sql.httpStatus?.statusCode == 200 {
                messages.append(Message(id: responseJSON?["id"] as! String, text: text, delivered: false, contactID: contactID, createdAt: isodateFromString(responseJSON?["createdAt"] as! String), type: .outgoing))
                sql.answerOnRequest = "Сообщение отправлено!"
                group.leave()
            }
        }
    }
    
    func isodateFromString(_ isoString: String) -> String {
        let stringToDateFormatter = ISO8601DateFormatter()
        stringToDateFormatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        stringToDateFormatter.formatOptions = [.withFullDate, .withFullTime, .withDashSeparatorInDate]
        guard let date = stringToDateFormatter.date(from: isoString) else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    //MARK: вывод на TableViewController элементов
    func showAlertMessage (_ myTitle: String, _ myController: UIViewController) {
        let alert = UIAlertController(title: myTitle, message: (sql.answerOnRequest ?? "Неизвестный ответ сервера"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        myController.present(alert, animated: true, completion: nil)
    }
    
    func startSpinner(_ myTitle: String = "", _ myController: UITableViewController) -> UIAlertController? {
        //create an alert controller
        let myAlert = UIAlertController(title: myTitle, message: "\n\n\n", preferredStyle: .alert)
        //create an activity indicator
        let spinner = UIActivityIndicatorView(frame: myAlert.view.bounds)
        spinner.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        spinner.color = .systemBlue
        spinner.style = .large
        // required otherwise if there buttons in the UIAlertController you will not be able to press them
        spinner.isUserInteractionEnabled = false
        spinner.startAnimating()
        //add the activity indicator as a subview of the alert controller's view
        myAlert.view.addSubview(spinner)
        myController.present(myAlert, animated: true, completion: nil)
        return myAlert
    }
}
