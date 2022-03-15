//
//  Contact.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import Foundation
import UIKit

protocol ContactStorageProtocol {
    func loadContactsFromDB(group: DispatchGroup) -> (Int?, String?)
    func saveContactToDB(group: DispatchGroup, telephone: String, name: String) -> (Int?, String?)
    func deleteContactFromDB(group: DispatchGroup, contactID: Int) -> (Int?, String?)
    func updateContactFromDB(group: DispatchGroup, telephone: String, name: String, contactID: Int) -> (Int?, String?)
    
    func loadMyUser()
    func saveMyUser(_ user: UserProtocol)
    
    func getMyUserFromDB(group: DispatchGroup, telephone: String, name: String) -> (Int?, String?)
    func postMyUserToDB(group: DispatchGroup, telephone: String, name: String) -> (Int?, String?)
    func patchMyUserFromDB(group: DispatchGroup, telephone: String, name: String) -> (Int?, String?)
    
    func getMessage(group: DispatchGroup, contactID: Int, delivered: String, _ completion: @escaping () -> Void) -> (Int?, String?)
    func getMessageFromDB(group: DispatchGroup, contactID: String, delivered: String, _ completion: @escaping () -> Void) -> (Int?, String?)
    func getStatusOutgoingMessageFromDB(group: DispatchGroup, contactID: String, delivered: String,_ completion: @escaping () -> Void) -> (Int?, String?)
    func updateStatusIncommingMessageToDB(group: DispatchGroup, contactID: String, responseJSON: [[String:Any]], _ completion: @escaping () -> Void) -> (Int?, String?)
    
    func sendMessage(group: DispatchGroup, contactID: Int, text: String) -> (Int?, String?)
    func sendMessageToDB(group: DispatchGroup, contactID: String, text: String) -> (Int?, String?)
    
    func getLastMessageContacts(group: DispatchGroup, contactID: Int) -> (Int?, String?)
    func getLastMessageContactsFromDB(group: DispatchGroup, contactID: String) -> (Int?, String?)
    
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
    
    func getMyUserFromDB(group: DispatchGroup, telephone: String, name: String) -> (Int?, String?) {
        //GET
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("users/by_telephone/" + telephone, [:], "GET") { [self] httpStatus,responseJSON in
            let responseJSON = responseJSON as? [String:String]
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            if httpStatus?.statusCode == 200 {
                myUser = User(id: responseJSON?["id"], telephone: telephone, name: (responseJSON?["name"] ?? ""))
                (status, answerOnRequest) = loadContactsFromDB(group: group)
            }
            else if httpStatus?.statusCode == 404 {
                (status, answerOnRequest) = postMyUserToDB(group: group, telephone: telephone, name: name)
            }
        }
        return (status, answerOnRequest)
    }

    func postMyUserToDB(group: DispatchGroup, telephone: String, name: String) -> (Int?, String?) {
        //POST
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("users", ["name":name, "telephone":telephone], "POST") { [self] httpStatus,responseJSON in
            let responseJSON = responseJSON as? [String:String]
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            if httpStatus?.statusCode == 200 {
                myUser = User(id: responseJSON?["id"], telephone: telephone, name: name)
                group.leave()
            }
        }
        return (status, answerOnRequest)
    }
    
    func patchMyUserFromDB(group: DispatchGroup, telephone: String, name: String) -> (Int?, String?) {
        //PATCH
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("users/"+(myUser!.id ?? ""), ["name":name, "telephone":telephone], "PATCH"){ [self] httpStatus,_ in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            if httpStatus?.statusCode == 200 {
                myUser?.name = name
                myUser?.telephone = telephone
                group.leave()
            }
        }
        return (status, answerOnRequest)
    }
    
    //MARK: работа с контактами аккаунта
    func loadContactsFromDB(group: DispatchGroup) -> (Int?, String?) {
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("contacts/by_user/" + (myUser?.id ?? ""), [:], "GET") { [self] httpStatus,responseJSON in
            let responseJSON = responseJSON as? [[String:Any]] ?? []
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            if httpStatus?.statusCode == 200 {
                for contact in responseJSON {
                    contacts.append(User(id: contact["id"] as? String, telephone: (contact["telephone"] as? String ?? ""),
                                         name: (contact["name"] as? String ?? "")))
                }
                group.leave()
            }
        }
        return (status, answerOnRequest)
    }
    
