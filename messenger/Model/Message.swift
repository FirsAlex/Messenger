//
//  Message.swift
//  messenger
//
//  Created by Alexander Firsov on 07.03.2022.
//

import Foundation

enum MessageType {
    case outgoing
    case incomming
}

protocol MessageProtocol {
    var id: String { get set }
    var text: String { get set }
    var delivered: Bool { get set }
    var contactID: String { get set }
    var createdAt: String { get set }
    var type: MessageType { get set }
}

struct Message: MessageProtocol {
    var id: String
    var text: String
    var delivered: Bool
    var contactID: String
    var createdAt: String
    var type: MessageType
}
