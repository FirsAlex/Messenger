//
//  File.swift
//  messenger
//
//  Created by Alexander Firsov on 10.03.2022.
//

import Foundation

class MyTimer {
    weak var timer: Timer?
    
    func start(_ completion: @escaping() -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true){ timer in
            completion()
        }
        //RunLoop.current.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        print("deinit MyTimer")
    }
}
