import 'package:quiver/iterables.dart';
import 'http_config.dart';
import 'environment.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'environment_event.dart';
import 'package:flutter/material.dart';
import 'environment_repository.dart';
import 'package:dio/dio.dart';
import 'package:quiver/strings.dart';
import 'authlization_interceptor.dart';
import 'package:scanner/group.dart';

class EnvironmentBloc extends Bloc<EnvironmentEvent, Environment> {
  EnvironmentBloc(this.initialState, EnvironmentRepository repository) {
    _repository = repository;
    _dio = _makeDio();
  }

  @override
  Environment initialState;

  EnvironmentRepository _repository = EnvironmentRepository();
  Dio _dio;

  Dio _makeDio() {
    final code = state.appConfig.locale.languageCode;
    final headers = {
      'Accept-Language': code,
      'version': '1',
      'bundleid': 'com.js.scanner',
      'platform': 'flutter'
    };
    if (!isEmpty(state.token)) {
      headers['Authorization'] = state.token;
    }
    final dio = Dio(BaseOptions(
        baseUrl: state.httpConfig.baseURL,
        connectTimeout: 15000,
        headers: headers,
        validateStatus: (code) => range(200, 399).contains(code)));

    dio.interceptors
      ..add(AuthorizationInterceptor((_) {
        add(EnvironmentLogout());
      }))
      ..add(ResponseChecker())
      ..add(LogInterceptor(requestBody: true, responseBody: true));
    return dio;
  }

  void _resetDio() {
    _dio = _makeDio();
  }

  static Future<EnvironmentBloc> restore() async {
    final repository = EnvironmentRepository();
    final environment = await repository.restoreEnvironment() ?? Environment();
    final bloc = EnvironmentBloc(environment, repository);
    return bloc;
  }

  @override
  Stream<Environment> mapEventToState(EnvironmentEvent event) async* {
    if (event is EnvironmentLogin) {
      yield* _mapLoggedInToState(event.token);
      _resetDio();
    } else if (event is EnvironmentLogout) {
      yield* _mapLoggedOutToState();
      _resetDio();
    } else if (event is EnvironmentLocalChanged) {
      yield* _mapLocalChangedToState(event.local);
      _resetDio();
    } else if (event is EnvironmentHttpBaseURLChanged) {
      yield* _mapUrlChangedToState(event.url);
      _resetDio();
    }
    await _repository.saveEnvironment(state);
  }

  Stream<Environment> _mapUrlChangedToState(String url) async* {
    final httpConfig =
        HTTPConfig(baseURL: url, logEnabled: state.httpConfig.logEnabled);
    yield state.update(httpConfig: httpConfig);
  }

  Stream<Environment> _mapLoggedInToState(String token) async* {
    yield state.update(token: token);
  }

  Stream<Environment> _mapLoggedOutToState() async* {
//    await logout();
    yield state.update(token: '');
  }

  Stream<Environment> _mapLocalChangedToState(Locale locale) async* {
    final appConfig = state.appConfig.update(locale: locale);
    yield state.update(appConfig: appConfig);
  }
}

extension Network on EnvironmentBloc {

  Future<List<Group>> fetchScannerInfo(String code) async {
    final response = await _dio.get<Map<String, dynamic>>(
        '/roshine/parcelorden/collectParcel',
        queryParameters: {'serialNumber': code});
    return (response.data["data"] as List<dynamic>)
        .map((e) => Group.fromJson(e))
        .toList();
  }
}
