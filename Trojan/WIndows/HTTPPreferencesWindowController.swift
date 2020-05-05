//
//  HTTPPreferencesWindowController.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/5/5.
//  Copyright © 2020 Mac. All rights reserved.
//

import Cocoa

class HTTPPreferencesWindowController: NSWindowController, NSWindowDelegate {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.window?.delegate = self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        window?.center()
    }
    
    //------------------------------------------------------------
    // NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        NotificationCenter.default.post(name: NOTIFY_HTTP_CONF_CHANGED, object: nil)
    }
    
}
