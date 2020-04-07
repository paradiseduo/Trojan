//
//  Trojan.swift
//  TrojanMac
//
//  Created by ParadiseDuo on 2020/4/7.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Foundation

class Trojan {
    let trojan = Bundle.main.path(forResource: "trojan", ofType: nil)
    static let shared = Trojan()
    
    private var task: Process?
    
    func start() {
        if let t = self.task, t.isRunning {
            return
        }
        NotificationCenter.default.post(name: TROJAN_START, object: nil)
        self.task = Process()
        CommandLine.async(task: self.task!, shellPath: self.trojan!, arguments: Profile.shared.arguments()) { (finish) in
            print("Trojan turn off!")
            NotificationCenter.default.post(name: TROJAN_STOP, object: nil)
        }
    }
    
    func stop() {
        if let t = self.task {
            t.terminate()
        }
        self.task = nil
    }
}
