//
//  LaunchAgentHelper.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/5/5.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Foundation
import CommonCrypto


extension Data {
    func sha1() -> String {
        let data = self
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1((data as NSData).bytes, CC_LONG(data.count), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined(separator: "")
    }
}

func getFileSHA1Sum(_ filepath: String) -> String {
    let fileMgr = FileManager.default
    if fileMgr.fileExists(atPath: filepath) {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: filepath)) {
            return data.sha1()
        }
    }
    return ""
}

func generateTrojanLauchAgentPlist() -> Bool {
    let trojanPath = NSHomeDirectory() + APP_SUPPORT_DIR + "trojan"
    let launchAgentDirPath = NSHomeDirectory() + LAUNCH_AGENT_DIR
    let plistFilepath = launchAgentDirPath + LAUNCH_AGENT_CONF_TROJAN_NAME
    
    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        try! fileMgr.createDirectory(atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    let oldSha1Sum = getFileSHA1Sum(plistFilepath)

    let arguments = [trojanPath, "--log", LOG_PATH, "--config", CONFIG_PATH]

    // For a complete listing of the keys, see the launchd.plist manual page.
    let dict: NSMutableDictionary = [
        "Label": "MacOS.Trojan.local",
        "WorkingDirectory": NSHomeDirectory() + APP_SUPPORT_DIR,
        "KeepAlive": true,
        "StandardOutPath": LOG_PATH,
        "StandardErrorPath": LOG_PATH,
        "ProgramArguments": arguments,
        "EnvironmentVariables": ["DYLD_LIBRARY_PATH": NSHomeDirectory() + APP_SUPPORT_DIR]
    ]
    dict.write(toFile: plistFilepath, atomically: true)
    let Sha1Sum = getFileSHA1Sum(plistFilepath)
    if oldSha1Sum != Sha1Sum {
        return true
    } else {
        return false
    }
}

func InstallTrojanLocal(finish: @escaping(_ success: Bool)->()) {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir+APP_SUPPORT_DIR
    if !fileMgr.fileExists(atPath: appSupportDir + "trojan-\(TROJAN_VERSION)/trojan") {
        let bundle = Bundle.main
        let installerPath = bundle.path(forResource: "install_trojan.sh", ofType: nil)
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Install trojan succeeded.")
            DispatchQueue.main.async {
                finish(true)
            }
        } else {
            NSLog("Install trojan failed.")
            DispatchQueue.main.async {
                finish(false)
            }
        }
    } else {
        finish(true)
    }
}

func ReloadConfTrojan(finish: @escaping(_ success: Bool)->()) {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "reload_conf_trojan.sh", ofType: nil)
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Reload trojan succeeded.")
        DispatchQueue.main.async {
            finish(true)
        }
    } else {
        NSLog("Reload trojan failed.")
        DispatchQueue.main.async {
            finish(false)
        }
    }
}

func StartTrojan(finish: @escaping(_ success: Bool)->()) {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "start_trojan.sh", ofType: nil)
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Start trojan succeeded.")
        DispatchQueue.main.async {
            finish(true)
        }
    } else {
        NSLog("Start trojan failed.")
        DispatchQueue.main.async {
            finish(false)
        }
    }
}

func StopTrojan(finish: @escaping(_ success: Bool)->()) {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "stop_trojan.sh", ofType: nil)
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Stop trojan succeeded.")
        DispatchQueue.main.async {
            finish(true)
        }
    } else {
        NSLog("Stop trojan failed.")
        DispatchQueue.main.async {
            finish(false)
        }
    }
}


func RemoveTrojan(finish: @escaping(_ success: Bool)->()) {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "remove_trojan.sh", ofType: nil)
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Remove trojan succeeded.")
        DispatchQueue.main.async {
            finish(true)
        }
    } else {
        NSLog("Remove trojan failed.")
        DispatchQueue.main.async {
            finish(false)
        }
    }
}

func writeTrojanConfFile(_ jsonString: String) -> Bool {
    let url = NSURL.fileURL(withPath: CONFIG_PATH)
    do {
        let oldSum = getFileSHA1Sum(CONFIG_PATH)
        try FileManager.default.removeItem(atPath: CONFIG_PATH)
        
        try jsonString.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        let newSum = getFileSHA1Sum(CONFIG_PATH)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5) {
            Profiles.shared.save()
        }
        
        if oldSum == newSum {
            return false
        }
        return true
    } catch let error {
        print("saveProfile: ", error)
    }
    return false
}

func SyncTrojan(finish: @escaping(_ success: Bool)->()) {
    func Sync(_ suc: Bool){
        SyncPrivoxy {
            SyncPac()
            finish(suc)
        }
    }
    var changed: Bool = false
    changed = changed || generateTrojanLauchAgentPlist()
    let mgr = Profile.shared
    if mgr.client != nil && mgr.client.remote_addr != "" {
        changed = changed || writeTrojanConfFile(Profile.shared.jsonString)
        if UserDefaults.standard.bool(forKey: USERDEFAULTS_TROJAN_ON) {
            ReloadConfTrojan { (suc) in
                Sync(suc)
            }
        } else {
            Sync(true)
        }
    } else {
        StopTrojan { (s) in
            Sync(true)
        }
    }
}

