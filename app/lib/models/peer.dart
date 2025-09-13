class Peer {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final String deviceType;
  final Map<String, String> properties;
  final DateTime discoveredAt;

  Peer({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.deviceType,
    required this.properties,
    required this.discoveredAt,
  });

  factory Peer.fromJson(Map<String, dynamic> json) {
    return Peer(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Device',
      ipAddress: json['ip'] ?? '',
      port: json['port'] ?? 8080,
      deviceType: json['device_type'] ?? 'unknown',
      properties: Map<String, String>.from(json['properties'] ?? {}),
      discoveredAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ipAddress,
      'port': port,
      'device_type': deviceType,
      'properties': properties,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Peer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
