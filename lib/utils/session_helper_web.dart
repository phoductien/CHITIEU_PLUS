import 'dart:html' as html;

bool checkIsReload() {
  final isReload = html.window.sessionStorage.containsKey(
    'chitieu_session_active',
  );
  if (!isReload) {
    html.window.sessionStorage['chitieu_session_active'] = 'true';
  }
  return isReload;
}
