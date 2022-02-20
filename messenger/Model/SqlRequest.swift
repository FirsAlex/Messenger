//
//  SqlRequest.swift
//  messenger
//
//  Created by Alexander Firsov on 18.02.2022.
//

import Foundation

protocol SqlRequestProtocol {
    func sendRequest(myUrlRoute: String, json: [String: Any], httpMethod: String,
                     completion: @escaping ([String:Any]?, URLResponse?) -> Void)
}

class SqlRequest: SqlRequestProtocol{
    init() {
    }
    
    func sendRequest(myUrlRoute: String = "", json: [String: Any] = [:], httpMethod: String,
                     completion: @escaping ([String:Any]?, URLResponse?) -> Void) {
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
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            let responseJSONdecode = responseJSON as? [String:Any]
            completion(responseJSONdecode, response)
        }
        task.resume()
    }
}
