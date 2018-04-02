//
//  AppDelegate.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 23.02.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import AVFoundation
import AudioUnit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)

    let popover = NSPopover()
    
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let icon = NSImage(named:NSImage.Name("status_icon"))
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.button?.action = #selector(togglePopover(_:))
        
        popover.contentViewController = ControlVC.freshController()
//        popover.behavior = .transient
        popover.animates = true
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
        eventMonitor?.start()
        
        checkIfLaunchedAutomatically()
    }
    
    func checkIfLaunchedAutomatically() {
        let helperAppId = "de.sn0wfreeze.Sonos-Volume-Control-Launcher"
        let isHelperRunning = !NSWorkspace.shared.runningApplications.filter({$0.bundleIdentifier == helperAppId}).isEmpty
        if isHelperRunning {
            //Inform helper app to kill itself
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier ?? "")
        }else {
            //Show window on start
            self.togglePopover(self)
        }
        
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            NSApplication.shared.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopover(sender: Any?) { 
        self.statusItem.button?.isHighlighted = false
        popover.close()
    }
    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher-Menu-Bar-Controller")
}

