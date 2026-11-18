# Accessibility verification

Run `swift test` for player button names, playback state labels, readable scrubber
values, and distinct settings field names. Run `./scripts/test-parser.sh` for the
existing parser checks.

Before a release, also exercise the app with a real video on macOS:

- Enable VoiceOver (Command-F5). Navigate the library sidebar and verify each
  section is announced once with its selected state.
- Open a video with Command-O. Verify playback controls stay visible with
  VoiceOver enabled. Check Play/Pause, Mute/Unmute, speed, and playback position
  announcements. Seek with VoiceOver's slider increment/decrement actions.
- Enable macOS Keyboard navigation. Tab and Shift-Tab through the player after
  its controls fade away. Verify controls reveal, focus is visible, and controls
  remain visible for more than ten seconds while focused, including when paused.
  Focus Mute and press Space: it mutes and playback does not pause. Tab back to
  the video and verify the controls fade again after a few seconds.
- Activate Audio tracks and Subtitles with the keyboard and with VoiceOver.
  Verify the menu opens at its button, selection works, and Escape dismisses it.
- Open Settings, verify focus enters it, and check the names of fonts, styles,
  numeric fields, steppers, and colors. Close with Done or Escape and verify
  keyboard playback controls work again.
- Immediately after opening Settings, press Space to toggle the focused
  system-font checkbox. Verify playback does not pause or resume. Use arrow keys
  on settings controls and verify they do not seek or change playback volume.
- Close the video and verify playback controls are absent from VoiceOver
  navigation. Reopen a video and check seeking remains disabled until duration
  becomes available.

Automated checks do not replace VoiceOver, focus traversal, or live playback
verification.
