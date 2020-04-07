//
//  LogWindowController.swift
//  Trojan
//
//  Created by ParadiseDuo on 2020/3/31.
//  Copyright © 2020 Mac. All rights reserved.
//

import Cocoa

class LogWindowController: NSWindowController, NSWindowDelegate {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet var textView: NSTextView!
    
    private var task: Process?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.textView.isEditable = false
        
        self.textView.string = "Log Path: \(LOG_PATH)\n"
        
        let fileMgr = FileManager.default
        if fileMgr.fileExists(atPath: LOG_PATH) {
            self.tail()
        } else {
            NotificationCenter.default.addObserver(forName: TROJAN_START, object: nil, queue: OperationQueue.main) { (noti) in
                if self.task == nil {
                    self.tail()
                }
            }
        }
        NotificationCenter.default.addObserver(forName: LOG_CLEAN_FINISH, object: nil, queue: OperationQueue.main) { (noti) in
            self.textView.string = "Log Path: \(LOG_PATH)\n"
            self.textView.scrollToEndOfDocument(nil)
        }
    }
    
    private func tail() {
        self.task = Process()
        CommandLine.async(task: self.task!, command: "tail -F -n 26 \(LOG_PATH)", output: { (line) in
            self.textView.string += line
            self.textView.scrollToEndOfDocument(nil)
        }) { (finish) in
            print("tail finish")
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        self.task?.interrupt()
        self.task = nil
        
        NotificationCenter.default.removeObserver(self)
    }
    
}
