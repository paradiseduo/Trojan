//
//  Configuration.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/4/2.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

// Trojan Helper
let TROJAN_START = Notification.Name("TROJAN_START")
let TROJAN_STOP = Notification.Name("TROJAN_STOP")
let USERDEFAULTS_TROJAN_ON = "TROJAN_ON"
let USERDEFAULTS_PROFILE = "Profile"
let CONFIG_PATH = NSHomeDirectory()+"/Documents/Trojan/trojan_client.json"
let CONFIG_PATH_OLD = NSHomeDirectory()+"/Documents/trojan_client.json"

// Version Checker Helper
let _VERSION_XML_URL = "https://raw.githubusercontent.com/paradiseduo/Trojan/master/Trojan/Info.plist"
let _VERSION_XML_LOCAL:String = Bundle.main.bundlePath + "/Contents/Info.plist"

// Log Helper
let LOG_PATH = "/usr/local/var/log/trojan"
let LOG_CLEAN_FINISH = Notification.Name("LOG_CLEAN_FINISH")

let ISSUES_URL = "https://github.com/paradiseduo/Trojan/issues"
let RELEASE_URL = "https://github.com/paradiseduo/Trojan/releases"

let PACRulesDirPath = NSHomeDirectory() + "/Documents/Trojan/"
let PACUserRuleFilePath = PACRulesDirPath + "user-rule.txt"
let PACFilePath = PACRulesDirPath + "gfwlist.js"
let GFWListFilePath = PACRulesDirPath + "gfwlist.txt"

let ACLWhiteListFilePath = PACRulesDirPath + "chn.acl"
let ACLBackCHNFilePath = PACRulesDirPath + "backchn.acl"
let ACLGFWListFilePath = PACRulesDirPath + "gfwlist.acl"

let PRIVOXY_VERSION = "3.0.28.static"
let APP_SUPPORT_DIR = "/Library/Application Support/Trojan/"
let LAUNCH_AGENT_DIR = "/Library/LaunchAgents/"
let LAUNCH_AGENT_CONF_PRIVOXY_NAME = "MacOS.Trojan.http.plist"

let TROJAN_VERSION = "1.16.0"
let LAUNCH_AGENT_CONF_TROJAN_NAME = "MacOS.Trojan.local.plist"

let NOTIFY_HTTP_CONF_CHANGED = Notification.Name("NOTIFY_HTTP_CONF_CHANGED")

let NOTIFY_UPDATE_RUNNING_MODE_MENU = Notification.Name("NOTIFY_UPDATE_RUNNING_MODE_MENU")

let NOTIFY_SERVER_PROFILES_CHANGED = Notification.Name("NOTIFY_SERVER_PROFILES_CHANGED")

let NOTIFY_SHOW_NETWORK_MONITOR = Notification.Name("NOTIFY_SHOW_NETWORK_MONITOR")

let NOTIFY_REFRESH_SERVERS = Notification.Name("NOTIFY_REFRESH_SERVERS")
