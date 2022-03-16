//
//  Contact.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import Foundation
import UIKit

protocol ContactStorageProtocol {
    func loadContactsFromDB(_ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func saveContactToDB(telephone: String, name: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func deleteContactFromDB(contactID: Int, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func updateContactFromDB(telephone: String, name: String, contactID: Int, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    
    func loadMyUser()
    func saveMyUser(_ user: UserProtocol)
    
    func getMyUserFromDB(telephone: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func postMyUserToDB(telephone: String, name: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func patchMyUserFromDB(telephone: String, name: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    
    func getMessage(contactID: Int, delivered: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func getMessageFromDB(contactID: String, delivered: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func getStatusOutgoingMessageFromDB(contactID: String, delivered: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func updateStatusIncommingMessageToDB(contactID: String, responseJSON: [[String:Any]], _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    
    func sendMessage(contactID: Int, text: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func sendMessageToDB(contactID: String, text: String,_ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    
    func getLastMessageContacts(contactID: Int,_ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    func getLastMessageContactsFromDB(group: DispatchGroup, contactID: String,_ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ())
    
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
    
    func getMyUserFromDB(telephone: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        //GET
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("users/by_telephone/" + telephone, [:], "GET") { [self] httpStatus,responseJSON in
            let responseJSON = responseJSON as? [String:String]
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            if status == 200 {
                myUser = User(id: responseJSON?["id"], telephone: telephone, name: (responseJSON?["name"] ?? ""))
                answerOnRequest = "Найден аккаунт на сервере!"
            }
            groupWaitResponseHttp.leave()
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }

    func postMyUserToDB(telephone: String, name: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        //POST
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("users", ["name":name, "telephone":telephone], "POST") { [self] httpStatus,responseJSON in
            let responseJSON = responseJSON as? [String:String]
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            if status == 200 {
                myUser = User(id: responseJSON?["id"], telephone: telephone, name: name)
                answerOnRequest = "Аккаунт сохранён!"
            }
            groupWaitResponseHttp.leave()
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func patchMyUserFromDB(telephone: String, name: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        //PATCH
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("users/"+(myUser!.id ?? ""), ["name":name, "telephone":telephone], "PATCH"){ [self] httpStatus,_ in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            if status == 200 {
                myUser?.name = name
                myUser?.telephone = telephone
                answerOnRequest = "Аккаунт изменён!"
            }
            groupWaitResponseHttp.leave()
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    //MARK: работа с контактами аккаунта
    func loadContactsFromDB(_ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("contacts/by_user/" + (myUser?.id ?? ""), [:], "GET") { [self] httpStatus,responseJSON in
            let responseJSON = responseJSON as? [[String:Any]] ?? []
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            if status == 200 {
                for contact in responseJSON {
                    contacts.append(User(id: contact["id"] as? String, telephone: (contact["telephone"] as? String ?? ""),
                                         name: (contact["name"] as? String ?? "")))
                }
                answerOnRequest = "Подгружено \(responseJSON.count) контактов!"
            }
            groupWaitResponseHttp.leave()
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func saveContactToDB(telephone: String, name: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        if (self.contacts.filter{$0.telephone == telephone}.count == 0) {
            //POST
            groupWaitResponseHttp.enter()
            sql.sendRequest("contacts/by_user/" + (myUser?.id ?? ""), ["name":name, "telephone":telephone], "POST") { [self]  httpStatus,responseJSON in
                let responseJSON = responseJSON as? [String:Any]
                status = httpStatus?.statusCode
                answerOnRequest = sql.answerOnRequestError(statusCode: status)
                if status == 200 {
                    contacts.append(User(id: responseJSON?["id"] as? String, telephone: telephone, name: name))
                    answerOnRequest = "Контакт сохранён!"
                }
                groupWaitResponseHttp.leave()
            }
        }
        else { answerOnRequest = "Указанный номер телефона присутствует среди Ваших контактов!"; }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func deleteContactFromDB(contactID: Int, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        //DELETE
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("contacts/" + (contacts[contactID].id ?? ""), [:], "DELETE"){ [self] httpStatus,_ in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            if status == 200 {
                contacts.remove(at: contactID)
                answerOnRequest = "Контакт удалён!"
            }
            groupWaitResponseHttp.leave()
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func updateContactFromDB(telephone: String, name: String, contactID: Int, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        
        let indexFind = self.contacts.firstIndex(where: {$0.telephone == telephone})
        if (indexFind == contactID || indexFind == nil) {
            //PATCH
            groupWaitResponseHttp.enter()
            sql.sendRequest("contacts/" + (contacts[contactID].id ?? ""), ["name":name, "telephone":telephone], "PATCH") { [self]  httpStatus, _ in
                status = httpStatus?.statusCode
                answerOnRequest = sql.answerOnRequestError(statusCode: status)
                if status == 200 {
                    contacts[contactID].name = name
                    contacts[contactID].telephone = telephone
                    answerOnRequest = "Контакт изменён!"
                }
                groupWaitResponseHttp.leave()
            }
        }
        else { answerOnRequest = "Указанный номер телефона присутствует среди Ваших контактов!";}
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    //MARK: работа с сообщениями
    func getMessage(contactID: Int, delivered: String,_ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("users/by_telephone/" + contacts[contactID].telephone, [:], "GET") { [self] httpStatus,responseJSON in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            let responseJSON = responseJSON as? [String:Any]
            if status == 404 {
                answerOnRequest = "Контакт не зарегистрирован в системе!"
                groupWaitResponseHttp.leave()
            }
            else if status == 200{
                getStatusOutgoingMessageFromDB(contactID: responseJSON?["id"] as! String, delivered: delivered){statusNew,answerOnRequestNew in
                    status = statusNew
                    answerOnRequest = answerOnRequestNew
                    groupWaitResponseHttp.leave()
                }
            }
            else { groupWaitResponseHttp.leave() }
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func getStatusOutgoingMessageFromDB(contactID: String, delivered: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("messages/between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID + "&delivered=trueOutgoing", [:], "GET") { [self] httpStatus,responseJSON in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            let responseJSON = responseJSON as? [[String:Any]] ?? []
            if status == 200 {
                for message in responseJSON {
                    let id = message["id"] as! String
                    messages = messages.map { value in
                        var newValue = value
                        newValue.delivered = (newValue.id == id) ? true : newValue.delivered
                        return newValue
                    }
                }
                getMessageFromDB(contactID: contactID, delivered: delivered){statusNew,answerOnRequestNew in
                    status = statusNew
                    answerOnRequest = answerOnRequestNew
                    groupWaitResponseHttp.leave()
                }
            }
            else { groupWaitResponseHttp.leave() }
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func getMessageFromDB(contactID: String, delivered: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("messages/between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID + "&delivered=" + delivered, [:], "GET") { [self] httpStatus,responseJSON in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            let responseJSON = responseJSON as? [[String:Any]] ?? []
            if status == 200 {
                if responseJSON.count != 0 {
                    updateStatusIncommingMessageToDB(contactID: contactID, responseJSON: responseJSON){statusNew,answerOnRequestNew in
                        status = statusNew
                        answerOnRequest = answerOnRequestNew
                        groupWaitResponseHttp.leave()
                    }
                }
                else { status = 404; groupWaitResponseHttp.leave() }
            }
            else { groupWaitResponseHttp.leave() }
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func updateStatusIncommingMessageToDB(contactID: String, responseJSON: [[String:Any]], _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("messages/between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID, [:], "PATCH") { [self] httpStatus,_ in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            if status == 200 {
                for message in responseJSON {
                    let toUser = (message["toUser"] as! Dictionary<String, String>)["id"]
                    let type = toUser == (myUser?.id ?? "") ? MessageType.incomming : MessageType.outgoing
                    messages.append(Message(id: message["id"] as! String, text: message["text"] as! String, delivered: message["delivered"] as! Bool, contactID: contactID, createdAt: isodateFromString(message["createdAt"] as! String), type: type))
                }
            }
            groupWaitResponseHttp.leave()
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func sendMessage(contactID: Int, text: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("users/by_telephone/" + contacts[contactID].telephone, [:], "GET") { [self] httpStatus,responseJSON in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            let responseJSON = responseJSON as? [String:Any]
            if status == 200 {
                sendMessageToDB(contactID: responseJSON?["id"] as! String, text: text){ statusNew, answerOnRequestNew in
                    status = statusNew; answerOnRequest = answerOnRequestNew
                    groupWaitResponseHttp.leave()
                }
            }
            else { groupWaitResponseHttp.leave() }
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func sendMessageToDB(contactID: String, text: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()){
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("messages", ["text":text, "fromUserID": myUser!.id ?? "", "toUserID": contactID], "POST") { [self] httpStatus,responseJSON in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            let responseJSON = responseJSON as? [String:Any]
            if status == 200 {
                messages.append(Message(id: responseJSON?["id"] as! String, text: text, delivered: false, contactID: contactID, createdAt: isodateFromString(responseJSON?["createdAt"] as! String), type: .outgoing))
            }
            groupWaitResponseHttp.leave()
    
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func getLastMessageContacts(contactID: Int, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()){
        var answerOnRequest: String?
        var status: Int?
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("users/by_telephone/" + contacts[contactID].telephone, [:], "GET") { [self] httpStatus,responseJSON in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            let responseJSON = responseJSON as? [String:Any]
            if status == 200 {
                getLastMessageContactsFromDB(group: groupWaitResponseHttp, contactID: responseJSON?["id"] as! String){ statusNew, answerOnRequestNew in
                    status = statusNew; answerOnRequest = answerOnRequestNew
                }
            }
            else if status == 404 {
                answerOnRequest = "Контакт не зарегистрирован в системе!"
                groupWaitResponseHttp.leave()
            }
        }
        groupWaitResponseHttp.notify(qos: .userInteractive, queue: .main) {
            completion(status, answerOnRequest)
        }
    }
    
    func getLastMessageContactsFromDB(group: DispatchGroup, contactID: String, _ completion: @escaping (_ statusNew: Int?, _ answerOnRequestNew: String?) -> ()) {
        var answerOnRequest: String?
        var status: Int?
        sql.sendRequest("messages/last_between_users?userID=" + (myUser?.id ?? "") + "&contactID=" + contactID + "&delivered=all", [:], "GET") { [self] httpStatus,responseJSON in
            status = httpStatus?.statusCode
            answerOnRequest = sql.answerOnRequestError(statusCode: status)
            let responseJSON = responseJSON as? [String:Any]
            if status == 200 {
                let toUser = (responseJSON!["toUser"] as! Dictionary<String, String>)["id"]
                let type = toUser == (myUser?.id ?? "") ? MessageType.incomming : MessageType.outgoing
                messages.append(Message(id: responseJSON?["id"] as! String, text: responseJSON?["text"] as! String, delivered: responseJSON?["delivered"] as! Bool, contactID: contactID, createdAt: isodateFromString(responseJSON?["createdAt"] as! String), type: type))
            }
            else if status == 404 {
                answerOnRequest = "У контакта нет сообщений!"
            }
            completion(status, answerOnRequest)
            group.leave()
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
