// extension Network on EnvironmentBloc {
//   Future<List<Group>> fetchScannerInfo(String code) async {
//     final response = await _dio.get<Map<String, dynamic>>(
//         '/roshine/parcelorden/collectParcel',
//         queryParameters: {'serialNumber': code});
//     return (response.data["data"] as List<dynamic>)
//         .map((e) => Group.fromJson(e))
//         .toList();
//   }
//
//   Future<StorageOrder> fetchOrderInfo(String code) async {
//     final response = await _dio.get<Map<String, dynamic>>(
//         '/roshine/parcelorden/selectOrderWarehousing',
//         queryParameters: {'serialNumber': code}); //keyword
//     return StorageOrder.fromJson(response.data["data"]);
//   }
//
//   Future<void> putIn(String code, int id) async {
//     final response = await _dio.get<Map<String, dynamic>>(
//         '/roshine/parcelorden/replaceWarehousing',
//         queryParameters: {'serialNumber': code, 'postStationId': id}); //keyword
//     return;
//   }
// }
//
// ';//'';//