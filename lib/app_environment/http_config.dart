class HTTPConfig {
  String baseURL;
  bool logEnabled;

//
  static const defaultBaseURL = 'http://172.16.178.16:8081';//
//  static const _defaultBaseURL = 'http://172.16.126.200:8081';
//  static const defaultBaseURL = 'http://172.16.178.15:8081';

  HTTPConfig({String baseURL, bool logEnabled})
      : baseURL = baseURL ?? defaultBaseURL,
        logEnabled = logEnabled ?? false;

  HTTPConfig.fromJson(Map<String, dynamic> json) {
    baseURL = defaultBaseURL;
    logEnabled = json['logEnabled'] as bool ?? false;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'logEnabled': logEnabled};
  }
}
