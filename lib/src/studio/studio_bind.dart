import 'dart:io';

/// How the Toolkit Studio HTTP server binds its listen socket.
enum StudioBindMode {
  loopback,
  lan,
}

StudioBindMode parseStudioBindMode(String? raw) {
  return switch (raw?.trim().toLowerCase()) {
    'lan' || 'any' || '0.0.0.0' => StudioBindMode.lan,
    _ => StudioBindMode.loopback,
  };
}

InternetAddress bindAddressFor(StudioBindMode mode) {
  return switch (mode) {
    StudioBindMode.loopback => InternetAddress.loopbackIPv4,
    StudioBindMode.lan => InternetAddress.anyIPv4,
  };
}

/// Non-loopback IPv4 addresses suitable for mobile companion pairing.
Future<List<String>> detectLanIpv4Addresses() async {
  final addresses = <String>{};
  try {
    for (final iface in await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    )) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) {
          addresses.add(addr.address);
        }
      }
    }
  } on Object {
    // NetworkInterface may fail in restricted environments.
  }
  return addresses.toList()..sort();
}

Future<String?> primaryLanIpv4Address() async {
  final addrs = await detectLanIpv4Addresses();
  return addrs.isEmpty ? null : addrs.first;
}
