import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../models/experiment_config.dart';
import '../models/experiment_user.dart';
import '../models/server_zone.dart';
import '../models/variant.dart';

/// A pure Dart implementation of the Amplitude Experiments fetch client.
///
/// This client is used as a fallback when the native SDK fails due to DNS
/// resolution issues. It uses a custom DNS resolver that falls back to
/// public DNS servers (Google 8.8.8.8 and Cloudflare 1.1.1.1) when the
/// system DNS fails.
class DartFetchClient {
  DartFetchClient({
    required this.deploymentKey,
    required this.config,
  });

  final String deploymentKey;
  final ExperimentConfig config;

  /// Fallback DNS servers to use when system DNS fails.
  static const List<String> _fallbackDnsServers = [
    '8.8.8.8', // Google
    '1.1.1.1', // Cloudflare
    '8.8.4.4', // Google secondary
    '1.0.0.1', // Cloudflare secondary
  ];

  /// Cached variants from the last successful fetch.
  Map<String, Variant> _cachedVariants = {};

  /// Returns the hostname based on the configured server zone.
  String get _hostname => switch (config.serverZone) {
        ServerZone.us => 'api.lab.amplitude.com',
        ServerZone.eu => 'api.lab.eu.amplitude.com',
      };

  /// Fetches variants for the given user using custom DNS resolution.
  Future<void> fetch(ExperimentUser? user) async {
    // Pre-resolve DNS with fallback before making HTTP request
    final addresses = await _resolveWithFallback(_hostname);
    if (addresses.isEmpty) {
      throw Exception('Failed to resolve hostname: $_hostname');
    }

    // Try each resolved address until one succeeds
    Exception? lastException;
    for (final address in addresses) {
      try {
        await _fetchWithAddress(address, user);
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        continue;
      }
    }

    throw lastException ?? Exception('Failed to fetch variants');
  }

  /// Fetches variants using a specific IP address.
  ///
  /// Connects to the IP address using a raw socket, then upgrades to TLS
  /// with the correct hostname for SNI (Server Name Indication). This allows
  /// the TLS certificate to be validated against the hostname, not the IP.
  Future<void> _fetchWithAddress(
    InternetAddress address,
    ExperimentUser? user,
  ) async {
    final hostname = _hostname;
    final timeout = Duration(milliseconds: config.fetchTimeoutMillis);

    // First, connect to the IP address with a plain socket
    final plainSocket = await Socket.connect(
      address,
      443,
      timeout: timeout,
    );

    // Upgrade to secure socket with the correct hostname for SNI
    // This makes TLS validate the certificate against the hostname
    final socket = await SecureSocket.secure(
      plainSocket,
      host: hostname, // SNI hostname for certificate validation
    );

    try {
      // Build HTTP request manually
      final request = StringBuffer()
        ..write('GET /sdk/v2/vardata HTTP/1.1\r\n')
        ..write('Host: $hostname\r\n')
        ..write('Authorization: Api-Key $deploymentKey\r\n')
        ..write(
          'X-Amp-Exp-Track: ${config.automaticExposureTracking ? "track" : "no-track"}\r\n',
        );

      // Add user header if present
      if (user != null) {
        final userMap = Map<String, dynamic>.from(user.toJson())
          ..removeWhere((_, v) => v == null);
        final userJson = json.encode(userMap);
        final userBase64 = base64Url.encode(utf8.encode(userJson));
        request.write('X-Amp-Exp-User: $userBase64\r\n');
      }

      // Add connection close header and end headers
      request
        ..write('Connection: close\r\n')
        ..write('\r\n');

      // Send request
      socket.write(request.toString());
      await socket.flush();

      // Read response with timeout
      final responseData = await _readResponse(socket, timeout);

      // Parse HTTP response
      final headerEnd = responseData.indexOf('\r\n\r\n');
      if (headerEnd == -1) {
        throw const FormatException('Invalid HTTP response: no header end');
      }

      final headerSection = responseData.substring(0, headerEnd);
      final body = responseData.substring(headerEnd + 4);

      // Parse status line
      final statusLine = headerSection.split('\r\n').first;
      final statusMatch = RegExp(r'HTTP/\d\.\d (\d+)').firstMatch(statusLine);
      if (statusMatch == null) {
        throw FormatException('Invalid HTTP status line: $statusLine');
      }

      final statusCode = int.parse(statusMatch.group(1)!);
      if (statusCode != 200) {
        throw HttpException(
          'HTTP $statusCode',
          uri: Uri.https(hostname, '/sdk/v2/vardata'),
        );
      }

      final responseJson = json.decode(body) as Map<String, dynamic>;
      _cachedVariants = _parseVariants(responseJson);
    } finally {
      await socket.close();
    }
  }

