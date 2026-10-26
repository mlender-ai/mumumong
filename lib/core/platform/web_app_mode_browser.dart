import 'dart:js_interop';

@JS('navigator.standalone')
external JSBoolean? get _standalone;
@JS('window.matchMedia')
external _DisplayQuery _matchMedia(JSString query);
extension type _DisplayQuery(JSObject _) implements JSObject {
  external JSBoolean get matches;
}
bool get isInstalledWebApp =>
    _standalone?.toDart == true ||
    _matchMedia('(display-mode: standalone)'.toJS).matches.toDart;
