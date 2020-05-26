//
//  AppDelegate.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/4/7.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    static func getLauncherStatus() -> Bool {
        return LoginServiceKit.isExistLoginItems()
    }
    
    static func setLauncherStatus(open: Bool) {
        if open {
            LoginServiceKit.addLoginItems()
        } else {
            LoginServiceKit.removeLoginItems()
        }
    }
    
    static func stopTrojan(finish: @escaping()->()) {
        StopTrojan { (s) in
            StopPrivoxy { (ss) in
                ProxyConfHelper.stopPACServer()
                ProxyConfHelper.disableProxy("hi")
                let defaults = UserDefaults.standard
                defaults.set(false, forKey: USERDEFAULTS_TROJAN_ON)
                defaults.synchronize()
                DispatchQueue.main.async {
                    finish()
                }
            }
        }
    }
}