func generatePrivoxyLauchAgentPlist() -> Bool {
    let privoxyPath = NSHomeDirectory() + APP_SUPPORT_DIR + "privoxy"
    let logFilePath = NSHomeDirectory() + "/Library/Logs/privoxy.log"
    let launchAgentDirPath = NSHomeDirectory() + LAUNCH_AGENT_DIR
    let plistFilepath = launchAgentDirPath + LAUNCH_AGENT_CONF_PRIVOXY_NAME
    
    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        try! fileMgr.createDirectory(atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    let oldSha1Sum = getFileSHA1Sum(plistFilepath)
    
    let arguments = [privoxyPath, "--no-daemon", "privoxy.config"]
    
    // For a complete listing of the keys, see the launchd.plist manual page.
    let dict: NSMutableDictionary = [
        "Label": "MacOS.Trojan.http",
        "WorkingDirectory": NSHomeDirectory() + APP_SUPPORT_DIR,
        "KeepAlive": true,
        "StandardOutPath": logFilePath,
        "StandardErrorPath": logFilePath,
        "ProgramArguments": arguments,
        "EnvironmentVariables": ["DYLD_LIBRARY_PATH": NSHomeDirectory() + APP_SUPPORT_DIR]
    ]
    dict.write(toFile: plistFilepath, atomically: true)
    let Sha1Sum = getFileSHA1Sum(plistFilepath)
    if oldSha1Sum != Sha1Sum {
        return true
    } else {
        return false
    }
}

func ReloadConfPrivoxy(finish: @escaping(_ success: Bool)->()) {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "reload_conf_privoxy.sh", ofType: nil)
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Reload privoxy succeeded.")
        DispatchQueue.main.async {
            finish(true)
        }
    } else {
        NSLog("Reload privoxy failed.")
        DispatchQueue.main.async {
            finish(false)
        }
    }
}

func StartPrivoxy(finish: @escaping(_ success: Bool)->()) {
    if generatePrivoxyLauchAgentPlist() {
        let bundle = Bundle.main
        let installerPath = bundle.path(forResource: "start_privoxy.sh", ofType: nil)
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Start privoxy succeeded.")
            DispatchQueue.main.async {
                finish(true)
            }
        } else {
            NSLog("Start privoxy failed.")
            DispatchQueue.main.async {
                finish(false)
            }
        }
    } else {
        NSLog("Start privoxy failed.")
        DispatchQueue.main.async {
            finish(false)
        }
    }
}

func StopPrivoxy(finish: @escaping(_ success: Bool)->()) {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "stop_privoxy.sh", ofType: nil)
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Stop privoxy succeeded.")
        DispatchQueue.main.async {
            finish(true)
        }
    } else {
        NSLog("Stop privoxy failed.")
        DispatchQueue.main.async {
            finish(false)
        }
    }
}

func InstallPrivoxy(finish: @escaping(_ success: Bool)->()) {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir+APP_SUPPORT_DIR
    if !fileMgr.fileExists(atPath: appSupportDir + "privoxy-\(PRIVOXY_VERSION)/privoxy") || !fileMgr.fileExists(atPath: appSupportDir + "libpcre.1.dylib") {
        let bundle = Bundle.main
        let installerPath = bundle.path(forResource: "install_privoxy.sh", ofType: nil)
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Install privoxy succeeded.")
            DispatchQueue.main.async {
                finish(true)
            }
        } else {
            NSLog("Install privoxy failed.")
            DispatchQueue.main.async {
                finish(false)
            }
        }
    } else {
        finish(true)
    }
}

func RemovePrivoxy(finish: @escaping(_ success: Bool)->()) {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "remove_privoxy.sh", ofType: nil)
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Remove privoxy succeeded.")
        DispatchQueue.main.async {
            finish(true)
        }
    } else {
        NSLog("Remove privoxy failed.")
        DispatchQueue.main.async {
            finish(false)
        }
    }
}

func writePrivoxyConfFile() -> Bool {
    do {
        let defaults = UserDefaults.standard
        let bundle = Bundle.main
        let examplePath = bundle.path(forResource: "privoxy.config.example", ofType: nil)
        var example = try String(contentsOfFile: examplePath!, encoding: .utf8)
        example = example.replacingOccurrences(of: "{http}", with: defaults.string(forKey: USERDEFAULTS_LOCAL_HTTP_LISTEN_ADDRESS)! + ":" + String(defaults.integer(forKey: USERDEFAULTS_LOCAL_HTTP_LISTEN_PORT)))
        example = example.replacingOccurrences(of: "{socks5}", with: defaults.string(forKey: USERDEFAULTS_LOCAL_SOCKS5_LISTEN_ADDRESS)! + ":" + String(defaults.integer(forKey: USERDEFAULTS_LOCAL_SOCKS5_LISTEN_PORT)))
        let data = example.data(using: .utf8)
        
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "privoxy.config"
        
        let oldSum = getFileSHA1Sum(filepath)
        try data?.write(to: URL(fileURLWithPath: filepath), options: .atomic)
        let newSum = getFileSHA1Sum(filepath)
        
        if oldSum == newSum {
            return false
        }
        
        return true
    } catch {
        NSLog("Write privoxy file failed.")
    }
    return false
}

func removePrivoxyConfFile() {
    do {
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "privoxy.config"
        try FileManager.default.removeItem(atPath: filepath)
    } catch {
        
    }
}

func SyncPrivoxy(finish: @escaping()->()) {
    var changed: Bool = false
    changed = changed || generatePrivoxyLauchAgentPlist()
    let mgr = Profile.shared
    if mgr.client != nil && mgr.client.remote_addr != "" {
        changed = changed || writePrivoxyConfFile()
        
        let on = UserDefaults.standard.bool(forKey: USERDEFAULTS_LOCAL_HTTP_ON) && UserDefaults.standard.bool(forKey: USERDEFAULTS_TROJAN_ON)
        if on {
            ReloadConfPrivoxy { (success) in
                finish()
            }
        } else {
            StopPrivoxy { (success) in
                removePrivoxyConfFile()
                finish()
            }
        }
    } else {
        finish()
    }
}
