//
//  AppDelegate.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/4/7.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if UserDefaults.standard.bool(forKey: USERDEFAULTS_TROJAN_ON) {
            Trojan.shared.start()
        }
        
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == LAUNCHER_APPID }.isEmpty
        if isRunning {
            DistributedNotificationCenter.default().post(name: KILL_LAUNCHER, object: Bundle.main.bundleIdentifier!)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    static func getLauncherStatus() -> Bool {
        let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]]
        let autoLaunchRegistered = jobs?.contains(where: { $0["Label"] as! String == LAUNCHER_APPID }) ?? false
        
        UserDefaults.standard.set(autoLaunchRegistered, forKey: USERDEFAULTS_LAUNCH_AT_LOGIN)
        UserDefaults.standard.synchronize()
        
        return autoLaunchRegistered
    }
    
    static func setLauncherStatus(open: Bool) {
        SMLoginItemSetEnabled(LAUNCHER_APPID as CFString, open)
    }
}


