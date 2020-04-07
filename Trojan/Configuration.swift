//
//  Configuration.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/4/2.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

// Trojan Helper
let TROJAN_START = Notification.Name("TROJAN_START")
let TROJAN_STOP = Notification.Name("TROJAN_STOP")
let USERDEFAULTS_TROJAN_ON = "TROJAN_ON"
let USERDEFAULTS_PROFILE = "Profile"
let CONFIG_PATH = NSHomeDirectory()+"/Documents/trojan_client.json"

// Version Checker Helper
let _VERSION_XML_URL = "https://raw.githubusercontent.com/paradiseduo/Trojan/master/Trojan/Info.plist"
let _VERSION_XML_LOCAL:String = Bundle.main.bundlePath + "/Contents/Info.plist"

// Log Helper
let LOG_PATH = "/usr/local/var/log/trojan"
let LOG_CLEAN_FINISH = Notification.Name("LOG_CLEAN_FINISH")

// Launcher Helper
let USERDEFAULTS_LAUNCH_AT_LOGIN = "USERDEFAULTS_LAUNCH_AT_LOGIN"
let KILL_LAUNCHER = Notification.Name("MacOS_Trojan_KILL_LAUNCHER")
let LAUNCHER_APPID = "MacOS.Trojan.StartAtLoginLauncher"

let ISSUES_URL = "https://github.com/paradiseduo/Trojan/issues"
let RELEASE_URL = "https://github.com/paradiseduo/Trojan/releases"
