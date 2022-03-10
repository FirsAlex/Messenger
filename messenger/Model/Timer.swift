//
//  File.swift
//  messenger
//
//  Created by Alexander Firsov on 10.03.2022.
//

import Foundation

class MyTimer {
    var timer: Timer?
    
    func start(_ completion: @escaping() -> Void) -> Void {
        self.timer =
           Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true){_ in
               completion()
           }
        self.timer!.fire()
    }
    func stop() -> Void {
        self.timer?.invalidate()
        self.timer = nil
    }
}
