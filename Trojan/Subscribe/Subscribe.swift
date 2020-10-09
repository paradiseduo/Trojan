//
//  Subscribe.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/4/27.
//  Copyright © 2020 MacClient. All rights reserved.
//

import Foundation
import Alamofire

@objcMembers class Subscribe: NSObject{
    
    var subscribeFeed = ""
    var isActive = true
    var autoUpdateEnable = true
    var maxCount = 0 // -1 is not limited
    var groupName = ""
    var token = ""
    var cache = ""
    var filter = ""
        
    init(initUrlString:String, initGroupName: String, initToken: String, initFilter: String, initMaxCount: Int, initActive: Bool, initAutoUpdate:Bool){
        super.init()
        subscribeFeed = initUrlString

        token = initToken
        filter = initFilter
        isActive = initActive
        
        autoUpdateEnable = initAutoUpdate
    
        setMaxCount(initMaxCount: initMaxCount)
        setGroupName(newGroupName: initGroupName)
    }
    
    func getFeed() -> String{
        return subscribeFeed
    }
    
    func setFeed(newFeed: String){
        subscribeFeed = newFeed
    }
    
    func diactivateSubscribe(){
        isActive = false
    }
    
    func activateSubscribe(){
        isActive = true
    }
    
    func enableAutoUpdate(){
        autoUpdateEnable = true
    }
    
    func disableAutoUpdate(){
        autoUpdateEnable = false
    }
    
    func getAutoUpdateEnable() -> Bool {
        return autoUpdateEnable
    }
    
    func getFilter() -> String {
        return filter
    }
    
