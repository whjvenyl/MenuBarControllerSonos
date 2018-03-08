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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = #imageLiteral(resourceName: "status_icon")
            button.action = #selector(printQuote(_:))
        }
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(togglePopover(_:))
        }
        popover.contentViewController = VolumeControlVC.freshController()
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
    
    
    @objc func printQuote(_ sender: Any?) {
        let quoteText = "Never put off until tomorrow what you can do the day after tomorrow."
        let quoteAuthor = "Mark Twain"
        
        print("\(quoteText) — \(quoteAuthor)")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func discoverSonos() {
        
    }
    
    func installKeyEventListener() {
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { (event) in
            let characters = event.characters
            let s = event.isARepeat
            let keyCode = event.keyCode
            
            print("Characters: ", characters)
            print("KeyCode: ", keyCode)
            print("Repeat ", s)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { (event) -> NSEvent? in
            let characters = event.characters
            let s = event.isARepeat
            let keyCode = event.keyCode
            
            print("Characters: ", characters)
            print("KeyCode: ", keyCode)
            print("Repeat ", s)
            return event
        }
    }
    
    func readAudioPlayerVolume() {
        let sampleFileURL = Bundle.main.url(forResource: "SampleAudio_0.4mb", withExtension: "mp3")
        do {
            let player = try AVAudioPlayer.init(contentsOf: sampleFileURL!)
            print("Player Volume:" , player.volume)
        }catch(let e) {
            print(e)
        }
        
        
    }
    
    func listenToVolumeChanges() {
        var deviceID: AudioObjectID = AudioObjectID(0)
        var size: UInt32 = UInt32(MemoryLayout<AudioObjectID>.size)
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        
        address.mSelector = kAudioHardwarePropertyDefaultOutputDevice
        address.mScope = kAudioObjectPropertyScopeGlobal
        address.mElement = kAudioObjectPropertyElementMaster
        
        let result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        
        if result != kAudioHardwareNoError {
            print("Error handling audio", result)
        }
        
        var propertyAddress = AudioObjectPropertyAddress()
        propertyAddress.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume
        propertyAddress.mScope = kAudioDevicePropertyScopeOutput
        propertyAddress.mElement = kAudioObjectPropertyElementMaster
        
        var volume: Float = Float()
        size = UInt32(MemoryLayout<Float>.size)
        let volumeResult = AudioHardwareServiceGetPropertyData(deviceID, &propertyAddress,0, nil, &size, &volume)
        
        if volumeResult != kAudioHardwareNoError {
            print("Error handling volume", volumeResult)
        }
        
        print("Current volume", volume)
    }


}

