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
    var speedItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
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
    
    @IBOutlet weak var speedMenu: NSMenu!
    @IBOutlet weak var fixedWidth: NSMenuItem!
    
    @IBOutlet weak var serversMenuItem: NSMenuItem!
    
    var settingW: SettingWindowController!
    var settingsW: SettingsWIndowController!
    var logW: LogWindowController!
    var toastW: ToastWindowController!
    var subscribePreferenceWinCtrl: SubscribePreferenceWindowController!
    
    var speedMonitor:NetSpeedMonitor?
    var speedTimer:Timer?
    let repeatTimeinterval: TimeInterval = 2.0
    
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
        NotificationCenter.default.addObserver(forName: NOTIFY_SHOW_NETWORK_MONITOR, object: nil, queue: OperationQueue.main) { (noti) in
            self.showSpeed()
        }
        NotificationCenter.default.addObserver(forName: NOTIFY_REFRESH_SERVERS, object: nil, queue: OperationQueue.main) { (noti) in
            self.updateServersMenu()
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
            USERDEFAULTS_AUTO_CHECK_UPDATE:false,
            USERDEFAULTS_ENABLE_SHOW_SPEED:false,
            USERDEFAULTS_FIXED_NETWORK_SPEED_VIEW_WIDTH:false
        ])
        
        let fileMgr = FileManager.default
        if fileMgr.fileExists(atPath: CONFIG_PATH_OLD) {
            do {
                try fileMgr.moveItem(atPath: CONFIG_PATH_OLD, toPath: CONFIG_PATH)
            } catch {
                
            }
        }
        self.showSpeed()
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
            self.updateServersMenu()
        }
    }
    
    func updateMainMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: USERDEFAULTS_TROJAN_ON)
        if isOn {
            switchLabel.title = "Trojan: On".localized
            switchLabel.image = NSImage(named: NSImage.statusAvailableName)
            toggleRunning.title = "Turn Trojan Off".localized
            
            let icon = NSImage(named: "open")
            statusItem.button?.image = icon
            statusItem.menu = statusMenu
            if Profiles.shared.count() > 0 {
                copyCommandItem.isHidden = false
            }
        } else {
            switchLabel.title = "Trojan: Off".localized
            switchLabel.image = NSImage(named: NSImage.statusUnavailableName)
            toggleRunning.title = "Turn Trojan On".localized
            
            let icon = NSImage(named: "close")
            statusItem.button?.image = icon
            statusItem.menu = statusMenu
            copyCommandItem.isHidden = true
        }
        statusItem.image?.isTemplate = true
    }
    
    func showSpeed() {
        if UserDefaults.standard.bool(forKey: USERDEFAULTS_ENABLE_SHOW_SPEED) {
            speedItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            speedItem.menu = speedMenu
            if UserDefaults.standard.bool(forKey: USERDEFAULTS_FIXED_NETWORK_SPEED_VIEW_WIDTH) {
                self.fixedSpeedItemWidth(true)
                self.fixedWidth.state = NSControl.StateValue.on
            } else {
                self.fixedSpeedItemWidth(false)
                self.fixedWidth.state = NSControl.StateValue.off
            }
            if let b = speedItem.button {
                b.attributedTitle = SpeedTools.speedAttributedString(up: 0.0, down: 0.0)
            }
            if speedMonitor == nil{
                speedMonitor = NetSpeedMonitor()
            }
            if speedTimer == nil {
                speedTimer = Timer(timeInterval: repeatTimeinterval, repeats: true) {[weak self] (timer) in
                    guard let w = self else {return}
                    w.speedMonitor?.timeInterval(w.repeatTimeinterval, downloadAndUploadSpeed: { (down, up) in
                        if let b = w.speedItem.button {
                            b.attributedTitle = SpeedTools.speedAttributedString(up: up, down: down)
                        }
                    })
                }
                RunLoop.main.add(speedTimer!, forMode: RunLoop.Mode.common)
            }
        } else {
            speedItem.attributedTitle = NSAttributedString(string: "")
            NSStatusBar.system.removeStatusItem(speedItem)
            speedTimer?.invalidate()
            speedTimer = nil
            speedMonitor = nil
        }
    }
    
    func updateServersMenu() {
        serversMenuItem.title = Profile.shared.name
        serversMenuItem.submenu?.removeAllItems()
        var i = 0
        var fastTime = ""
        if let t = UserDefaults.standard.object(forKey: USERDEFAULTS_FASTEST_NODE) as? String {
            fastTime = t
        }
        for p in Profiles.shared.profiles {
            let item = NSMenuItem(title: p.name, action: #selector(StatusMenuManager.selectServer), keyEquivalent: "")
            item.tag = i
            item.target = self
            
            let nf = NumberFormatter.three(p.latency)
            if p.latency.doubleValue != Double.infinity {
                item.title += "  - \(nf)ms"
                if nf == fastTime {
                    let dic = [NSAttributedString.Key.foregroundColor : NSColor.green]
                    let attStr = NSAttributedString(string: item.title, attributes: dic)
                    item.attributedTitle = attStr
                }
            } else {
                if !nerverTestBefore {
                    item.title += "  - failed"
                    let dic = [NSAttributedString.Key.foregroundColor : NSColor.red]
                    let attStr = NSAttributedString(string: item.title, attributes: dic)
                    item.attributedTitle = attStr
                }
            }
            
            if p.equal(profile: Profile.shared) {
                item.state = NSControl.StateValue(rawValue: 1)
            }
            serversMenuItem.submenu?.addItem(item)
            i += 1
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
            self.makeToast("Trojan: Off".localized)
        } else {
            defaults.set(true, forKey: USERDEFAULTS_TROJAN_ON)
            self.makeToast("Trojan: On".localized)
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
        Profiles.shared.save()
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
        CommandLine.async(task: Process(), command: "rm -rf \(LOG_PATH)", terminate:  { (finish) in
            print("CleanLog finish")
            NotificationCenter.default.post(name: LOG_CLEAN_FINISH, object: nil)
            self.makeToast("Logs Cleand")
        })
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
    
    @IBAction func testConnectionDelay(_ sender: NSMenuItem) {
        ConnectTestigManager.shared.start()
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
    
    @IBAction func editSubscribeFeedTao(_ sender: NSMenuItem) {
        if subscribePreferenceWinCtrl != nil {
            subscribePreferenceWinCtrl.close()
        }
        let ctrl = SubscribePreferenceWindowController(windowNibName: "SubscribePreferenceWindowController")
        subscribePreferenceWinCtrl = ctrl
        
        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func updateSubscribeWithProxy(_ sender: NSMenuItem) {
        SubscribeManager.instance.updateAllServerFromSubscribe(auto: false, useProxy: true)
    }
    
    @IBAction func updateSubscribeWithoutProxy(_ sender: NSMenuItem) {
        SubscribeManager.instance.updateAllServerFromSubscribe(auto: false, useProxy: false)
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
                self.makeToast("Export Command Copied.".localized)
            } else {
                self.makeToast("Export Command Copied Failed.".localized)
            }
        } else {
            if let a = address {
                let command = "export ALL_PROXY=socks5://\(a):\(port);export no_proxy=localhost;"
                // Copy to paste board.
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: NSPasteboard.PasteboardType.string)
                
                // Show a toast notification.
                self.makeToast("Export Command Copied.".localized)
            } else {
                self.makeToast("Export Command Copied Failed.".localized)
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
    
    @objc func selectServer(_ sender: NSMenuItem) {
        let index = sender.tag
        let spMgr = Profiles.shared
        let newProfile = spMgr.profiles[index]
        if newProfile.equal(profile: Profile.shared) {
            return
        } else {
            Profile.shared.client = newProfile.client
            Profile.shared.name = newProfile.name
            Profile.shared.saveProfile()
            NotificationCenter.default.post(name: NOTIFY_SERVER_PROFILES_CHANGED, object: nil)
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
    
    //------------------------------------------------------------
    // MARK: Speed Item Actions
    @IBAction func fixedWidth(_ sender: NSMenuItem) {
        sender.state = (sender.state == .on ? .off:.on)
        let b = sender.state == .on ? true:false
        UserDefaults.standard.setValue(b, forKey: USERDEFAULTS_FIXED_NETWORK_SPEED_VIEW_WIDTH)
        UserDefaults.standard.synchronize()
        self.fixedSpeedItemWidth(b)
    }
    
    @IBAction func closeSpeedItem(_ sender: NSMenuItem) {
        UserDefaults.standard.setValue(false, forKey: USERDEFAULTS_ENABLE_SHOW_SPEED)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(Notification(name: NOTIFY_SHOW_NETWORK_MONITOR))
    }
    
    private func fixedSpeedItemWidth(_ fixed: Bool) {
        if fixed {
            speedItem.length = 70
        } else {
            speedItem.length = NSStatusItem.variableLength
        }
    }
}
