import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/src/camera/viewport.dart';
import 'package:flame/src/components/mixins/coordinate_transform.dart';
import 'package:flame/src/events/messages/position_event.dart';

extension DeliverAtPoint on PositionEvent {
  /// Sends the event to components of type <T> that are currently rendered at
  /// the [canvasPosition].
  void deliverAtPointCached<T extends Component>({
    required Set<T> supportedComponents,
    required void Function(T component) eventHandler,
    bool deliverToAll = false,
  }) {
    for (final component in supportedComponents) {
      if (!component.isScreenPointOnComponent(canvasPosition)) continue;
      eventHandler(component);
      if (!continuePropagation) {
        CameraComponent.currentCameras.clear();
        break;
      }
    }
  }
}

mixin ScreenPointOnComponentCached on PositionComponent {
  Rect? _cachedScreenRect;

  @override
  FutureOr<void> onLoad() {
    transform.addListener(_onTransformChanged);
    return super.onLoad();
  }

  @override
  void onRemove() {
    transform.removeListener(_onTransformChanged);
    super.onRemove();
  }

  bool isScreenPointOnComponent(Vector2 point) {
    _cachedScreenRect ??= getComponentRectOnScreen();
    return _cachedScreenRect?.containsPoint(point) ?? false;
  }

  void _onTransformChanged() {
    _cachedScreenRect = null;
  }
}

extension ScreenPointOnComponent on Component {
  Rect? getComponentRectOnScreen() {
    Vector2? topLeft;
    Vector2? bottomRight;
    for (final component in ancestors(includeSelf: true)) {
      if (component is CoordinateTransform) {
        topLeft =
            (component as CoordinateTransform).localToParent(Vector2.zero());
        if (component is PositionComponent) {
          bottomRight = component.localToParent(component.size);
        }
      } else if (component is Viewport) {
        topLeft?.translate(component.position.x, component.position.y);
        bottomRight?.translate(component.position.x, component.position.y);
      }
    }
    if (topLeft != null && bottomRight != null) {
      return Rect.fromLTRB(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
    }
    return null;
  }

  bool isScreenPointOnComponent(Vector2 point) =>
      getComponentRectOnScreen()?.containsPoint(point) ?? false;
}
