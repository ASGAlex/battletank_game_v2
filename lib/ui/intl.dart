import 'package:flutter/widgets.dart';

import '../generated/l10n.dart';

extension Translate on BuildContext {
  S loc() => S.of(this);
}
