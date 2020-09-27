//
//  SettingsWIndowController.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/5/23.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Cocoa

class SettingsWIndowController: NSWindowController, NSWindowDelegate, NSTextFieldDelegate {
    
    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var launchAtLogin: NSButton!
    
    @IBOutlet weak var httpAddress: NSTextField!
    @IBOutlet weak var httpPort: NSTextField!
    
    private var httpHasChanged = false
    
    override func windowDidLoad() {
        super.windowDidLoad()

        window?.delegate = self
        launchAtLogin.state = AppDelegate.getLauncherStatus() ? .on:.off
        
        httpAddress.delegate = self
        httpPort.delegate = self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        window?.center()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let t = obj.object as? NSTextField {
            switch t {
            case httpPort, httpAddress:
                httpHasChanged = true
                break
            default:
                break
            }
        }
    }
    
    @IBAction func toolbarAction(_ sender: NSToolbarItem) {
        tabView.selectTabViewItem(withIdentifier: sender.itemIdentifier)
    }
    
    @IBAction func onHTTPSaveTap(_ sender: NSButton) {
        if httpHasChanged {
            NotificationCenter.default.post(name: NOTIFY_HTTP_CONF_CHANGED, object: nil)
        }
    }
    
    @IBAction func showNetwork(_ sender: NSButton) {
        NotificationCenter.default.post(Notification(name: NOTIFY_SHOW_NETWORK_MONITOR))
    }
    
    @IBAction func httpButtonTap(_ sender: NSButton) {
        httpHasChanged = true
    }
    
    func windowWillClose(_ notification: Notification) {
        AppDelegate.setLauncherStatus(open: launchAtLogin.state == .on ? true:false)
    }
}
