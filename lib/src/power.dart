/// Power status of thumper.
enum Power {
  /// Thumper is in an initial state.
  /// It's like [idle], but may have a different UX behavior.
  /// e.g. a reset button should be disabled in this state.
  reset,

  /// Thumper is paused.  Might enabled both a play and reset button.
  idle,

  /// Thumper is running.  Pause button would be enabled, but a reset
  /// button would be disabled.
  running
}
