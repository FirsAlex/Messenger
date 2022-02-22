//
//  Contact.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import Foundation

protocol ContactStorageProtocol {
    func loadContacts()
    func saveContacts(_ contacts: [UserProtocol])
    
    func loadMyUser()
    func saveMyUser(_ user: UserProtocol)
}

class ContactStorage: ContactStorageProtocol {
    static let shared = ContactStorage()
    let sql = SqlRequest()
    
    var contacts: [UserProtocol] = []
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
        loadMyUser()
        loadContacts()
    }
    
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
    
    func loadContacts() {
        let groupWaitResponseHttp = DispatchGroup()
        groupWaitResponseHttp.enter()
        sql.sendRequest("contacts/by_user/" + (myUser?.id ?? ""), [:], "GET") {[self] in
            
            if sql.httpStatus?.statusCode == 502 {
                sql.answerOnRequest = "Нет связи с сервером 502 Bad Gateway!"
            }
            else if sql.httpStatus?.statusCode == nil {
                sql.answerOnRequest = "Сервер не ответил на запрос!"
            }
            else if sql.httpStatus?.statusCode == 200 {
                sql.answerOnRequest = "Сервер ответил на запрос контактов по пользователю!"
            }
            groupWaitResponseHttp.leave()
        }

        groupWaitResponseHttp.notify(qos: .background, queue: .main) { [self] in
            let responseJSON = sql.responseJSON as? [[String:Any]] ?? []
            print(responseJSON)
            responseJSON.map {
                contacts.append(User(id: $0["id"] as? String, telephone: ($0["telephone"] as? String ?? ""),
                                     name: ($0["name"] as? String ?? "")))
            }
        }
    }
    
    func saveContacts(_ contacts: [UserProtocol]) {
       /* var arrayForStorage: [[String:String]] = []
        tasks.forEach { task in
            var newElementForStorage: Dictionary<String, String> = [:]
            newElementForStorage[TaskKey.title.rawValue] = task.title
            newElementForStorage[TaskKey.type.rawValue] = (task.type == .important) ? "important" : "normal"
            newElementForStorage[TaskKey.status.rawValue] = (task.status == .planned) ? "planned" : "completed"
            arrayForStorage.append(newElementForStorage)
        }
        storage.set(arrayForStorage, forKey: storageKey)*/
    }
}
