String routeFromMessage(
  Map<String, dynamic> data, {
  required String fallbackRoute,
}) {
  final route = data['route'];
  if (route is! String || route.isEmpty) return fallbackRoute;
  return route.startsWith('/') ? route : '/$route';
}
