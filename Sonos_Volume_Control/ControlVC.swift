//
//  VolumeControlVC.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 06.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

class ControlVC: NSViewController {

    //MARK: Properties
    @IBOutlet weak var sonosStack: NSStackView!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var errorMessageLabel: NSTextField!
    @IBOutlet weak var controlsView: NSView!
    @IBOutlet weak var pauseButton: PlayPauseButton!
    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var sonosScrollContainer: CustomScrolllView!
    @IBOutlet weak var speakerGroupSelector: NSSegmentedControl!
    @IBOutlet weak var currentTrackLabel: NSTextField!
    @IBOutlet weak var trackLabelLeading: NSLayoutConstraint!
    
    let defaultHeight: CGFloat = 143.0
    let defaultWidth:CGFloat = 228.0
    let maxHeight: CGFloat = 215.0
    
    let sCntrl = SonosController.shared

    var speakerButtons: [SonosDevice: NSButton] = [:]
    var groupButtons: [SonosSpeakerGroup: NSButton] = [:]
    
    var showState = ShowState.speakers
    
    var isAnimating = false
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.sCntrl.delegate = self
        
        if sCntrl.sonosSystems.count == 0 {
            errorMessageLabel.isHidden = false
        }
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.sCntrl.searchForDevices()
        updateState()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.setupScrollView()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        self.stopAnimations()
    }
    
    func updateSonosDeviceList() {
        guard self.showState == .speakers else {return}
        
        //Remove error label
        if self.sCntrl.sonosSystems.count > 0 {
            self.errorMessageLabel.isHidden = true
            self.controlsView.isHidden = false
        }else {
            self.errorMessageLabel.isHidden = false
            self.controlsView.isHidden = true
        }
        
        //Remove all buttons
        for view in self.sonosStack.subviews {
            self.sonosStack.removeView(view)
        }
        
        
        //Add all sonos buttons
        for sonos in sCntrl.sonosSystems {
            let button = NSButton(checkboxWithTitle: sonos.readableName, target: sonos, action: #selector(SonosDevice.activateDeactivate(button:)))
            button.state = sonos.active ? .on : .off
            button.font = NSFont.systemFont(ofSize: 12.5)
            self.sonosStack.addArrangedSubview(button)
            self.speakerButtons[sonos] = button
            sonos.delegate = self
        }
        
        self.setupScrollView()
    }
    
    func updateGroupsList() {
        guard self.showState == .groups else {return}
        
        //Remove error label or show it if necessary
        if self.sCntrl.sonosGroups.count > 0 {
            self.errorMessageLabel.isHidden = true
            self.controlsView.isHidden = false
        }else {
            self.errorMessageLabel.isHidden = false
            self.controlsView.isHidden = true
        }
        
        //Remove all buttons
        for view in self.sonosStack.subviews {
            self.sonosStack.removeView(view)
        }
        
        var sonosGroupArray = Array(self.sCntrl.sonosGroups.values)
        
        sonosGroupArray.sort { (lhs, rhs) -> Bool in
            return  lhs.name < rhs.name
        }
        
        //Add all sonos buttons
        for (idx, group) in sonosGroupArray.enumerated() {
            //Guard against empty name groups
            guard !group.name.isEmpty  else {return}
            
            if idx == 0 && self.sCntrl.activeGroup == nil {
                group.isActive = true
            }
            
            group.delegate = self
            
            let button = NSButton(radioButtonWithTitle: group.name, target: group, action: #selector(SonosSpeakerGroup.activateDeactivate(button:)))
            button.state = group.isActive ? .on : .off
            self.sonosStack.addArrangedSubview(button)
            self.groupButtons[group] = button
        }
        
        self.setupScrollView()
    }
    
    func setupScrollView() {
       self.sonosScrollContainer.scrollToTop()
       self.sonosScrollContainer.isScrollingEnabled = self.sCntrl.sonosSystems.count > 4
    }
    
    func updateState() {
        switch self.showState {
        case .groups:
            self.updateStateForGroupMode()
        case .speakers:
            self.updateStateForSpeakerMode()
        }
    }
    
    func updateStateForGroupMode() {
        self.sCntrl.activeGroup?.getGroupVolume({ (volume) in
            self.volumeSlider.integerValue = volume
        })
        
        //Update track info
        self.sCntrl.activeGroup?.updateCurrentTrack({ (trackInfo) in
            self.updateTrackLabel(withTrack: trackInfo.trackText())
            //Update buttons
            self.sCntrl.activeGroup?.getPlayState({ (state) in
                self.updatePlayButton(forState: state, isPlayingRadio: trackInfo.isPlayingRadio)
            })
        })
    }
    
    func updateStateForSpeakerMode() {
        let firstSonos = sCntrl.sonosSystems.first(where: {$0.active})
        firstSonos?.getVolume({ (volume) in
            if firstSonos?.muted == true {
                self.volumeSlider.integerValue = 0
            }else {
                self.volumeSlider.integerValue = volume
            }
        })
        
        if let coordinator = sCntrl.sonosSystems.first(where: {$0.active && $0.isGroupCoordinator}) {
            //Update track
            coordinator.updateCurrentTrack({ (trackInfo) in
                self.updateTrackLabel(withTrack: trackInfo.trackText())
                //Update buttons
                coordinator.getPlayState({ (state) in
                    self.updatePlayButton(forState: state, isPlayingRadio: trackInfo.isPlayingRadio)
                })
            })
        }else {
            //Hide buttons
            self.controlsView.isHidden = true
        }
    }
    
    func updateTrackLabel(withTrack track: String) {
        self.stopAnimations()
        self.currentTrackLabel.stringValue = track
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.animateTrackLabel()
        }

    }
    
    func animateTrackLabel() {
        guard self.currentTrackLabel.frame.width > self.view.frame.width, isAnimating == false else {return}
        
        self.isAnimating = true
        self.trackLabelLeading.constant = 8
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 10.0
            self.trackLabelLeading.animator().constant = -self.currentTrackLabel.frame.width
        }) {
            guard self.isAnimating else {return}
            self.trackLabelLeading.constant = self.currentTrackLabel.frame.width
            //Completed one way
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 10.0
                self.trackLabelLeading.animator().constant = 8
            }, completionHandler: {
                self.isAnimating = false
            })
        }
    }
    
    func stopAnimations() {
        self.isAnimating = false
        
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.1
            self.trackLabelLeading.animator().constant = 8
        }, completionHandler: nil)
    }
    
    func updatePlayButton(forState state: PlayState, isPlayingRadio: Bool) {
        switch (state) {
        case .playing, .transitioning:
            self.controlsView.isHidden = false
            
            if isPlayingRadio {
                self.pauseButton.currentState = .stop
            }else {
                self.pauseButton.currentState = .pause
            }
        case .paused, .stopped:
            self.pauseButton.currentState = .play
            self.controlsView.isHidden = false
        default:
            self.controlsView.isHidden = true
        }
        
        if isPlayingRadio {
            self.nextButton.isHidden = true
            self.previousButton.isHidden = true
        }else {
            self.nextButton.isHidden = false
            self.previousButton.isHidden = false
        }
    }
    
    //MARK: - Interactions
    
    @IBAction func switchSpeakerGroups(_ sender: Any) {
        let selected = self.speakerGroupSelector.indexOfSelectedItem
        if (selected == 0) {
            //Show speakers
            self.showState = .speakers
            self.updateSonosDeviceList()
        }else {
            //Show groups
            self.showState = .groups
            self.updateGroupsList()
        }
        self.updateState()
    }
    
    @IBAction func setVolume(_ sender: NSSlider) {
        switch self.showState {
        case .speakers:
            for sonos in sCntrl.sonosSystems {
                guard sonos.active else {continue}
                sonos.setVolume(volume: sender.integerValue)
            }
        case .groups:
            self.sCntrl.activeGroup?.setVolume(volume: sender.integerValue)
        }
        
    }
    
    @IBAction func playPause(_ sender: Any) {
        let actionState = self.pauseButton.currentState
        
        switch self.showState {
        case .speakers:
            for sonos in sCntrl.sonosSystems {
                guard sonos.active else {continue}
                self.playPause(forSonos: sonos, actionState: actionState)
            }
            
        case .groups:
            switch actionState {
            case .play:
                self.sCntrl.activeGroup?.play()
                self.updatePlayButton(forState: .playing, isPlayingRadio: self.sCntrl.activeGroup?.trackInfo?.isPlayingRadio ?? false)
            case .pause, .stop:
                self.sCntrl.activeGroup?.pause()
                self.updatePlayButton(forState: .paused, isPlayingRadio: self.sCntrl.activeGroup?.trackInfo?.isPlayingRadio ?? false)
            }
        }
        
    }
    
    private func playPause(forSonos sonos: SonosDevice, actionState: PlayPauseButton.State) {
        //Play or pause based on the button state
        switch actionState {
        case .pause, .stop:
            sonos.pause()
        case .play:
            sonos.play()
        }
        self.updatePlayButton(forState: sonos.playState, isPlayingRadio: sonos.trackInfo?.isPlayingRadio ?? false)
    }
    
    private func pause(sonos: SonosDevice) {
        
    }
    
    private func play(sonos: SonosDevice) {
        
    }
    
    @IBAction func nextTrack(_ sender: Any) {
        switch self.showState {
        case .speakers:
            for sonos in sCntrl.sonosSystems {
                guard sonos.active else {continue}
                sonos.next()
            }
        case .groups:
            self.sCntrl.activeGroup?.next()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateState()
        }
        
    }
    
    @IBAction func prevTrack(_ sender: Any) {
        switch self.showState {
        case .speakers:
            for sonos in sCntrl.sonosSystems {
                guard sonos.active else {continue}
                sonos.previous()
            }
        case .groups:
            self.sCntrl.activeGroup?.previous()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateState()
        }
    }
    
    @IBAction func showMenu(_ sender: NSView) {
        let appMenu = NSMenu()
        if UserDefaults.standard.isLaunchAtLoginEnabled {
            appMenu.addItem(withTitle: NSLocalizedString("Stop launching App on startup", comment: "menu item"), action: #selector(launchAppOnLogin), keyEquivalent: "")
        }else {
            appMenu.addItem(withTitle: NSLocalizedString("Launch App on startup", comment: "menu item"), action: #selector(launchAppOnLogin), keyEquivalent: "")
        }
        
        appMenu.addItem(withTitle: NSLocalizedString("Write a review", comment: "menu item"), action: #selector(writeAReview), keyEquivalent: "")
        appMenu.addItem(withTitle: NSLocalizedString("Send Feedback", comment: "Send feedback menu item"), action: #selector(sendFeedback), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: NSLocalizedString("Show Imprint", comment: "menu item"), action: #selector(openImprint), keyEquivalent: "")
        appMenu.addItem(withTitle: NSLocalizedString("Software licenses", comment: "menu item"), action: #selector(openLicenses), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: NSLocalizedString("Quit", comment: "menu item"), action: #selector(quitApp), keyEquivalent: "")
        
        
        let p = NSPoint(x: sender.frame.origin.x, y: sender.frame.origin.y - (sender.frame.height / 2))
        appMenu.popUp(positioning: nil, at: p, in: sender.superview)
        
        
    }
    
    enum ShowState {
        case groups
        case speakers
    }
}

extension ControlVC: SonosControllerDelegate {
    func didUpdateSpeakers() {
        self.update()
    }
    
    func didUpdateGroups() {
        switch self.showState {
        case .speakers:
            self.updateSonosDeviceList()
        case .groups:
            self.updateGroupsList()
        }
        
        if self.sCntrl.sonosSystems.count > 0 {
            self.updateState()
        }
    }
    
    func update() {
        switch self.showState {
        case .speakers:
            self.updateSonosDeviceList()
        case .groups:
            self.updateGroupsList()
        }
        
        if self.sCntrl.sonosSystems.count > 0 {
            self.updateState()
        }
    }
}

//MARK: - Sonos Discovery
extension ControlVC {
    // MARK: Storyboard instantiation
    static func freshController() -> ControlVC {
        //1.
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        //2.
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "VolumeControlVC")
        //3.
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ControlVC else {
            fatalError("Why cant i find QuotesViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}

//MARK: Sonos Delegate
extension ControlVC: SonosDeviceDelegate {
    func didUpdateActiveState(forSonos sonos: SonosDevice, isActive: Bool) {
        self.updateState()
    }
}

extension ControlVC: SonosSpeakerGroupDelegate {
    func didChangeActiveState(group: SonosSpeakerGroup) {
        //Deactivate other groups
        for g in self.sCntrl.sonosGroups.values {
            guard g != group else {continue}
            g.isActive = false
            self.groupButtons[g]?.state = .off
        }
        self.updateState()
    }
}


