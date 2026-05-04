import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceSessionModel {
  final String id; // Document ID / Unique session ID
  final String deviceName;
  final String deviceType; // Android, iOS, Windows, etc.
  final String osVersion;
  final DateTime lastActive;
  final bool isCurrentDevice;

  DeviceSessionModel({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.osVersion,
    required this.lastActive,
    this.isCurrentDevice = false,
  });

  bool get isCurrent => isCurrentDevice;

  factory DeviceSessionModel.fromMap(
    Map<String, dynamic> map,
    String docId, {
    String? currentDeviceId,
  }) {
    return DeviceSessionModel(
      id: docId,
      deviceName: map['deviceName'] ?? 'Thiết bị không xác định',
      deviceType: map['deviceType'] ?? 'Unknown',
      osVersion: map['osVersion'] ?? '',
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCurrentDevice: docId == currentDeviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceName': deviceName,
      'deviceType': deviceType,
      'osVersion': osVersion,
      'lastActive': FieldValue.serverTimestamp(),
    };
  }
}