    func saveContactToDB(group: DispatchGroup, telephone: String, name: String) -> (Int?, String?) {
        var answerOnRequest: String?
        var status: Int?
        if (self.contacts.filter{$0.telephone == telephone}.count == 0) {
            //POST
            sql.sendRequest("contacts/by_user/" + (myUser?.id ?? ""), ["name":name, "telephone":telephone], "POST") { [self]  httpStatus,responseJSON in
                let responseJSON = responseJSON as? [String:Any]
                answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
                status = httpStatus?.statusCode
                if httpStatus?.statusCode == 200 {
                    contacts.append(User(id: responseJSON?["id"] as? String, telephone: telephone, name: name))
                    answerOnRequest = "Контакт сохранён!"
                    group.leave()
                }
            }
        }
        else { answerOnRequest = "Указанный номер телефона присутствует среди Ваших контактов!"; group.leave() }
        return (status, answerOnRequest)
    }
    
    func deleteContactFromDB(group: DispatchGroup, contactID: Int) -> (Int?, String?){
        //DELETE
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("contacts/" + (contacts[contactID].id ?? ""), [:], "DELETE"){ [self] httpStatus,_ in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            if httpStatus?.statusCode == 200 {
                contacts.remove(at: contactID)
                answerOnRequest = "Контакт удалён!"
                group.leave()
            }
        }
        return (status, answerOnRequest)
    }
    
    func updateContactFromDB(group: DispatchGroup, telephone: String, name: String, contactID: Int) -> (Int?, String?) {
        var answerOnRequest: String?
        var status: Int?
        let indexFind = self.contacts.firstIndex(where: {$0.telephone == telephone})
        if (indexFind == contactID || indexFind == nil) {
            //PATCH
            sql.sendRequest("contacts/" + (contacts[contactID].id ?? ""), ["name":name, "telephone":telephone], "PATCH") { [self]  httpStatus, _ in
                answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
                status = httpStatus?.statusCode
                if httpStatus?.statusCode == 200 {
                    contacts[contactID].name = name
                    contacts[contactID].telephone = telephone
                    answerOnRequest = "Контакт изменён!"
                    group.leave()
                }
            }
        }
        else { answerOnRequest = "Указанный номер телефона присутствует среди Ваших контактов!"; group.leave() }
        return (status, answerOnRequest)
    }
    
    //MARK: работа с сообщениями
    func getMessage(group: DispatchGroup, contactID: Int, delivered: String,_ completion: @escaping () -> Void) -> (Int?, String?){
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("users/by_telephone/" + contacts[contactID].telephone, [:], "GET") { [self] httpStatus,responseJSON in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            let responseJSON = responseJSON as? [String:Any]
            if httpStatus?.statusCode == 200 {
                (status, answerOnRequest) =
                getStatusOutgoingMessageFromDB(group: group, contactID: responseJSON?["id"] as! String, delivered: delivered, completion)
            }
            else if httpStatus?.statusCode == 404 {
                answerOnRequest = "Контакт не зарегистрирован в системе!"
                group.leave()
            }
        }
        return (status, answerOnRequest)
    }
    
    func getStatusOutgoingMessageFromDB(group: DispatchGroup, contactID: String, delivered: String,_ completion: @escaping () -> Void) -> (Int?, String?) {
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("messages/between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID + "&delivered=trueOutgoing", [:], "GET") { [self] httpStatus,responseJSON in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            let responseJSON = responseJSON as? [[String:Any]] ?? []
            if httpStatus?.statusCode == 200 {
                for message in responseJSON {
                    let id = message["id"] as! String
                    messages = messages.map { value in
                        var newValue = value
                        newValue.delivered = (newValue.id == id) ? true : newValue.delivered
                        return newValue
                    }
                }
                (status, answerOnRequest) = getMessageFromDB(group: group, contactID: contactID, delivered: delivered, completion)
            }
        }
        return (status, answerOnRequest)
    }
    
    func getMessageFromDB(group: DispatchGroup, contactID: String, delivered: String, _ completion: @escaping () -> Void) -> (Int?, String?) {
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("messages/between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID + "&delivered=" + delivered, [:], "GET") { [self] httpStatus,responseJSON in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            let responseJSON = responseJSON as? [[String:Any]] ?? []
            if httpStatus?.statusCode == 200 {
                if responseJSON.count != 0 {
                    (status, answerOnRequest) = updateStatusIncommingMessageToDB(group: group, contactID: contactID, responseJSON: responseJSON, completion)
                }
                else {
                    group.leave()
                }
            }
        }
        return (status, answerOnRequest)
    }
    
