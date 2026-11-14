// class AreasModel {
//   List<Areas>? areas;
//
//   AreasModel({this.areas});
//
//   AreasModel.fromJson(Map<String, dynamic> json) {
//     if (json['areas'] != null) {
//       areas = <Areas>[];
//       json['areas'].forEach((v) {
//         areas!.add(Areas.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     if (areas != null) {
//       data['areas'] = areas!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

class AreasModel {
  int? id;
  String? name;
  dynamic deliveryAmount;

  AreasModel({this.id, this.name, this.deliveryAmount});

  AreasModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    name = json['name']?.toString();
    deliveryAmount = json['delivery_amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['delivery_amount'] = deliveryAmount;
    return data;
  }
}

List<AreasModel> parseAreasPayload(dynamic payload) {
  final rawAreas = _extractAreas(payload);

  return rawAreas
      .whereType<Map>()
      .map((area) => AreasModel.fromJson(Map<String, dynamic>.from(area)))
      .where((area) => area.id != null && area.name?.trim().isNotEmpty == true)
      .toList();
}

List<dynamic> _extractAreas(dynamic payload) {
  if (payload is List) return payload;

  if (payload is Map) {
    if (payload.containsKey('areas')) {
      return _extractAreas(payload['areas']);
    }
    if (payload.containsKey('data')) {
      return _extractAreas(payload['data']);
    }
  }

  throw const FormatException('The areas response has an unsupported format.');
}
