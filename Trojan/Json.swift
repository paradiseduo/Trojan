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
    var log_level: Int
    var ssl: SSL
    var tcp: TCP

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
    }
}


struct SSL: Codable {
    var verify: Bool
    var verify_hostname: Bool
    var cert: String
    var cipher: String
    var cipher_tls13: String
    var sni: String
    var alpn: [String]
    var reuse_session: Bool
    var session_ticket: Bool
    var curves: String

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
    }
}


struct TCP: Codable {
    var no_delay: Bool
    var keep_alive: Bool
    var reuse_port: Bool
    var fast_open: Bool
    var fast_open_qlen: Int

    private enum CodingKeys: String, CodingKey {
        case no_delay = "no_delay"
        case keep_alive = "keep_alive"
        case reuse_port = "reuse_port"
        case fast_open = "fast_open"
        case fast_open_qlen = "fast_open_qlen"
    }
}