  /// Reads the complete HTTP response from a socket with timeout.
  Future<String> _readResponse(SecureSocket socket, Duration timeout) async {
    final buffer = StringBuffer();
    final completer = Completer<String>();

    Timer? timer;
    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Response read timeout', timeout),
        );
      }
    });

    socket.listen(
      (data) {
        buffer.write(utf8.decode(data, allowMalformed: true));
      },
      onDone: () {
        timer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(buffer.toString());
        }
      },
      onError: (Object error) {
        timer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  /// Gets a variant by key from the cached variants.
  Variant? variant(String key, Variant? fallback) {
    return _cachedVariants[key] ?? fallback;
  }

  /// Gets all cached variants.
  Map<String, Variant> all() => Map.unmodifiable(_cachedVariants);

  /// Clears the cached variants.
  void clear() {
    _cachedVariants = {};
  }

  /// Resolves a hostname with fallback to public DNS servers.
  Future<List<InternetAddress>> _resolveWithFallback(String host) async {
    // First, try system DNS
    try {
      final addresses = await InternetAddress.lookup(host);
      if (_areValidAddresses(addresses)) {
        return addresses;
      }
    } catch (_) {
      // System DNS failed, try fallback
    }

    // Try fallback DNS servers
    for (final dnsServer in _fallbackDnsServers) {
      try {
        final addresses = await _lookupWithDns(host, dnsServer);
        if (_areValidAddresses(addresses)) {
          return addresses;
        }
      } catch (_) {
        continue;
      }
    }

    return [];
  }

  /// Checks if the resolved addresses are valid (not loopback/any).
  bool _areValidAddresses(List<InternetAddress> addresses) {
    if (addresses.isEmpty) return false;

    for (final addr in addresses) {
      // Check for loopback addresses
      if (addr.isLoopback) return false;

      // Check for any/wildcard addresses
      final addrStr = addr.address;
      if (addrStr == '0.0.0.0' || addrStr == '::') return false;
    }

    return true;
  }

  /// Secure random generator for DNS transaction IDs.
  static final Random _secureRandom = Random.secure();

  /// Performs DNS lookup using a specific DNS server.
  ///
  /// This uses a simple UDP DNS query to the specified server.
  Future<List<InternetAddress>> _lookupWithDns(
    String host,
    String dnsServer,
  ) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    try {
      // Generate random transaction ID for this query
      final transactionId = _secureRandom.nextInt(0xFFFF);

      // Build DNS query with the random transaction ID
      final query = _buildDnsQuery(host, transactionId);
      socket.send(query, InternetAddress(dnsServer), 53);

      // Wait for response with timeout
      await for (final event in socket.timeout(const Duration(seconds: 5))) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            // Parse response and validate transaction ID
            final result = _parseDnsResponse(datagram.data, transactionId);
            if (result != null) {
              return result;
            }
            // Invalid transaction ID, continue waiting for correct response
          }
        }
      }
    } finally {
      socket.close();
    }

    return [];
  }

  /// Builds a DNS query packet for the given hostname.
  ///
  /// [transactionId] is a random 16-bit ID used to match responses to queries.
  List<int> _buildDnsQuery(String host, int transactionId) {
    final buffer = <int>[
      // Transaction ID (random, provided by caller)
      (transactionId >> 8) & 0xFF,
      transactionId & 0xFF,
      // Flags: Standard query
      0x01, 0x00,
      // Questions: 1
      0x00, 0x01,
      // Answer RRs: 0
      0x00, 0x00,
      // Authority RRs: 0
      0x00, 0x00,
      // Additional RRs: 0
      0x00, 0x00,
    ];

    // Query name
    for (final label in host.split('.')) {
      buffer
        ..add(label.length)
        ..addAll(label.codeUnits);
    }

    buffer
      ..add(0x00) // End of name
      // Type: A (IPv4)
      ..add(0x00)
      ..add(0x01)
      // Class: IN
      ..add(0x00)
      ..add(0x01);

    return buffer;
  }

  /// Parses a DNS response packet and extracts IP addresses.
  ///
  /// [expectedTransactionId] is validated against the response to prevent
  /// DNS spoofing attacks. Returns null if transaction ID doesn't match.
  List<InternetAddress>? _parseDnsResponse(
    List<int> data,
    int expectedTransactionId,
  ) {
    final addresses = <InternetAddress>[];

    if (data.length < 12) return null;

    // Validate transaction ID (first 2 bytes)
    final responseTransactionId = (data[0] << 8) | data[1];
    if (responseTransactionId != expectedTransactionId) {
      // Transaction ID mismatch - possible spoofing attempt, reject response
      return null;
    }

    // Skip header and question section
    var offset = 12;

    // Skip question section
    while (offset < data.length && data[offset] != 0) {
      if ((data[offset] & 0xC0) == 0xC0) {
        offset += 2;
        break;
      }
      offset += data[offset] + 1;
    }
    if (offset < data.length && data[offset] == 0) {
      offset += 5; // null byte + type (2) + class (2)
    }

    // Parse answer section
    final answerCount = (data[6] << 8) | data[7];
    for (var i = 0; i < answerCount && offset < data.length; i++) {
      // Skip name (might be compressed)
      if ((data[offset] & 0xC0) == 0xC0) {
        offset += 2;
      } else {
        while (offset < data.length && data[offset] != 0) {
          offset += data[offset] + 1;
        }
        offset++;
      }

      if (offset + 10 > data.length) break;

      final type = (data[offset] << 8) | data[offset + 1];
      final dataLength = (data[offset + 8] << 8) | data[offset + 9];
      offset += 10;

      if (type == 1 && dataLength == 4 && offset + 4 <= data.length) {
        // A record (IPv4)
        final ip = '${data[offset]}.${data[offset + 1]}.'
            '${data[offset + 2]}.${data[offset + 3]}';
        try {
          addresses.add(InternetAddress(ip));
        } catch (_) {
          // Invalid IP, skip
        }
      }

      offset += dataLength;
    }

    return addresses;
  }

  /// Parses the API response into a map of variants.
  Map<String, Variant> _parseVariants(Map<String, dynamic> json) {
    final variants = <String, Variant>{};

    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        variants[key] = Variant(
          key: value['key'] as String? ?? key,
          value: value['value'] as String?,
          payload: value['payload'],
          expKey: value['expKey'] as String?,
        );
      }
    }

    return variants;
  }
}
