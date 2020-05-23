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
        if UserDefaults.standard.bool(forKey: USERDEFAULTS_TROJAN_ON) {
            Trojan.shared.start()
        }
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
}


