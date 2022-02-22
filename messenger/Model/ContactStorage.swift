//
//  Contact.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import Foundation

protocol ContactStorageProtocol {
    func loadContactsFromDB()
    func saveContacts(_ contacts: [UserProtocol])
    
    func loadMyUser()
    func getMyUserFromDB(group: DispatchGroup, telephone: String, name: String)
    func patchMyUserFromDB(group: DispatchGroup, telephone: String, name: String)
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
        loadContactsFromDB()
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
    
    func getMyUserFromDB(group: DispatchGroup, telephone: String, name: String){
        //GET
        sql.sendRequest("users/by_telephone/" + telephone, [:], "GET") { [self] in
            let responseJSON = sql.responseJSON as? [String:String]
            if sql.httpStatus?.statusCode == 502 {
                self.sql.answerOnRequest = "Нет связи с сервером 502 Bad Gateway!"
                group.leave()
            }
            else if sql.httpStatus?.statusCode == 200 {
                myUser = User(id: responseJSON?["id"], telephone: telephone,
                                      name: (responseJSON?["name"] ?? ""))
                loadContactsFromDB()
                sql.answerOnRequest = "Найден аккаунт в БД с таким же номером телефона!"
                group.leave()
            }
            else if sql.httpStatus?.statusCode == nil {
                sql.answerOnRequest = "Сервер не ответил на запрос!"
                group.leave()
            }
            //POST
            else if sql.httpStatus?.statusCode == 404 {
                sql.sendRequest("users", ["name":name, "telephone":telephone], "POST") {
                    if sql.httpStatus?.statusCode == 200 {
                        myUser = User(id: responseJSON?["id"], telephone: telephone, name: name)
                        loadContactsFromDB()
                        sql.answerOnRequest = "Новый аккаунт сохранён!"
                    }
                    else { sql.answerOnRequest = "Новый аккаунт не сохранён!" }
                    group.leave()
                }
            }
        }
    }
    
    func patchMyUserFromDB(group: DispatchGroup, telephone: String, name: String) {
        //PATCH
        sql.sendRequest("users/"+(myUser!.id ?? ""), ["name":name, "telephone":telephone], "PATCH"){ [self] in
            if sql.httpStatus?.statusCode == 200 {
                myUser?.name = name
                myUser?.telephone = telephone
                sql.answerOnRequest = "Аккаунт обновлён!"
            }
            else if sql.httpStatus?.statusCode == 502 {
                sql.answerOnRequest = "Нет связи с сервером 502 Bad Gateway!"
            }
            else {
                sql.answerOnRequest = "Не удалось обновить запись в таблице пользователей!"
            }
            group.leave()
        }
    }
    
    func loadContactsFromDB() {
        let group = DispatchGroup()
        group.enter()
        sql.sendRequest("contacts/by_user/" + (myUser?.id ?? ""), [:], "GET") {
            group.leave()
        }
        group.notify(qos: .background, queue: .main) { [self] in
            let responseJSON = sql.responseJSON as? [[String:Any]] ?? []
            for contact in responseJSON {
                contacts.append(User(id: contact["id"] as? String, telephone: (contact["telephone"] as? String ?? ""),
                                     name: (contact["name"] as? String ?? "")))
            }
        }
    }
    
    func saveContacts(_ contacts: [UserProtocol]) {
    }
}