    func updateStatusIncommingMessageToDB(group: DispatchGroup, contactID: String, responseJSON: [[String:Any]], _ completion: @escaping () -> Void) -> (Int?, String?) {
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("messages/between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID, [:], "PATCH") { [self] httpStatus,_ in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
                if httpStatus?.statusCode == 200 {
                    for message in responseJSON {
                        let toUser = (message["toUser"] as! Dictionary<String, String>)["id"]
                        let type = toUser == (myUser?.id ?? "") ? MessageType.incomming : MessageType.outgoing
                        messages.append(Message(id: message["id"] as! String, text: message["text"] as! String, delivered: message["delivered"] as! Bool, contactID: contactID, createdAt: isodateFromString(message["createdAt"] as! String), type: type))
                    }
                    completion()
                    group.leave()
                }
        }
        return (status, answerOnRequest)
    }
    
    func sendMessage(group: DispatchGroup, contactID: Int, text: String) -> (Int?, String?){
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("users/by_telephone/" + contacts[contactID].telephone, [:], "GET") { [self] httpStatus,responseJSON in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            let responseJSON = responseJSON as? [String:Any]
            if httpStatus?.statusCode == 200 {
                (status, answerOnRequest) = sendMessageToDB(group: group, contactID: responseJSON?["id"] as! String, text: text)
            }
            else if httpStatus?.statusCode == 404 {
                answerOnRequest = "Контакт не зарегистрирован в системе!"
                group.leave()
            }
        }
        return (status, answerOnRequest)
    }
    
    func sendMessageToDB(group: DispatchGroup, contactID: String, text: String) -> (Int?, String?) {
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("messages", ["text":text, "fromUserID": myUser!.id ?? "", "toUserID": contactID], "POST") { [self] httpStatus,responseJSON in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            let responseJSON = responseJSON as? [String:Any]
            if httpStatus?.statusCode == 200 {
                messages.append(Message(id: responseJSON?["id"] as! String, text: text, delivered: false, contactID: contactID, createdAt: isodateFromString(responseJSON?["createdAt"] as! String), type: .outgoing))
                group.leave()
            }
        }
        return (status, answerOnRequest)
    }
    
    func getLastMessageContacts(group: DispatchGroup, contactID: Int) -> (Int?, String?){
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("users/by_telephone/" + contacts[contactID].telephone, [:], "GET") { [self] httpStatus,responseJSON in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            let responseJSON = responseJSON as? [String:Any]
            if httpStatus?.statusCode == 200 {
                (status, answerOnRequest) = getLastMessageContactsFromDB(group: group, contactID: responseJSON?["id"] as! String)
            }
            else if httpStatus?.statusCode == 404 {
                answerOnRequest = "Контакт не зарегистрирован в системе!"
                group.leave()
            }
        }
        return (status, answerOnRequest)
    }
    
    func getLastMessageContactsFromDB(group: DispatchGroup, contactID: String) -> (Int?, String?) {
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("messages/last_between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID + "&delivered=all", [:], "GET") { [self] httpStatus,responseJSON in
            answerOnRequest = sql.answerOnRequestError(group: group, statusCode: httpStatus?.statusCode)
            status = httpStatus?.statusCode
            let responseJSON = responseJSON as? [String:Any]
            if httpStatus?.statusCode == 200 {
                let toUser = (responseJSON!["toUser"] as! Dictionary<String, String>)["id"]
                let type = toUser == (myUser?.id ?? "") ? MessageType.incomming : MessageType.outgoing
                messages.append(Message(id: responseJSON?["id"] as! String, text: responseJSON?["text"] as! String, delivered: responseJSON?["delivered"] as! Bool, contactID: contactID, createdAt: isodateFromString(responseJSON?["createdAt"] as! String), type: type))
                group.leave()
            }
            else if httpStatus?.statusCode == 404 {
                answerOnRequest = "У контакта нет сообщений!"
                group.leave()
            }
        }
        return (status, answerOnRequest)
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
    func showAlertMessage (_ myTitle: String, _ myAnswer: String?, _ myController: UIViewController) {
        let alert = UIAlertController(title: myTitle, message: myAnswer ?? "Неизвестный ответ от сервера", preferredStyle: .alert)
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
