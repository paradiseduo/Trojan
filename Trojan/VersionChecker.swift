//
//  VersionChecker.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/3/31.
//  Copyright © 2020 Mac. All rights reserved.
//

import Cocoa

class VersionChecker: NSObject {
    var haveNewVersion: Bool = false
    enum versionError: Error {
        case CanNotGetOnlineData
    }

    func showAlertView(Title: String, SubTitle: String, ConfirmBtn: String, CancelBtn: String) -> Int {
        let alertView = NSAlert()
        alertView.messageText = Title
        alertView.informativeText = SubTitle
        alertView.addButton(withTitle: ConfirmBtn)
        if CancelBtn != "" {
            alertView.addButton(withTitle: CancelBtn)
        }
        let action = alertView.runModal()
        return action.rawValue
    }
    
    func parserVersionString(strIn: String) -> Int {
        var strTmp = strIn
        if let index = strIn.range(of: "-")?.lowerBound {
            strTmp = String(strIn[..<index])
        }
        if !strTmp.hasSuffix(".") {
            strTmp += "."
        }
        var ret = [Int]()
        
        repeat {
            if let index = strTmp.range(of: ".")?.lowerBound, let num = Int(String(strTmp[..<index])) {
                ret.append(num)
                print(String(strTmp[..<index]))
            }
            if let index = strTmp.range(of: ".")?.upperBound {
                strTmp = String(strTmp[index...])
            }
        } while(strTmp.range(of: ".") != nil);
        var sum = 0
        var i = 100
        for item in ret {
            sum += item*i
            i /= 10
        }
        return sum
    }
    
    func checkNewVersion() -> [String:Any] {
        func getOnlineData() throws -> NSDictionary{
            guard NSDictionary(contentsOf: URL(string:_VERSION_XML_URL)!) != nil else {
                throw versionError.CanNotGetOnlineData
            }
            return NSDictionary(contentsOf: URL(string:_VERSION_XML_URL)!)!
        }
        
        var localData: NSDictionary = NSDictionary()
        var onlineData: NSDictionary = NSDictionary()
        
        localData = NSDictionary(contentsOfFile: _VERSION_XML_LOCAL)!
        do{
            try onlineData = getOnlineData()
        }catch{
            return ["newVersion" : false,
                    "error": "network error",
                    "Title": "网络错误",
                    "SubTitle": "由于网络错误无法检查更新",
                    "ConfirmBtn": "确认",
                    "CancelBtn": ""
            ]
        }
        
        let versionString:String = onlineData["CFBundleShortVersionString"] as! String
        let buildString:String = onlineData["CFBundleVersion"] as! String
        let currentVersionString:String = localData["CFBundleShortVersionString"] as! String
        let currentBuildString:String = localData["CFBundleVersion"] as! String
        var subtitle:String
        if (versionString == currentVersionString){
            
            if buildString == currentBuildString {

                subtitle = "当前版本 " + currentVersionString + " build " + currentBuildString
                return ["newVersion" : false,
                        "error": "",
                        "Title": "已是最新版本！",
                        "SubTitle": subtitle,
                        "ConfirmBtn": "确认",
                        "CancelBtn": ""
                ]
            }
            else {
                haveNewVersion = true
                
                subtitle = "新版本为 " + versionString + " build " + buildString + "\n" + "当前版本 " + currentVersionString + " build " + currentBuildString
                return ["newVersion" : true,
                        "error": "",
                        "Title": "软件有更新！",
                        "SubTitle": subtitle,
                        "ConfirmBtn": "前往下载",
                        "CancelBtn": "取消"
                ]
            }
        }
        else{
            // 处理如果本地版本竟然比远程还新
            
            let version = parserVersionString(strIn: onlineData["CFBundleShortVersionString"] as! String)
            let currentVersion = parserVersionString(strIn: localData["CFBundleShortVersionString"] as! String)
            
            if currentVersion < version {
                haveNewVersion = true
                subtitle = "新版本为 " + versionString + " build " + buildString + "\n" + "当前版本 " + currentVersionString + " build " + currentBuildString
                return ["newVersion" : true,
                        "error": "",
                        "Title": "软件有更新！",
                        "SubTitle": subtitle,
                        "ConfirmBtn": "前往下载",
                        "CancelBtn": "取消"
                ]
            } else {
                subtitle = "当前版本 " + currentVersionString + " build " + currentBuildString + "\n" + "远端版本 " + versionString + " build " + buildString
                return ["newVersion" : false,
                        "error": "",
                        "Title": "已是最新版本！",
                        "SubTitle": subtitle,
                        "ConfirmBtn": "确认",
                        "CancelBtn": ""
                ]
            }
        }
    }
}
