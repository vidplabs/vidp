import AppKit
import XCTest
@testable import Vidp

final class AccessibilityTests: XCTestCase {
    @MainActor
    func testSettingsKeepUnmodifiedKeysOutOfPlaybackMenu() {
        _ = NSApplication.shared
        let validator = PlaybackShortcutValidator()
        let menu = PlaybackMenu(title: "Playback")
        menu.settingsOpen = { validator.settingsOpen }
        let mainMenu = NSMenu(title: "Main")
        let playbackItem = NSMenuItem(title: "Playback", action: nil, keyEquivalent: "")
        playbackItem.submenu = menu
        mainMenu.addItem(playbackItem)
        let item = NSMenuItem(title: "Play/Pause", action: #selector(PlaybackShortcutValidator.activate(_:)), keyEquivalent: " ")
        item.keyEquivalentModifierMask = []
        item.target = validator
        menu.addItem(item)
        let space = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, characters: " ", charactersIgnoringModifiers: " ",
            isARepeat: false, keyCode: 49)!

        validator.settingsOpen = true
        XCTAssertFalse(mainMenu.performKeyEquivalent(with: space))
        XCTAssertEqual(validator.activations, 0)
        // Shift-arrow seeks must also yield to settings controls.
        item.keyEquivalentModifierMask = .shift
        XCTAssertFalse(validator.validateMenuItem(item))
        // Keep modified commands, such as Command-W, available.
        item.keyEquivalentModifierMask = .command
        XCTAssertTrue(validator.validateMenuItem(item))

        validator.settingsOpen = false
        item.keyEquivalentModifierMask = []
        XCTAssertTrue(mainMenu.performKeyEquivalent(with: space))
        XCTAssertEqual(validator.activations, 1)
    }

    @MainActor
    private func descendants(of view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }

    @MainActor
    func testPlayerButtonsHaveNamesAndReflectPlaybackState() {
        _ = NSApplication.shared
        let hud = HUDOverlayView(frame: NSRect(x: 0, y: 0, width: 1000, height: 600))
        let buttons = descendants(of: hud).compactMap { $0 as? NSButton }
        XCTAssertEqual(buttons.count, 13)
        XCTAssertTrue(buttons.allSatisfy { !($0.accessibilityLabel() ?? "").isEmpty })
        XCTAssertTrue(buttons.allSatisfy { $0.focusRingType != .none })
        let play = buttons.first { $0.accessibilityLabel() == "Play" }
        let mute = buttons.first { $0.accessibilityLabel() == "Mute" }
        XCTAssertNotNil(play)
        XCTAssertNotNil(mute)
        hud.updatePlayIcon(paused: false)
        hud.updateMuteIcon(muted: true)
        XCTAssertEqual(play?.accessibilityLabel(), "Pause")
        XCTAssertEqual(mute?.accessibilityLabel(), "Unmute")
        hud.updatePlayIcon(paused: true)
        hud.updateMuteIcon(muted: false)
        XCTAssertEqual(play?.accessibilityLabel(), "Play")
        XCTAssertEqual(mute?.accessibilityLabel(), "Mute")
    }

    @MainActor
    func testUnloadedPlayerControlsAreHidden() {
        _ = NSApplication.shared
        let hud = HUDOverlayView(frame: .zero)
        XCTAssertTrue(hud.isHidden)
        hud.setFileLoaded(true)
        XCTAssertFalse(hud.isHidden)
        hud.setFileLoaded(false)
        XCTAssertTrue(hud.isHidden)
        let slider = descendants(of: hud).compactMap { $0 as? NSSlider }.first
        XCTAssertEqual(slider?.isEnabled, false)
    }

    @MainActor
    func testScrubberDescribesTimeInsteadOfFraction() {
        let slider = ScrubSlider(value: 0.5, minValue: 0, maxValue: 1, target: nil, action: nil)
        XCTAssertEqual(slider.accessibilityValueDescription(), "Unavailable")
        slider.mediaDuration = 180
        XCTAssertEqual(
            slider.accessibilityValueDescription(),
            "0 hours, 1 minutes, 30 seconds of 0 hours, 3 minutes, 0 seconds")
        slider.mediaDuration = .nan
        XCTAssertEqual(slider.accessibilityValueDescription(), "Unavailable")
    }

    @MainActor
    func testSettingsFieldsHaveDistinctNames() {
        _ = NSApplication.shared
        let settings = SettingsSidebarView(frame: .zero)
        let controls = descendants(of: settings).filter {
            $0 is NSPopUpButton || $0 is NSColorWell || $0 is NSStepper
                || ($0 as? NSTextField)?.isEditable == true
        }
        let names = controls.compactMap { $0.accessibilityLabel() }
        XCTAssertFalse(controls.isEmpty)
        XCTAssertEqual(names.count, controls.count)
        XCTAssertEqual(Set(names).count, names.count)
    }
}

@MainActor
private final class PlaybackShortcutValidator: NSObject, NSMenuItemValidation {
    var settingsOpen = false
    var activations = 0

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        AppDelegate.settingsAllowPlaybackShortcut(menuItem, settingsOpen: settingsOpen)
    }

    @objc func activate(_ sender: NSMenuItem) {
        activations += 1
    }
}
