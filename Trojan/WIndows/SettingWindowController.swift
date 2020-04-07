//
//  SettingWindowController.swift
//  TrojanMac
//
//  Created by ParadiseDuo on 2020/4/7.
//  Copyright © 2020 ParadiseDuo. All rights reserved.
//

import Cocoa

let tableViewDragType: String = "trojan.server.profile.data"

class SettingWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var scroll: NSScrollView!
    @IBOutlet var textView: NSTextView!
    
    @IBOutlet weak var profilesTableView: NSTableView!
    @IBOutlet weak var copyButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    
    private var closeFromSave = false
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.profilesTableView.delegate = self
        self.profilesTableView.dataSource = self
        
        if let s = Profile.shared.jsonString {
            self.textView.string = s
        }
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    private func decodeJSON(handle: (_ client: Client)->()) {
        do {
            if let d = self.textView.string.data(using: String.Encoding.utf8) {
                let f = try JSONDecoder().decode(Client.self, from: d)
                handle(f)
            } else {
                self.shakeWindows()
            }
        }catch {
            self.shakeWindows()
        }
    }
    
    @IBAction func saveTap(_ sender: NSButton) {
        self.decodeJSON { (c) in
            Profile.shared.client = c
            Profile.shared.saveProfile()
            self.closeFromSave = true
            self.window?.close()
        }
    }
    
    @IBAction func cancelTap(_ sender: NSButton) {
        self.window?.close()
    }
    
    func updateProfileBoxVisible() {
        if Profiles.shared.count() <= 1 {
            removeButton.isEnabled = false
        }else{
            removeButton.isEnabled = true
        }
    }
    
    @IBAction func addTap(_ sender: NSButton) {
        self.decodeJSON {[weak self] (c) in
            guard let w = self else {return}
            w.profilesTableView.beginUpdates()
            let p = Profile()
            p.name = "New Server"
            p.client = c
            if Profiles.shared.add(p) {
                let index = IndexSet(integer: Profiles.shared.count()-1)
                w.profilesTableView.insertRows(at: index, withAnimation: .effectFade)
                w.profilesTableView.scrollRowToVisible(Profiles.shared.count()-1)
                w.profilesTableView.selectRowIndexes(index, byExtendingSelection: false)
                w.profilesTableView.endUpdates()
            } else {
                w.shakeWindows()
            }
        }
    }
    
    @IBAction func copyTap(_ sender: NSButton) {
        
    }
    
    @IBAction func removeTap(_ sender: NSButton) {
        
    }
    
    //--------------------------------------------------
    // MARK: For NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return Profiles.shared.count()
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let (title, isActive) = self.getDataAtRow(row)
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier("main") {
            return title
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier("status") {
            if isActive {
                return NSImage(named: NSImage.Name("NSMenuOnStateTemplate"))
            } else {
                return nil
            }
        }
        return ""
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let p = Profiles.shared.itemAtIndex(row)
        if p != nil {
            p!.name = object as! String
        }
    }
    
    // MARK: Drag & Drop reorder rows
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: NSPasteboard.PasteboardType(rawValue: tableViewDragType))
        return item
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return NSDragOperation()
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        var oldIndexes = [Int]()
        info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:], using: {
            (draggingItem: NSDraggingItem, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if let str = (draggingItem.item as! NSPasteboardItem).string(forType: NSPasteboard.PasteboardType(rawValue: tableViewDragType)), let index = Int(str) {
                oldIndexes.append(index)
            }
        })
        var oldIndexOffset = 0
        var newIndexOffset = 0
        
        tableView.beginUpdates()
        let mgr = Profiles.shared
        for oldIndex in oldIndexes {
            if oldIndex < row {
                let o = mgr.remove(at: oldIndex + oldIndexOffset)
                mgr.insert(o, at:row - 1)
                tableView.moveRow(at: oldIndex + oldIndexOffset, to: row - 1)
                oldIndexOffset -= 1
            } else {
                let o = mgr.remove(at: oldIndex)
                mgr.insert(o, at:row + newIndexOffset)
                tableView.moveRow(at: oldIndex, to: row + newIndexOffset)
                newIndexOffset += 1
            }
        }
        tableView.endUpdates()
        
        return true
    }
    
    //--------------------------------------------------
    // For NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if self.profilesTableView.selectedRow >= 0 {
            let s = Profiles.shared.itemAtIndex(self.profilesTableView.selectedRow)
            if s != nil {
                self.textView.string = s!.jsonString!
            }
        } else {
            let index = IndexSet(integer: Profiles.shared.count()-1)
            self.profilesTableView.selectRowIndexes(index, byExtendingSelection: false)
        }
    }
    
    private func getDataAtRow(_ index:Int) -> (String, Bool) {
        let profile = Profiles.shared.itemAtIndex(index)
        if profile != nil {
            let isActive = (profile!.name == Profile.shared.name)
            return (profile!.name, isActive)
        } else {
            return ("", false)
        }
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
    
    func windowWillClose(_ notification: Notification) {
        if !self.closeFromSave {
            Profiles.shared.load()
        }
    }
}
