import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

abstract class EnvironmentEvent extends Equatable {}

class EnvironmentLogout extends EnvironmentEvent {
  @override
  List<Object> get props => [];
}

class EnvironmentLogin extends EnvironmentEvent {
  final String token;

  EnvironmentLogin({@required this.token});

  @override
  List<Object> get props => [token];
}

class EnvironmentLocalChanged extends EnvironmentEvent {
  final Locale local;

  EnvironmentLocalChanged(this.local);

  @override
  List<Object> get props => [local];
}

class EnvironmentHttpBaseURLChanged extends EnvironmentEvent {
  final String url;

  EnvironmentHttpBaseURLChanged(this.url);

  @override
  List<Object> get props => [url];
}
