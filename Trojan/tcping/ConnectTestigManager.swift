//
//  ConnectTestigManager.swift
//  Trojan
//
//  Created by YouShaoduo on 2020/10/9.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Foundation

var isTesting:Bool = false
var nerverTestBefore = true

class ConnectTestigManager {
    static let shared = ConnectTestigManager()
    
    private var tcping: Tcping?
    
    func start() {
        if !isTesting {
            isTesting = true
            self.tcping = Tcping()
            self.tcping!.ping {
                isTesting = false
                NotificationCenter.default.post(name: NOTIFY_REFRESH_SERVERS, object: nil)
                self.tcping = nil
            }
        }
    }
}

extension NumberFormatter {
    static func three(_ number: NSNumber) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 3
        
        return nf.string(from: number) ?? "failed"
    }
}
