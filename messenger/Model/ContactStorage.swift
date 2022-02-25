//
//  Contact.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import Foundation

protocol ContactStorageProtocol {
    func loadContactsFromDB(group: DispatchGroup)
    func saveContacts(_ contacts: [UserProtocol])
    
    func loadMyUser()
    func saveMyUser(_ user: UserProtocol)
    
    func getMyUserFromDB(group: DispatchGroup, telephone: String, name: String)
    func postMyUserToDB(group: DispatchGroup, telephone: String, name: String)
    func patchMyUserFromDB(group: DispatchGroup, telephone: String, name: String)
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
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                myUser = User(id: responseJSON?["id"], telephone: telephone, name: (responseJSON?["name"] ?? ""))
                sql.answerOnRequest = "Найден аккаунт в БД с таким же номером телефона!" + "\nИмя: \(myUser?.name ?? "")" + "\nТелефон: \(myUser?.telephone ?? "")"
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
    
    func loadContactsFromDB(group: DispatchGroup) {
        sql.sendRequest("contacts/by_user/" + (myUser?.id ?? ""), [:], "GET") { [self] in
            let responseJSON = sql.responseJSON as? [[String:Any]] ?? []
            sql.answerOnRequestError(group: group, statusCode: sql.httpStatus?.statusCode)
            if sql.httpStatus?.statusCode == 200 {
                for contact in responseJSON {
                    contacts.append(User(id: contact["id"] as? String, telephone: (contact["telephone"] as? String ?? ""),
                                         name: (contact["name"] as? String ?? "")))
                }
                print("Контакты загружены!")
                print(sql.answerOnRequest)
                sql.answerOnRequest = "\(sql.answerOnRequest ?? "")" + "\nКонтакты аккаунта загружены!"
                print(sql.answerOnRequest)
                group.leave()
            }
        }
    }
    
    func saveContacts(_ contacts: [UserProtocol]) {
    }
}
