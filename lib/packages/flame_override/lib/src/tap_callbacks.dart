import 'package:flame/game.dart';
import 'package:flame/src/components/core/component.dart';
import 'package:flame/src/events/messages/tap_cancel_event.dart';
import 'package:flame/src/events/messages/tap_down_event.dart';
import 'package:flame/src/events/messages/tap_up_event.dart';
import 'package:meta/meta.dart';
import 'package:tank_game/packages/flame_override/lib/src/has_tappable_components.dart';

/// This mixin can be added to a [Component] allowing it to receive tap events.
///
/// In addition to adding this mixin, the component must also implement the
/// [containsLocalPoint] method -- the component will only be considered
/// "tapped" if the point where the tap has occurred is inside the component.
///
/// This mixin is the replacement of the Tappable mixin.
mixin TapCallbacks on Component {
  late final MultiTapDispatcher _dispatcher;

  void onTapDown(TapDownEvent event) {}

  void onLongTapDown(TapDownEvent event) {}

  void onTapUp(TapUpEvent event) {}

  void onTapCancel(TapCancelEvent event) {}

  @override
  @mustCallSuper
  void onMount() {
    super.onMount();
    final game = findGame()! as FlameGame;

    var dispatcher = game.firstChild<MultiTapDispatcher>();
    if (dispatcher == null) {
      dispatcher = MultiTapDispatcher();
      game.add(dispatcher);
    }
    dispatcher.tapCallbacksComponents.add(this);
    _dispatcher = dispatcher;
  }

  @override
  void onRemove() {
    super.onRemove();
    _dispatcher.tapCallbacksComponents.remove(this);
  }
}
