//
//  SqlRequest.swift
//  messenger
//
//  Created by Alexander Firsov on 18.02.2022.
//

import Foundation
import UIKit

protocol SqlRequestProtocol {
    func answerOnRequestError(statusCode: Int?) -> String?
    func sendRequest(_ myUrlRoute: String, _ json: [String: Any], _ httpMethod: String,
                     _ completion: @escaping ( _ httpStatus: HTTPURLResponse?, _ responseJSON: Any?) -> Void)
}

class SqlRequest: SqlRequestProtocol{
    init() {
    }
    
    func sendRequest(_ myUrlRoute: String = "", _ json: [String: Any] = [:], _ httpMethod: String,
                     _ completion: @escaping ( _ httpStatus: HTTPURLResponse?, _ responseJSON: Any?) -> Void) {
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
                completion(httpStatus, responseJSON)
                return
            }
            
            httpStatus = response as? HTTPURLResponse
            responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            completion(httpStatus, responseJSON)
        }
        task.resume()
    }
    
    func answerOnRequestError(statusCode: Int?) -> String? {
        if statusCode == 502 {
            return "Нет связи с сервером 502 Bad Gateway!"
        }
        else if statusCode == nil {
            return "Сервер не ответил на запрос!"
        }
        else if statusCode == 400 {
            return "Неправильный параметр в строке запроса!"
        }
        else if statusCode == 500 {
            return "Нарушение уникальности поля, такой телефон уже существует у аккаунта!"
        }
        else {return nil}
    }
}
