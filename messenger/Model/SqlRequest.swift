//
//  SqlRequest.swift
//  messenger
//
//  Created by Alexander Firsov on 18.02.2022.
//

import Foundation
import UIKit

protocol SqlRequestProtocol {
    func answerOnRequestError(group: DispatchGroup, statusCode: Int?,_ completion: (Int?, String) -> ())
    func sendRequest(_ myUrlRoute: String, _ json: [String: Any], _ httpMethod: String,
                     _ completion: @escaping ( _ httpStatus: HTTPURLResponse?, _ responseJSON: Any?) -> Void) -> Void
}

class SqlRequest: SqlRequestProtocol{
    init() {
    }
    
    func sendRequest(_ myUrlRoute: String = "", _ json: [String: Any] = [:], _ httpMethod: String,
                     _ completion: @escaping ( _ httpStatus: HTTPURLResponse?, _ responseJSON: Any?) -> Void) -> Void {
        var httpStatus: HTTPURLResponse?
        var responseJSON: Any?
        // create request
        let url = URL(string: "https://server.firsalex.keenetic.name/\(myUrlRoute)")!
        var request = URLRequest(url: url)
        
        request.httpMethod = httpMethod
        if httpMethod == "POST" || httpMethod == "PATCH" {
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // insert json data to the request
            request.httpBody = jsonData
        }
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) -> Void in
            //print("Answer in request: \(String(describing: response))")
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            
            httpStatus = response as? HTTPURLResponse
            responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            completion(httpStatus, responseJSON)
        }
        task.resume()
    }
    
    func answerOnRequestError(group: DispatchGroup, statusCode: Int?,_ completion: (Int?, String) -> ()) {
        if statusCode == 502 {
            completion(statusCode, "Нет связи с сервером 502 Bad Gateway!")
            group.leave()
        }
        else if statusCode == nil {
            completion(statusCode, "Сервер не ответил на запрос!")
            group.leave()
        }
        else if statusCode == 400 {
            completion(statusCode, "Неправильный параметр в строке запроса!")
            group.leave()
        }
        else if statusCode == 500 {
            completion(statusCode, "Нарушение уникальности поля, такой телефон уже существует у аккаунта!")
            group.leave()
        }
    }
}
