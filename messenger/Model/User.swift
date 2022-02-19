//
//  User.swift
//  messenger
//
//  Created by Alexander Firsov on 08.02.2022.
//

import Foundation

protocol UserProtocol {
    var id: String? { get set }
    var telephone: String { get set }
    var name: String { get set }
}

struct User: UserProtocol {
    var id: String?
    var telephone: String
    var name: String
}
