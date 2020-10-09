//
//  Utils.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/10/9.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Foundation

func getLocalInfo() -> [String: Any] {
    let InfoDict = Bundle.main.infoDictionary
    return InfoDict!
}

func splitor(url: String, regexp: String) -> [String] {
    var ret: [String] = []
    var ssrUrl = url
    while ssrUrl.range(of:regexp, options: .regularExpression) != nil {
        if let range = ssrUrl.range(of:regexp, options: .regularExpression) {
            let result = String(ssrUrl[range])
            ssrUrl.replaceSubrange(range, with: "")
            ret.append(result)
        }
    }
    return ret
}

func ParseAppURLSchemes(url: String) -> Profile? {
    if url.contains("trojan://") {
        return ParseTrojanURL(url: url)
    }
    return nil
}

// base64(urlEncode(trojan://password@domain:port?peer=name))
func ParseTrojanURL(url: String) -> Profile? {
    let p1 = url.components(separatedBy: "trojan://")[1]
    let password = p1.components(separatedBy: "@")[0]
    let p2 = url.components(separatedBy: "trojan://"+password+"@")[1]
    let domain = p2.components(separatedBy: ":")[0]
    let p3 = url.components(separatedBy: "trojan://"+password+"@"+domain+":")[1]
    let port = p3.components(separatedBy: "?")[0]
    var name = url.components(separatedBy: "?peer=")[1]
    if name.contains("#") {
        name = name.components(separatedBy: "#")[1]
    }
    let p = Profile()
    p.loadDefaultProfile()
    p.client.remote_addr = String(domain)
    p.client.remote_port = Int(port) ?? 443
    p.client.password = [String(password)]
    p.name = String(name)
    return p
}

extension String {
    func base64Encoded() -> String {
        return data(using: .utf8)?.base64EncodedString() ?? self
    }

    func base64Decoded() -> String {
        guard let data = Data(base64Encoded: self) else { return self }
        return String(data: data, encoding: .utf8) ?? self
    }
    
    func urlEncode() -> String {
        let customAllowedSet = NSCharacterSet(charactersIn:"=\"#%/<>?@\\^`{|}&;:,.").inverted
        return self.addingPercentEncoding(withAllowedCharacters: customAllowedSet) ?? self
    }
    
    func urlDecode() -> String {
        return self.removingPercentEncoding ?? self
    }
}

extension NSTextField {
    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        switch event.charactersIgnoringModifiers {
        case "a":
            return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: self.window?.firstResponder, from: self)
        case "c":
            return NSApp.sendAction(#selector(NSText.copy(_:)), to: self.window?.firstResponder, from: self)
        case "v":
            return NSApp.sendAction(#selector(NSText.paste(_:)), to: self.window?.firstResponder, from: self)
        case "x":
            return NSApp.sendAction(#selector(NSText.cut(_:)), to: self.window?.firstResponder, from: self)
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}
