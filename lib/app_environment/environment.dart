import 'app_config.dart';
import 'appearance.dart';
import 'package:quiver/strings.dart';
import 'http_config.dart';

class Environment {
  static final _appConfigStoreKey = 'com.envirinment.appConfig';
  static final _httpStoreKey = 'com.envirinment.httpConfig';
  static final _appearanceStoreKey = 'com.envirinment.appearanceStoreKey';
  static final _tokenStoreKey = 'com.envirinment.token';

  AppConfig appConfig;

  Appearance appearance;

  HTTPConfig httpConfig;

  String token;

  bool get isAuthenticated => !isEmpty(token);

  Environment({AppConfig appConfig, Appearance appearance, HTTPConfig httpConfig, String token}) {
    this.appConfig = appConfig ?? AppConfig();
    this.appearance = appearance ?? Appearance();
    this.httpConfig = httpConfig ?? HTTPConfig();
    this.token = token;
  }

  Environment.fromJson(Map<String, dynamic> json) {
    appConfig = AppConfig.fromJson(json[_appConfigStoreKey] as Map<String, dynamic>);
    httpConfig = HTTPConfig.fromJson(json[_httpStoreKey] as Map<String, dynamic>);
    appearance = Appearance.fromJson(json[_appearanceStoreKey] as Map<String, dynamic>);
    token = json[_tokenStoreKey] as String;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      _appConfigStoreKey: appConfig.toJson(),
      _httpStoreKey: httpConfig.toJson(),
      _tokenStoreKey: token,
      _appearanceStoreKey: appearance.toJson(),
    };
  }

  Environment update({
    AppConfig appConfig,
    Appearance appearance,
    HTTPConfig httpConfig,
    String token,
  }) {
    return copyWith(
        appConfig: appConfig, appearance: appearance, httpConfig: httpConfig, token: token);
  }

  Environment copyWith({
    AppConfig appConfig,
    Appearance appearance,
    HTTPConfig httpConfig,
    String token,
  }) {
    return Environment(
      appConfig: appConfig ?? this.appConfig,
      appearance: appearance ?? this.appearance,
      httpConfig: httpConfig ?? this.httpConfig,
      token: token ?? this.token,
    );
  }
}
