/// Power status of thumper.
enum Power {
  /// Thumper is in an initial state.
  /// It's like [idle], but may have a different UX behavior.
  /// e.g. a reset button should be disabled in this state.
  reset,

  /// Thumper is paused (might enable a reset button here).
  idle,

  /// Thumper is running.
  running
}