    func setFilter(filter: String) {
        self.filter = filter.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func setGroupName(newGroupName: String) {
        if newGroupName != "" {
            groupName = newGroupName
            return
        }
        if self.cache != "" {
            getTrojanURLsFromRes(resString: cache)
            return
        }
    }
    
    func getGroupName() -> String {
        return groupName
    }
    
    func getMaxCount() -> Int {
        return maxCount
    }
    
    static func fromDictionary(_ data:[String:AnyObject]) -> Subscribe {
        var feed:String = ""
        var group:String = ""
        var token:String = ""
        var maxCount:Int = -1
        var isActive:Bool = true
        var autoUpdateEnable:Bool = true
        var filter:String = ""
        
        for (key, value) in data {
            switch key {
            case "feed":
                feed = value as! String
            case "group":
                group = value as! String
            case "token":
                token = value as! String
            case "maxCount":
                maxCount = value as! Int
            case "isActive":
                isActive = value as! Bool
            case "autoUpdateEnable":
                autoUpdateEnable = value as! Bool
            case "filter":
                filter = value as! String
            default:
                print("")
            }
        }
        return Subscribe(initUrlString: feed, initGroupName: group, initToken: token, initFilter: filter, initMaxCount: maxCount,initActive: isActive,initAutoUpdate: autoUpdateEnable)
    }
    
    static func toDictionary(_ data: Subscribe) -> [String: AnyObject] {
        var ret : [String: AnyObject] = [:]
        ret["feed"] = data.subscribeFeed as AnyObject
        ret["group"] = data.groupName as AnyObject
        ret["token"] = data.token as AnyObject
        ret["maxCount"] = data.maxCount as AnyObject
        ret["isActive"] = data.isActive as AnyObject
        ret["autoUpdateEnable"] = data.autoUpdateEnable as AnyObject
        ret["filter"] = data.filter as AnyObject
        return ret
    }
    
    fileprivate func sendRequest(url: String, options: Any, useProxy: Bool = true, callback: @escaping (String) -> Void) {
        if url.isEmpty { return }
        let headers: HTTPHeaders = [
            "Cache-control": "no-cache",
            "token": self.token,
            "User-Agent": "Trojan " + (getLocalInfo()["CFBundleShortVersionString"] as! String) + " Version " + (getLocalInfo()["CFBundleVersion"] as! String)
        ]
        
        Network.session(useProxy: useProxy).request(url, headers: headers).responseString{ response in
            do {
                let value = try response.result.get()
                callback(value)
            } catch {
                callback("")
                self.pushNotification(title: "请求失败", subtitle: "", info: "发送到\(url)的请求失败，请检查您的网络")
            }
        }
    }
    
    func setMaxCount(initMaxCount: Int) {
        func getMaxFromRes(resString: String) {
            let maxCountReg = "MAX=[0-9]+"
            let decodeRes = resString.base64Decoded()
            let range = decodeRes.range(of: maxCountReg, options: .regularExpression)
            if let r = range {
                self.maxCount = Int(decodeRes[r].replacingOccurrences(of: "MAX=", with: ""))!
            }
            else{
                self.maxCount = -1
            }
        }
        if initMaxCount != 0 { return self.maxCount = initMaxCount }
        if cache != "" { return getMaxFromRes(resString: cache) }
        sendRequest(url: self.subscribeFeed, options: "", callback: { resString in
            if resString == "" { return }// Also should hold if token is wrong feedback
            getMaxFromRes(resString: resString)
            self.cache = resString
        })
    }
    
    func updateServerFromFeed(useProxy: Bool, handle: @escaping ()->()) {
        func updateServerHandler(resString: String) {
            let urls = self.getTrojanURLsFromRes(resString: resString)
            // hold if user fill a maxCount larger then server return
            // Should push a notification about it and correct the user filled maxCount?
            let maxN = (self.maxCount > urls.count) ? urls.count : (self.maxCount == -1) ? urls.count: self.maxCount

            // 存一下原有group中的 profile ，为了计算下列数量
            let oldNodes = Profiles.shared.profiles.filter { $0.client.group == self.getGroupName()}
            // 原有的 group 中的 profile 全部清除
            Profiles.shared.profiles = Profiles.shared.profiles.filter { $0.client.group != self.getGroupName()}

            //更新对应4种情况：
            //1.节点原来存在，更新后被删除
            //2.节点原来不存在，更新后增加
            //3.节点原来存在，并且更新完之后啥也不用干（本地节点信息跟服务端已经一致）
            //4.节点原来存在，只更新内容（本地节点与服务端信息不一致，比如密码换了）
            var subCount = 0
            var addCount = 0
            var dupCount = 0
            var existCount = 0
            var filterCount = 0
            //这里处理后三种情况
            var newNodes = [Profile]()
            for index in 0..<maxN {
                if let profile = ParseAppURLSchemes(url: urls[index]) {
                    profile.client.group = self.getGroupName()
                    newNodes.append(profile)
                    let (exists, duplicated, _) = Profiles.isDuplicatedOrExists(profile)
                    if duplicated {
                        dupCount += 1
                    } else if exists {
                        existCount += 1
                    } else {
                        addCount += 1
                    }
                } else {
                    print("\(index), \(urls[index]) ParseAppURLSchemes Error!")
                }
            }
            //这里处理第一种情况
            for item in oldNodes {
                if !newNodes.contains(where: { (s) -> Bool in
                    return item.equal(profile: s)
                }) {
                    subCount += 1
                }
            }
            //将更新后的节点加回原来的数组
            for item in newNodes {
                Profiles.shared.add(item)
            }
            //用户添加了过滤条件的话，在这里过滤
            var regex: NSRegularExpression?
            if self.filter.count > 0 {
                do {
                    regex = try NSRegularExpression(pattern: self.filter, options:.caseInsensitive)
                }catch{
                    regex = nil
                }
            }
            Profiles.shared.profiles = Profiles.shared.profiles.filter { (p) -> Bool in
                let remark = p.client.group
                let result = regex?.numberOfMatches(in: remark, options: .reportCompletion, range: NSMakeRange(0, remark.count))
                if let r = result, r > 0 {
                    if remark == self.groupName {
                        filterCount += 1
                        return false
                    }
                }
                return true
            }
            Profiles.shared.save()
            DispatchQueue.main.async {
                var message = "节点总数:\(maxN)"
                if dupCount > 0 {
                    message += " 无需更新:\(dupCount)"
                }
                if existCount > 0 {
                    message += " 更新:\(existCount)"
                }
                if addCount > 0 {
                    message += " 新增:\(addCount)"
                }
                if subCount > 0 {
                    message += " 删除:\(subCount)"
                }
                if filterCount > 0 {
                    message += " 过滤:\(filterCount)"
                }
                self.pushNotification(title: "成功更新订阅", subtitle: message, info: "更新来自\(self.subscribeFeed)的订阅")
                NotificationCenter.default.post(name: NOTIFY_SERVER_PROFILES_CHANGED, object: nil)
                handle()
            }
        }

        if !isActive {
            handle()
            return
        }

        sendRequest(url: self.subscribeFeed, options: "", useProxy: useProxy, callback: { resString in
            if resString == "" {
                handle()
                return
            }
            updateServerHandler(resString: resString)
            self.cache = resString
        })
    }
    
    @discardableResult func getTrojanURLsFromRes(resString: String) -> [String] {
        let decodeRes = resString.base64Decoded()
        let decodeURL = decodeRes.urlDecode()
        let arr = decodeURL.components(separatedBy: "\n")
        if arr.count >= 2 {
            let s = arr[1].components(separatedBy: "=")
            if s.count == 2 {
                self.groupName = s[1]
            }
        }
        var urls = [String]()
        for item in arr {
            if item.contains("trojan://") {
                urls.append(item)
            }
        }
        return urls
    }
    
    func feedValidator() -> Bool{
        let feedRegExp = "http[s]?://[A-Za-z0-9-_/.=?]*"
        return subscribeFeed.range(of:feedRegExp, options: .regularExpression) != nil
    }
    
    fileprivate func pushNotification(title: String, subtitle: String, info: String){
        let userNote = NSUserNotification()
        userNote.title = title
        userNote.subtitle = subtitle
        userNote.informativeText = info
        userNote.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(userNote);
    }
    
    class func isSame(source: Subscribe, target: Subscribe) -> Bool {
        return source.subscribeFeed == target.subscribeFeed && source.token == target.token && source.maxCount == target.maxCount
    }
    
    func isExist(_ target: Subscribe) -> Bool {
        return self.subscribeFeed == target.subscribeFeed
    }
}
