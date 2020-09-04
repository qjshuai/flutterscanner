import 'package:dio/dio.dart';
import 'package:quiver/strings.dart';

class AuthorizationInterceptor extends Interceptor {
  Function(Response response) invalidTokenCallBack;

  AuthorizationInterceptor(this.invalidTokenCallBack);

  @override
  Future onError(DioError err) async {
    if (err?.response?.statusCode == 401) {
      invalidTokenCallBack(err.response);
    }
    return err; //ErrorEnvelope(err);
  }
}

class ResponseChecker extends Interceptor {
  @override
  Future onResponse(Response response) {
    if (response.data is String) {
      // if ((response.data as String).contains('<html>')) {
      //   response.statusCode = 401;
      //   throw DioError(response: response, type: DioErrorType.RESPONSE, error: null);
      // }
      throw DioError(response: response, type: DioErrorType.RESPONSE, error: response.data);
    }
    final data = response.data as Map<String, dynamic>;
    final code = data['code'] as int ?? 0;
    if (code == 0) {
      return Future<dynamic>.value(response);
    } else {
      var message = data['message'] as String;
      if (isEmpty(message)) {
        message = '错误 code :$code';
      }
      throw DioError(response: response, type: DioErrorType.RESPONSE, error: message);
    }
  }
}
