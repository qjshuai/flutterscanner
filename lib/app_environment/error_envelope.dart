import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class ErrorEnvelope implements Exception {
  /// 错误信息
  String message;

  @override
  String toString() {
    return message ?? '未知错误';
  }

  /*原始错误*/
  dynamic error;

  ErrorEnvelope(dynamic origin) {
    if (origin is ErrorEnvelope) {
      error = origin.error;
      message = origin.message;
    } else {
      error = origin;
      message = _parseErrorMessage(origin);
    }
  }

  ErrorEnvelope.custom(String message, {this.error}) : message = message;

  static final ErrorEnvelope invalidToken = ErrorEnvelope('登录已失效, 请重新登录');
  static final String offlineMessage = '未连接到网络';

  static String _parseErrorMessage(dynamic origin) {
    debugPrint('_parseErrorMessage ${origin}');

    if (origin is ErrorEnvelope) {
      return origin.message;
    }
    if (origin is DioError) {
      if (origin.response?.statusCode == 401 && origin.request.path?.contains('login') != true) {
        return invalidToken.message;
      }
      if (origin.response?.data == null) {
        return origin.message;
      }
      dynamic data = origin.response.data;
      if (data is Map<String, dynamic>) {
        var message = data['message'] as String ?? data['error'] as String;
        debugPrint('_parseErrorMessage ${origin.response.data}');
        if (message == 'No message available') {
          message = '${origin.response?.statusCode} ${data['error'] as String ?? '错误'}';
        }
        return message ?? '未知错误';
      } else {
        return '未知错误';
      }
    } else if (origin is Error) {
      return origin.stackTrace.toString();
    } else if (origin is Exception) {
      return origin.toString();
    } else {
      return origin.toString() ?? '未知错误';
    }
  }
}

//
///// It occurs when url is opened timeout.
//CONNECT_TIMEOUT,
//
///// It occurs when url is sent timeout.
//SEND_TIMEOUT,
//
/////It occurs when receiving timeout.
//RECEIVE_TIMEOUT,
//
///// When the server response, but with a incorrect status, such as 404, 503...
//RESPONSE,
//
///// When the request is cancelled, dio will throw a error with this type.
//CANCEL,
//
///// Default error type, Some other Error. In this case, you can
///// use the DioError.error if it is not null.
//DEFAULT,
