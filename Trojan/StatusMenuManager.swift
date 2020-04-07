//
//  StatusMenuManager.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/3/31.
//  Copyright © 2020 Mac. All rights reserved.
//

import Cocoa

class StatusMenuManager: NSObject {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var switchLabel: NSMenuItem!
    @IBOutlet weak var toggleRunning: NSMenuItem!
    @IBOutlet weak var launchItem: NSMenuItem!
    @IBOutlet weak var copyCommandItem: NSMenuItem!
    
    var settingW: SettingWindowController!
    var logW: LogWindowController!
    var toastW: ToastWindowController!
    
    override func awakeFromNib() {
        Profiles.shared.load()
        Profile.shared.loadProfile()
        updateMainMenu()
        NotificationCenter.default.addObserver(forName: TROJAN_START, object: nil, queue: OperationQueue.main) { (noti) in
            if !UserDefaults.standard.bool(forKey: USERDEFAULTS_TROJAN_ON) {
                UserDefaults.standard.set(true, forKey: USERDEFAULTS_TROJAN_ON)
                UserDefaults.standard.synchronize()
                self.updateMainMenu()
            }
        }
        NotificationCenter.default.addObserver(forName: TROJAN_STOP, object: nil, queue: OperationQueue.main) { (noti) in
            if UserDefaults.standard.bool(forKey: USERDEFAULTS_TROJAN_ON) {
                UserDefaults.standard.set(false, forKey: USERDEFAULTS_TROJAN_ON)
                UserDefaults.standard.synchronize()
                self.updateMainMenu()
            }
        }
    }
    
    func updateMainMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: USERDEFAULTS_TROJAN_ON)
        if isOn {
            switchLabel.title = "Trojan: On"
            switchLabel.image = NSImage(named: NSImage.statusAvailableName)
            toggleRunning.title = "Turn Trojan Off"
            
            let icon = NSImage(named: "open")
            statusItem.button?.image = icon
            statusItem.menu = statusMenu
            copyCommandItem.isHidden = false
        } else {
            switchLabel.title = "Trojan: Off"
            switchLabel.image = NSImage(named: NSImage.statusUnavailableName)
            toggleRunning.title = "Turn Trojan On"
            
            let icon = NSImage(named: "close")
            statusItem.button?.image = icon
            statusItem.menu = statusMenu
            copyCommandItem.isHidden = true
            
        }
        self.launchItem.state = NSControl.StateValue(rawValue: AppDelegate.getLauncherStatus() ? 1 : 0)
    }
    
    @IBAction func powerSwitch(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: USERDEFAULTS_TROJAN_ON)
        if isOn {
            defaults.set(false, forKey: USERDEFAULTS_TROJAN_ON)
            Trojan.shared.stop()
            self.makeToast("Trojan OFF")
        } else {
            defaults.set(true, forKey: USERDEFAULTS_TROJAN_ON)
            Trojan.shared.start()
            self.makeToast("Trojan ON")
        }
        defaults.synchronize()
        updateMainMenu()
    }
    
    @IBAction func quit(_ sender: NSMenuItem) {
        Trojan.shared.stop()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5) {
            NSApplication.shared.terminate(self)
        }
    }
    
    @IBAction func showLog(_ sender: NSMenuItem) {
        if self.logW != nil {
            self.logW.close()
        }
        let c = LogWindowController(windowNibName: "LogWindowController")
        self.logW = c
        c.showWindow(self)
        c.window?.center()
        c.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func cleanLogs(_ sender: NSMenuItem) {
        CommandLine.async(task: Process(), command: "rm -rf \(LOG_PATH)") { (finish) in
            print("CleanLog finish")
            NotificationCenter.default.post(name: LOG_CLEAN_FINISH, object: nil)
            self.makeToast("Logs Cleand")
        }
    }
    
    
    @IBAction func setting(_ sender: NSMenuItem) {
        if self.settingW != nil {
            self.settingW.close()
        }
        let c = SettingWindowController(windowNibName: "SettingWindowController")
        self.settingW = c
        c.showWindow(self)
        c.window?.center()
        c.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func checkUpdate(_ sender: NSMenuItem) {
        let versionChecker = VersionChecker()
        DispatchQueue.global().async {
            let newVersion = versionChecker.checkNewVersion()
            DispatchQueue.main.async {
                let alertResult = versionChecker.showAlertView(Title: newVersion["Title"] as! String, SubTitle: newVersion["SubTitle"] as! String, ConfirmBtn: newVersion["ConfirmBtn"] as! String, CancelBtn: newVersion["CancelBtn"] as! String)
                if (newVersion["newVersion"] as! Bool && alertResult == 1000){
                    NSWorkspace.shared.open(URL(string: RELEASE_URL)!)
                }
            }
        }
    }
    
    @IBAction func launchAtLogin(_ sender: NSMenuItem) {
        if UserDefaults.standard.bool(forKey: USERDEFAULTS_LAUNCH_AT_LOGIN) {
            AppDelegate.setLauncherStatus(open: false)
        } else {
            AppDelegate.setLauncherStatus(open: true)
        }
        self.updateMainMenu()
    }
    
    @IBAction func feedbackTap(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: ISSUES_URL)!)
    }
    
    @IBAction func aboutMe(_ sender: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel(sender);
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func copyCommandLineTap(_ sender: NSMenuItem) {
        Profile.shared.loadProfile()

        let command = "export ALL_PROXY=socks5://\(Profile.shared.client.local_addr):\(Profile.shared.client.local_port);export no_proxy=localhost;"

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: NSPasteboard.PasteboardType.string)

        self.makeToast("Export Command Copied.")
    }
    
    func makeToast(_ message: String) {
        if self.toastW != nil {
            self.toastW.close()
        }
        let c = ToastWindowController.init(windowNibName: "ToastWindowController")
        self.toastW = c
        c.message = message
        c.showWindow(self)
        c.fadeInHud()
    }
}
