
/// 扫码状态
abstract class ScanState {}

class ScanningState implements ScanState {}

/// 扫码错误
class ScanErrorState implements ScanState {
  final String error;

  ScanErrorState(this.error);
}

///扫码成功 获取订单信息中
class FetchingState implements ScanState {}

/// 订单信息获取出错
class FetchingErrorState implements ScanState {
  final String error;

  FetchingErrorState(this.error);
}

/// 获取订单信息成功, 仅不需要提交的订单
class FetchSuccessState implements ScanState {}

/// 获取订单信息成功 正在提交
class SubmitSuccessState implements ScanState {}

/// 提交成功
class SubmittingErrorState implements ScanState {
  final String error;

  SubmittingErrorState(this.error);
}