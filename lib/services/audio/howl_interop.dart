@JS()
library howl;

import 'package:js/js.dart';

@JS()
@staticInterop
class Howl {
  external factory Howl(HowlOptions options);
}

extension HowlMethods on Howl {
  external play();

  external pause();

  external stop();

  external mute();

  external volume([double value]);

  external loop([bool loop, dynamic id]);

  external String state();

  external unload();

  external load();
}

@JS()
@anonymous
class HowlOptions {
  external factory HowlOptions({
    required List<String> src,
    bool autoplay = false,
    String format,
    bool html5 = false,
    bool mute = false,
    bool loop = false,
    int pool = 5,
    bool preload = true,
    int rate = 1,
    Object sprite,
    double volume = 1.0,
    Function(dynamic id, dynamic error) onend,
    Function() onfade,
    Function(dynamic id) onload,
    Function(dynamic id, dynamic error) onloaderror,
    Function(dynamic id, dynamic error) onplayerror,
    Function() onpause,
    Function() onplay,
    Function() onstop,
    Function() onmute,
    Function() onvolume,
    Function() onrate,
    Function() onseek,
    Function() onunlock,
  });
}
