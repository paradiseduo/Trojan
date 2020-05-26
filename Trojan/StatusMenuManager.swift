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
    @IBOutlet weak var copyCommandItem: NSMenuItem!
    
    @IBOutlet weak var pacItem: NSMenuItem!
    @IBOutlet weak var whiteListItem: NSMenuItem!
    @IBOutlet weak var globalItem: NSMenuItem!
    @IBOutlet weak var manualItem: NSMenuItem!
    @IBOutlet weak var aclAutoItem: NSMenuItem!
    @IBOutlet weak var backChinaItem: NSMenuItem!
    @IBOutlet weak var aclModeItem: NSMenuItem!
    
    var settingW: SettingWindowController!
    var settingsW: SettingsWIndowController!
    var logW: LogWindowController!
    var toastW: ToastWindowController!
    
    override func awakeFromNib() {
        updateApplicationConfig()
        
        NotificationCenter.default.addObserver(forName: NOTIFY_HTTP_CONF_CHANGED, object: nil, queue: OperationQueue.main) { (noti) in
            SyncPrivoxy {
                StatusMenuManager.applyConfig { (s) in
                    self.refresh()
                }
            }
        }
        NotificationCenter.default.addObserver(forName: NOTIFY_UPDATE_RUNNING_MODE_MENU, object: nil, queue: OperationQueue.main) { (noti) in
            self.updateRunningModeMenu()
        }
        NotificationCenter.default.addObserver(forName: NOTIFY_SERVER_PROFILES_CHANGED, object: nil, queue: OperationQueue.main) { (noti) in
            if Profiles.shared.count() > 0 {
                if !UserDefaults.standard.bool(forKey: USERDEFAULTS_TROJAN_ON) {
                    self.toggle { (suc) in
                        self.refresh()
                    }
                } else {
                    SyncTrojan { (s) in
                        self.refresh()
                    }
                }
            }
        }
    }
    
    private func updateApplicationConfig() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            USERDEFAULTS_RUNNING_MODE: "auto",
            USERDEFAULTS_LOCAL_SOCKS5_LISTEN_ADDRESS: "127.0.0.1",
            USERDEFAULTS_LOCAL_SOCKS5_LISTEN_PORT: NSNumber(value: 10800 as UInt16),
            USERDEFAULTS_LOCAL_HTTP_LISTEN_ADDRESS: "127.0.0.1",
            USERDEFAULTS_LOCAL_HTTP_LISTEN_PORT: NSNumber(value: 10801 as UInt16),
            USERDEFAULTS_PAC_SERVER_LISTEN_ADDRESS: "127.0.0.1",
            USERDEFAULTS_PAC_SERVER_LISTEN_PORT:NSNumber(value: 8090 as UInt16),
            USERDEFAULTS_GFW_LIST_URL: "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt",
            USERDEFAULTS_ACL_WHITE_LIST_URL: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/banAD.acl",
            USERDEFAULTS_ACL_AUTO_LIST_URL: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/gfwlist-banAD.acl",
            USERDEFAULTS_ACL_PROXY_BACK_CHN_URL:"https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/backcn-banAD.acl",
            USERDEFAULTS_AUTO_CONFIGURE_NETWORK_SERVICES: NSNumber(value: true as Bool),
            USERDEFAULTS_LOCAL_HTTP_ON: true,
            USERDEFAULTS_LOCAL_HTTP_FOLLOW_GLOBAL: true,
            USERDEFAULTS_ACL_FILE_NAME: "chn.acl",
            USERDEFAULTS_AUTO_CHECK_UPDATE:false
        ])
        
        let fileMgr = FileManager.default
        if fileMgr.fileExists(atPath: CONFIG_PATH_OLD) {
            do {
                try fileMgr.moveItem(atPath: CONFIG_PATH_OLD, toPath: CONFIG_PATH)
            } catch {
                
            }
        }
        Profiles.shared.load()
        InstallTrojanLocal { (s) in
            InstallPrivoxy { (suc) in
                ProxyConfHelper.install()
                SyncPac()

                StatusMenuManager.applyConfig { (s) in
                    self.refresh()
                }
                
                if UserDefaults.standard.bool(forKey: USERDEFAULTS_AUTO_CHECK_UPDATE) {
                    self.checkUpdate(showAlert: false)
                }
            }
        }
    }
    
    private func refresh() {
        DispatchQueue.main.async {
            self.updateMainMenu()
            self.updateRunningModeMenu()
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
            if Profiles.shared.count() > 0 {
                copyCommandItem.isHidden = false
            }
        } else {
            switchLabel.title = "Trojan: Off"
            switchLabel.image = NSImage(named: NSImage.statusUnavailableName)
            toggleRunning.title = "Turn Trojan On"
            
            let icon = NSImage(named: "close")
            statusItem.button?.image = icon
            statusItem.menu = statusMenu
            copyCommandItem.isHidden = true
        }
    }
    
    @IBAction func powerSwitch(_ sender: NSMenuItem) {
        self.toggle { (s) in
            self.updateMainMenu()
        }
    }
    
    private func toggle(finish: @escaping(_ success: Bool)->()) {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: USERDEFAULTS_TROJAN_ON)
        if isOn {
            defaults.set(false, forKey: USERDEFAULTS_TROJAN_ON)
            self.makeToast("Trojan OFF")
        } else {
            defaults.set(true, forKey: USERDEFAULTS_TROJAN_ON)
            self.makeToast("Trojan ON")
        }
        defaults.synchronize()
        StatusMenuManager.applyConfig { (suc) in
            SyncTrojan { (s) in
                DispatchQueue.main.async {
                    finish(true)
                }
            }
        }
    }
    
    @IBAction func quit(_ sender: NSMenuItem) {
        AppDelegate.stopTrojan {
            if AppDelegate.getLauncherStatus() == false {
                RemovePrivoxy { (s) in
                    RemoveTrojan { (ss) in
                        NSApplication.shared.terminate(self)
                    }
                }
            } else {
                NSApplication.shared.terminate(self)
            }
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
    
    @IBAction func serversSetting(_ sender: NSMenuItem) {
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
        self.checkUpdate(showAlert: true)
    }
    
    @IBAction func settingsTap(_ sender: NSMenuItem) {
        if self.settingsW != nil {
            self.settingsW.close()
        }
        let c = SettingsWIndowController(windowNibName: "SettingsWIndowController")
        self.settingsW = c
        c.showWindow(self)
        c.window?.center()
        c.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func checkUpdate(showAlert: Bool) {
        let versionChecker = VersionChecker()
        DispatchQueue.global().async {
            let newVersion = versionChecker.checkNewVersion()
            DispatchQueue.main.async {
                if (showAlert || newVersion["newVersion"] as! Bool){
                    let alertResult = versionChecker.showAlertView(Title: newVersion["Title"] as! String, SubTitle: newVersion["SubTitle"] as! String, ConfirmBtn: newVersion["ConfirmBtn"] as! String, CancelBtn: newVersion["CancelBtn"] as! String)
                    if (newVersion["newVersion"] as! Bool && alertResult == 1000){
                        NSWorkspace.shared.open(URL(string: RELEASE_URL)!)
                    }
                }
            }
        }
    }
    
    @IBAction func feedbackTap(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: ISSUES_URL)!)
    }
    
    @IBAction func aboutMe(_ sender: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel(sender);
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func copySocks5CommandLineTap(_ sender: NSMenuItem) {
        // Get the Http proxy config.
        let defaults = UserDefaults.standard
        let address = defaults.string(forKey: USERDEFAULTS_LOCAL_SOCKS5_LISTEN_ADDRESS)
        let port = defaults.integer(forKey: USERDEFAULTS_LOCAL_SOCKS5_LISTEN_PORT)
        let httpAddress = defaults.string(forKey: USERDEFAULTS_LOCAL_HTTP_LISTEN_ADDRESS)
        let httpPort = defaults.integer(forKey: USERDEFAULTS_LOCAL_HTTP_LISTEN_PORT)
        
        if defaults.bool(forKey: USERDEFAULTS_LOCAL_HTTP_ON) {
            if let a = httpAddress {
                let command = "export http_proxy=http://\(a):\(httpPort);export https_proxy=http://\(a):\(httpPort);"
                
                // Copy to paste board.
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: NSPasteboard.PasteboardType.string)
                
                // Show a toast notification.
                self.makeToast("Export Command Copied.")
            } else {
                self.makeToast("Export Command Copied Failed.")
            }
        } else {
            if let a = address {
                let command = "export ALL_PROXY=socks5://\(a):\(port);export no_proxy=localhost;"
                // Copy to paste board.
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: NSPasteboard.PasteboardType.string)
                
                // Show a toast notification.
                self.makeToast("Export Command Copied.")
            } else {
                self.makeToast("Export Command Copied Failed.")
            }
        }
    }
    
    @IBAction func pacMode(_ sender: NSMenuItem) {
        Mode.switchTo(.PAC)
    }
    
    @IBAction func WhiteListMode(_ sender: NSMenuItem) {
        Mode.switchTo(.WHITELIST)
    }
    
    @IBAction func globalMode(_ sender: NSMenuItem) {
        Mode.switchTo(.GLOBAL)
    }
    
    @IBAction func manualMode(_ sender: NSMenuItem) {
        Mode.switchTo(.MANUAL)
    }
    
    @IBAction func aclAutoMode(_ sender: NSMenuItem) {
        Mode.switchTo(.ACLAUTO)
    }
    
    @IBAction func backChinaMode(_ sender: NSMenuItem) {
        Mode.switchTo(.CHINA)
    }

    static func applyConfig(finish: @escaping(_ success: Bool)->()) {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: USERDEFAULTS_TROJAN_ON)
        let mode = defaults.string(forKey: USERDEFAULTS_RUNNING_MODE)
        
        if isOn {
            StartTrojan { (s) in
                if s {
                    StartPrivoxy { (ss) in
                        if ss {
                            if mode == "auto" {
                                ProxyConfHelper.disableProxy("hi")
                                ProxyConfHelper.enablePACProxy("hi")
                            } else if mode == "global" {
                                ProxyConfHelper.disableProxy("hi")
                                ProxyConfHelper.enableGlobalProxy()
                            } else if mode == "manual" {
                                ProxyConfHelper.disableProxy("hi")
                            } else if mode == "whiteList" {
                                ProxyConfHelper.disableProxy("hi")
                                ProxyConfHelper.enableWhiteListProxy()//新白名单基于GlobalMode
                            }
                            finish(true)
                        } else {
                            finish(false)
                        }
                    }
                } else {
                    finish(false)
                }
            }
        } else {
            AppDelegate.stopTrojan {
                finish(true)
            }
        }
    }
    
    func updateRunningModeMenu() {
        let defaults = UserDefaults.standard
        let mode = defaults.string(forKey: USERDEFAULTS_RUNNING_MODE)

        pacItem.state = NSControl.StateValue(rawValue: 0)
        globalItem.state = NSControl.StateValue(rawValue: 0)
        manualItem.state = NSControl.StateValue(rawValue: 0)
        whiteListItem.state = NSControl.StateValue(rawValue: 0)
        backChinaItem.state = NSControl.StateValue(rawValue: 0)
        aclAutoItem.state = NSControl.StateValue(rawValue: 0)
        aclModeItem.state = NSControl.StateValue(rawValue: 0)
        if mode == "auto" {
            pacItem.state = NSControl.StateValue(rawValue: 1)
        } else if mode == "global" {
            globalItem.state = NSControl.StateValue(rawValue: 1)
        } else if mode == "manual" {
            manualItem.state = NSControl.StateValue(rawValue: 1)
        } else if mode == "whiteList" {
            let aclMode = defaults.string(forKey: USERDEFAULTS_ACL_FILE_NAME)!
            switch aclMode {
            case "backchn.acl":
                aclModeItem.state = NSControl.StateValue(rawValue: 1)
                backChinaItem.state = NSControl.StateValue(rawValue: 1)
                break
            case "gfwlist.acl":
                aclModeItem.state = NSControl.StateValue(rawValue: 1)
                aclAutoItem.state = NSControl.StateValue(rawValue: 1)
                break
            default:
                whiteListItem.state = NSControl.StateValue(rawValue: 1)
            }
        }
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
