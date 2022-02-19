//
//  Contact.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import Foundation

protocol ContactStorageProtocol {
    func loadContacts() -> [UserProtocol]?
    func saveContacts(_ contacts: [UserProtocol])
    
    func loadMyUser() -> UserProtocol?
    func saveMyUser(_ user: UserProtocol)
}

class ContactStorage: ContactStorageProtocol {
    static let shared = ContactStorage()
    
    var contacts: [UserProtocol]?
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
        contacts = loadContacts() ?? []
        myUser = loadMyUser()
    }
    
    func saveMyUser(_ user: UserProtocol) {
        var newElementForStorage: Dictionary<String, String> = [:]
        newElementForStorage["telephone"] = user.telephone
        newElementForStorage["name"] = user.name
        newElementForStorage["id"] = user.id
        storageMyUser.set(newElementForStorage, forKey: storageMyUserKey)
    }
    
    func loadMyUser() -> UserProtocol? {
        let myUserFromStorage = storageMyUser.dictionary(forKey: storageMyUserKey) as? [String : String] ?? [:]
        let id = myUserFromStorage["id"]
        guard let telephone = myUserFromStorage["telephone"],
              let name = myUserFromStorage["name"] else { return nil}
        return User(id: id, telephone: telephone, name: name)
    }
    
    func loadContacts() -> [UserProtocol]? {
        let result = [User(telephone: "123", name: "Name1"), User(telephone: "321", name: "Name2")]
        /*  var resultTasks: [TaskProtocol] = []
        let tasksFromStorage = storage.array(forKey: storageKey) as? [[String:String]] ?? []
        for task in tasksFromStorage {
            guard let title = task[TaskKey.title.rawValue],
                  let typeRaw = task[TaskKey.type.rawValue],
                  let statusRaw = task[TaskKey.status.rawValue] else { continue }
            let type: TaskPriority = typeRaw == "important" ? .important : .normal
            let status: TaskStatus = statusRaw == "planned" ? .planned : .completed
            resultTasks.append(Task(title: title, type: type, status: status))
        }
        return resultTasks*/
        return result
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
