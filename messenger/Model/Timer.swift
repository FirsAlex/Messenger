//
//  File.swift
//  messenger
//
//  Created by Alexander Firsov on 10.03.2022.
//

import Foundation

class MyTimer {
    weak var timer: Timer?
    
    func start(interval: Double, _ completion: @escaping() -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true){ timer in
            completion()
        }
        //работа Timer при взаимодействии с интерфейсом
        RunLoop.current.add(timer!, forMode: .common)
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
