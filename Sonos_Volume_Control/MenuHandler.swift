//
//  MenuHandler.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 02.04.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import ServiceManagement

extension ControlVC {

    @objc func quitApp() {
        NSApp.terminate(self)
    }
    
    @objc func openImprint() {
        NSWorkspace.shared.open(URL(string:"http://sn0wfreeze.de/?p=522")!)
    }
    
    @objc func openLicenses() {
        NSWorkspace.shared.open(URL(string:"http://sn0wfreeze.de/?p=525")!)
    }
    
    @objc func sendFeedback() {
        NSWorkspace.shared.open(URL(string:"mailto:sonos-controller@sn0wfreeze.de")!)
    }
    
    @objc func writeAReview() {
        NSWorkspace.shared.open(URL(string:"macappstore://itunes.apple.com/app/id1357379892?mt=12")!)
    }
    
    @objc func launchAppOnLogin() {
        if UserDefaults.standard.isLaunchAtLoginEnabled {
            self.turnLaunchAtLoginOff()
        }else {
            self.turnLaunchAtLoginOn()
        }
    }
    
    /// Turn on the automatic start of the app when starting the mac
    func turnLaunchAtLoginOn() {
        let loginItemid = "de.sn0wfreeze.Sonos-Volume-Control-Launcher"
//        let loginItemid = "de.sn0wfreeze.Sonos-Volume-Control"
        if SMLoginItemSetEnabled(loginItemid as CFString, true) == false {
            //Failed -> Show alert
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("An error occurred", comment: "Error message text")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: "Okay - Button title"))
            alert.informativeText =  NSLocalizedString("Could not add the app to launch automatically. You can do this manually by using the user settings in system preferences", comment: "Error description text")
            alert.runModal()
        }else {
            UserDefaults.standard.isLaunchAtLoginEnabled = true
            
            //Show alert to inform the user about upcoming pop ups
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Launch at login activated", comment: "Confirm message text")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: "Okay - Button title"))
            alert.informativeText = NSLocalizedString("When you restart the system it will show a pop up asking if you allow the Menu Controller to start. You only need to confirm this once.", comment: "Info text of launch confirmation")
            alert.runModal()
        }

    }
    

    
    /// Turn off the automatic start of the app when starting the mac
    func turnLaunchAtLoginOff() {
        let loginItemid = "de.sn0wfreeze.Sonos-Volume-Control-Launcher"
//        let loginItemid = "de.sn0wfreeze.Sonos-Volume-Control"
        if SMLoginItemSetEnabled(loginItemid as CFString, false) == false {
            //Failed -> Show alert
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("An error occurred", comment: "Error message text")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: "Okay - Button title"))
            alert.informativeText = "Could not stop the app from launching automatically. Check your user settings in System preferences"
            alert.runModal()
        }else {
            UserDefaults.standard.isLaunchAtLoginEnabled = false
        }
    }
}
