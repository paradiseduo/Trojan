//
//  Json.swift
//  TrojanMac
//
//  Created by ParadiseDuo on 2020/4/7.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Foundation

struct Client: Codable {
    var run_type: String
    var local_addr: String
    var local_port: Int
    var password: [String]
    var remote_addr: String
    var remote_port: Int
    var log_level: Int?
    var ssl: SSL
    var tcp: TCP
    var uuid: String
    var group: String

    private enum CodingKeys: String, CodingKey {
        case run_type = "run_type"
        case local_addr = "local_addr"
        case local_port = "local_port"
        case remote_addr = "remote_addr"
        case remote_port = "remote_port"
        case password = "password"
        case log_level = "log_level"
        case ssl = "ssl"
        case tcp = "tcp"
        case uuid = "uuid"
        case group = "group"
    }
    
    func json() -> [String: AnyObject] {
        let c = self
        
        let ssl: [String: AnyObject] = ["verify": NSNumber(value: c.ssl.verify ?? true) as AnyObject,
                                        "verify_hostname": NSNumber(value: c.ssl.verify_hostname ?? true) as AnyObject,
                                        "cert": c.ssl.cert as AnyObject,
                                        "cipher": c.ssl.cipher as AnyObject,
                                        "cipher_tls13": c.ssl.cipher_tls13 as AnyObject,
                                        "sni": c.ssl.sni as AnyObject,
                                        "alpn": c.ssl.alpn as AnyObject,
                                        "reuse_session": NSNumber(value: c.ssl.reuse_session ?? true) as AnyObject,
                                        "session_ticket": NSNumber(value: c.ssl.session_ticket ?? false) as AnyObject,
                                        "curves": c.ssl.curves as AnyObject,
                                        "plain_http_response": c.ssl.plain_http_response as AnyObject,
                                        "dhparam": c.ssl.dhparam as AnyObject,
                                        "prefer_server_cipher": NSNumber(value: c.ssl.prefer_server_cipher ?? true) as AnyObject
                                       ]
        
        let tcp: [String: AnyObject] = ["no_delay": NSNumber(value: c.tcp.no_delay ?? true) as AnyObject,
                                        "keep_alive": NSNumber(value: c.tcp.keep_alive ?? true) as AnyObject,
                                        "reuse_port": NSNumber(value: c.tcp.reuse_port ?? false) as AnyObject,
                                        "fast_open": NSNumber(value: c.tcp.fast_open ?? false) as AnyObject,
                                        "fast_open_qlen": NSNumber(value: c.tcp.fast_open_qlen ?? 20) as AnyObject
                                       ]
        var uuid = UUID().uuidString
        if c.uuid.count > 0 {
            uuid = c.uuid
        }
        let conf: [String: AnyObject] = ["run_type": c.run_type as AnyObject,
                                         "local_addr": c.local_addr as AnyObject,
                                         "local_port": NSNumber(value: c.local_port) as AnyObject,
                                         "remote_addr": c.remote_addr as AnyObject,
                                         "remote_port": NSNumber(value: c.remote_port) as AnyObject,
                                         "password": c.password as AnyObject,
                                         "log_level": NSNumber(value: c.log_level ?? 1) as AnyObject,
                                         "ssl": ssl as AnyObject,
                                         "tcp": tcp as AnyObject,
                                         "uuid": uuid as AnyObject,
                                         "group": c.group as AnyObject
                                        ]
        
        return conf
    }
    
    func jsonString() -> String {
        do {
            var data: Data
            if #available(OSX 10.13, *) {
                data =  try JSONSerialization.data(withJSONObject: self.json(), options: [.prettyPrinted, .sortedKeys])
            } else {
                data =  try JSONSerialization.data(withJSONObject: self.json(), options: [.prettyPrinted])
            }
            let convertedString = String(data: data, encoding: String.Encoding.utf8)
            return convertedString ?? ""
        } catch let myJSONError {
            print(myJSONError)
        }
        return ""
    }
}


struct SSL: Codable {
    var verify: Bool?
    var verify_hostname: Bool?
    var cert: String?
    var cipher: String?
    var cipher_tls13: String?
    var sni: String?
    var alpn: [String]?
    var reuse_session: Bool?
    var session_ticket: Bool?
    var curves: String?
    var plain_http_response: String?
    var dhparam: String?
    var prefer_server_cipher: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case verify = "verify"
        case verify_hostname = "verify_hostname"
        case cert = "cert"
        case cipher = "cipher"
        case cipher_tls13 = "cipher_tls13"
        case sni = "sni"
        case alpn = "alpn"
        case reuse_session = "reuse_session"
        case session_ticket = "session_ticket"
        case curves = "curves"
        case plain_http_response = "plain_http_response"
        case dhparam = "dhparam"
        case prefer_server_cipher = "prefer_server_cipher"
    }
}


struct TCP: Codable {
    var no_delay: Bool?
    var keep_alive: Bool?
    var reuse_port: Bool?
    var fast_open: Bool?
    var fast_open_qlen: Int?

    private enum CodingKeys: String, CodingKey {
        case no_delay = "no_delay"
        case keep_alive = "keep_alive"
        case reuse_port = "reuse_port"
        case fast_open = "fast_open"
        case fast_open_qlen = "fast_open_qlen"
    }
}
