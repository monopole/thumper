abstract class ThumperEvent {}

/// Thumper paused and reset to an initial state with the thump
/// countdown restored to its initial value.
class ThumperEventRewound extends ThumperEvent {}

/// Thumper paused; frequency not changed.
/// Thump countdown is reset to its initial value.
class ThumperEventPaused extends ThumperEvent {}

/// Thumper resumed at current frequency.
class ThumperEventResumed extends ThumperEvent {}

/// Thumping frequency increased.
class ThumperEventIncreased extends ThumperEvent {}

/// Thumping frequency decreased.
class ThumperEventDecreased extends ThumperEvent {}

/// Thump and decrement a thump countdown so that automatic thumping
/// can be automatically paused when the countdown reaches zero.
class ThumperEventThumpedAutomatically extends ThumperEvent {}

/// Thump without decrementing a thump countdown.
class ThumperEventThumpedManually extends ThumperEvent {}
