//
//   CommandLine.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/4/2.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation


class CommandLine {
    static func async(task: Process, command: String, output: ((String) -> Void)? = nil, terminate: ((Int) -> Void)? = nil) {
        let utf8Command = "export LANG=en_US.UTF-8\n" + command
        async(task: task, shellPath: "/bin/bash", arguments: ["-c", utf8Command], output: output, terminate: terminate)
    }
    
    static func async(task: Process, shellPath: String, arguments: [String]? = nil, output: ((String) -> Void)? = nil, terminate: ((Int) -> Void)? = nil) {
        DispatchQueue.global().async {
            let pipe = Pipe()
            let outHandle = pipe.fileHandleForReading
            
            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            task.environment = environment
            
            if arguments != nil {
                task.arguments = arguments!
            }
            
            task.launchPath = shellPath
            task.standardOutput = pipe
            
            outHandle.waitForDataInBackgroundAndNotify()
            var obs1 : NSObjectProtocol!
            obs1 = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outHandle, queue: nil) {  notification -> Void in
                let data = outHandle.availableData
                if data.count > 0 {
                    if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                        DispatchQueue.main.async {
                            output?(str as String)
                        }
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                } else {
                    NotificationCenter.default.removeObserver(obs1 as Any)
                    pipe.fileHandleForReading.closeFile()
                }
            }

            var obs2 : NSObjectProtocol!
            obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: task, queue: nil) { notification -> Void in
                DispatchQueue.main.async {
                    terminate?(Int(0))
                }
                NotificationCenter.default.removeObserver(obs2 as Any)
            }
            
            task.launch()
            task.waitUntilExit()
        }
    }
}
