//
//  AppDelegate.swift
//  StartAtLoginLauncher
//
//  Created by ParadiseDuo on 2020/4/7.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let mainAppIdentifier = "MacOS.Trojan"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty
            
        if !isRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(terminate), name: Notification.Name("MacOS_Trojan_KILL_LAUNCHER"), object: mainAppIdentifier)
                
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast(3)
            components.append("MacOS")
            components.append("Trojan") //main app name
                
            let newPath = NSString.path(withComponents: components)
            NSWorkspace.shared.launchApplication(newPath)
        } else {
            self.terminate()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }


}

