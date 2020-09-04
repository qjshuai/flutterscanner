import 'package:flutter/material.dart';
import 'package:quiver/strings.dart';
import 'error_envelope.dart';

class AppConfig {
  Locale _locale;

  Locale get locale => _locale ?? _deviceLocale ?? Locale('en', 'US');

  AppConfig({Locale locale}) : _locale = locale;

  AppConfig.fromJson(Map<String, dynamic> json) {
    final languageCode = json['languageCode'] as String;
    final countryCode = json['countryCode'] as String;
    if (isEmpty(languageCode) || isEmpty(countryCode)) {
      throw ErrorEnvelope('languageCode 或 countryCode 为空');
    }
    _locale = Locale(languageCode, countryCode);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode
    };
  }

  AppConfig update({
    Locale locale,
  }) {
    return copyWith(
      locale: locale,
    );
  }

  AppConfig copyWith({
    Locale locale,
  }) {
    return AppConfig(
      locale: locale ?? this.locale,
    );
  }
}

Locale _deviceLocale;

Locale get deviceLocale => _deviceLocale;

set deviceLocale(Locale locale) {
  _deviceLocale ??= locale;
}
