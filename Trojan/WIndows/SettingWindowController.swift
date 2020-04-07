//
//  SettingWindowController.swift
//  TrojanMac
//
//  Created by ParadiseDuo on 2020/4/7.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Cocoa

class SettingWindowController: NSWindowController {

    @IBOutlet weak var scroll: NSScrollView!
    @IBOutlet var textView: NSTextView!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        Profile.shared.loadProfile()
        if let s = Profile.shared.jsonString {
            self.textView.string = s
        }
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    
    @IBAction func saveTap(_ sender: NSButton) {
        do {
            if let d = self.textView.string.data(using: String.Encoding.utf8) {
                let f = try JSONDecoder().decode(Client.self, from: d)
                Profile.shared.client = f
                Profile.shared.saveProfile()
                self.window?.close()
            } else {
                self.shakeWindows()
            }
        }catch {
            self.shakeWindows()
        }
    }
    
    @IBAction func cancelTap(_ sender: NSButton) {
        self.window?.close()
    }
    
    func shakeWindows() {
        let numberOfShakes:Int = 8
        let durationOfShake:Float = 0.5
        let vigourOfShake:Float = 0.05
        
        let frame:CGRect = (window?.frame)!
        let shakeAnimation = CAKeyframeAnimation()
        
        let shakePath = CGMutablePath()
        
        shakePath.move(to: CGPoint(x:NSMinX(frame), y:NSMinY(frame)))
        
        for _ in 1...numberOfShakes{
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) - frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) + frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
        }
        
        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = CFTimeInterval(durationOfShake)
        window?.animations = ["frameOrigin":shakeAnimation]
        window?.animator().setFrameOrigin(window!.frame.origin)
    }
}
