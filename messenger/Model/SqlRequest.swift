//
//  SqlRequest.swift
//  messenger
//
//  Created by Alexander Firsov on 18.02.2022.
//

import Foundation
import UIKit

protocol SqlRequestProtocol {
    var responseJSON: Any? { get set }
    var httpStatus: HTTPURLResponse? { get set }
    var answerOnRequest: String? { get set }
    func sendRequest(_ myUrlRoute: String, _ json: [String: Any], _ httpMethod: String,
                     _ completion: @escaping () -> Void)
}

class SqlRequest: SqlRequestProtocol{
    var httpStatus: HTTPURLResponse?
    var answerOnRequest: String?
    var responseJSON: Any?
    
    init() {
    }
    
    func sendRequest(_ myUrlRoute: String = "", _ json: [String: Any] = [:], _ httpMethod: String,
                     _ completion: @escaping () -> Void) {
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
            data, response, error in
            print("Answer in request: \(String(describing: response))")
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                completion()
                return
            }
            
            self.httpStatus = response as? HTTPURLResponse
            self.responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            completion()
        }
        task.resume()
    }
}
