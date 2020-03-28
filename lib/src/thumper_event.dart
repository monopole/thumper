/// Thumper events.
enum ThumperEvent {
  /// Thumper paused and reset to an initial state with the thump
  /// countdown restored to its initial value.
  rewound,

  /// Thumper paused; frequency not changed.
  /// Thump countdown is reset to its initial value.
  paused,

  /// Thumper resumed at current frequency.
  resumed,

  /// Thumping frequency increased.
  increased,

  /// Thumping frequency decreased.
  decreased,

  /// Thump and decrement a thump countdown so that automatic thumping
  /// can be automatically paused when the countdown reaches zero.
  thumpedAutomatically,

  /// Thump without decrementing a thump countdown.
  thumpedManually,
}
