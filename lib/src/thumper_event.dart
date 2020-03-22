/// Thumper events.
enum ThumperEvent {
  /// Thumper paused and reset to an initial state with the thump
  /// countdown restored to its initial value.
  rewound,

  /// Thumper paused; speed not changed.
  /// Thump countdown is reset to its initial value.
  paused,

  /// Thumper resumed at current speed.
  resumed,

  /// Thumping speed increased.
  accelerated,

  /// Thumping speed decreased.
  decelerated,

  /// Thump and decrement a thump countdown so that automatic thumping
  /// can be automatically paused when the countdown reaches zero.
  thumpedAutomatically,

  /// Thump without decrementing a thump countdown.
  thumpedManually,
}
