import 'package:environment/app_bloc.dart';
import 'package:get_it/get_it.dart';

extension UrlImage on String {
  /// webp
  String get imageUrl {
    return '$commonImageUrl.webp';
  }

  /// png or jpg
  String get commonImageUrl {
    return '${GetIt.instance.get<AppBloc>().state.environment.resourceUrl}/${this}';
  }
}
