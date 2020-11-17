// 导航监听器
import 'package:flutter/material.dart';

class MyRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route previousRoute) {
    print(
        'push route  from $previousRoute.settings.name   to ${route.settings.name}');
    super.didPush(route, previousRoute);
  }
}
