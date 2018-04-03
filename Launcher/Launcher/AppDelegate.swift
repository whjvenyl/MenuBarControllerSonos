//
//  AppDelegate.swift
//  Launcher
//
//  Created by Alexander Heinrich on 02.04.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        //Check if the app is already running
        let mainAppIdentifier = "de.sn0wfreeze.Sonos-Volume-Control"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty

        
        if !isRunning {
            //Register for notifications
            DistributedNotificationCenter.default().addObserver(self,
                                                                selector: #selector(self.terminate),
                                                                name: .killLauncher,
                                                                object: mainAppIdentifier)
            
            let appName = "Menu Bar Controller for Sonos"
            //Start the app
            let path = Bundle.main.bundlePath
            var pComps = path.components(separatedBy: "/")
            pComps.removeLast(3)
            pComps.append("MacOS")
            pComps.append(appName)
            let newPath = NSString.path(withComponents: pComps)
            let success = NSWorkspace.shared.launchApplication(newPath)
            if !success {
                NSWorkspace.shared.launchApplication("Menu Bar Controller for Sonos")
            }
        }
    }
    
    @objc func terminate() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher-Menu-Bar-Controller")
}
