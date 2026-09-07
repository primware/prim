import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../API/endpoint.dart';
import '../../../API/pos.api.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';

class HeldTicket {
  const HeldTicket({required this.id, required this.createdAt, required this.updatedAt, required this.data});

  static const schemaVersion = 1;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'version': schemaVersion,
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'data': data,
  };

  static HeldTicket? fromJson(dynamic value) {
    if (value is! Map || value['version'] != schemaVersion || value['data'] is! Map) {
      return null;
    }
    final createdAt = DateTime.tryParse(value['createdAt']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(value['updatedAt']?.toString() ?? '');
    if (createdAt == null || updatedAt == null || value['id'] == null) {
      return null;
    }
    return HeldTicket(
      id: value['id'].toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      data: Map<String, dynamic>.from(value['data'] as Map),
    );
  }
}

class HeldTicketStore {
  HeldTicketStore._();
  static final instance = HeldTicketStore._();

  final ValueNotifier<int> count = ValueNotifier<int>(0);
  Future<void> Function()? activeOrderSaver;
  String? activeTicketId;

  String get _key {
    final parts = [
      Base.baseURL ?? '',
      Token.client?.toString() ?? '',
      Token.rol?.toString() ?? '',
      UserData.id?.toString() ?? '',
      Token.organitation?.toString() ?? '',
      POS.cPosID?.toString() ?? 'non-pos',
    ];
    return 'held_tickets_v1_${Uri.encodeComponent(parts.join('|'))}';
  }

  Future<List<HeldTicket>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      count.value = 0;
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Invalid held ticket list');
      }
      final tickets = decoded.map(HeldTicket.fromJson).whereType<HeldTicket>().toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      count.value = tickets.length;
      return tickets;
    } catch (error) {
      debugPrint('Held tickets could not be decoded: $error');
      count.value = 0;
      return [];
    }
  }

  Future<void> save(HeldTicket ticket) async {
    final tickets = await load();
    tickets.removeWhere((item) => item.id == ticket.id);
    tickets.insert(0, ticket);
    await _write(tickets);
  }

  Future<void> delete(String id) async {
    final tickets = await load()
      ..removeWhere((item) => item.id == id);
    await _write(tickets);
  }

  Future<void> refresh() async => load();

  Future<void> _write(List<HeldTicket> tickets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(tickets.map((item) => item.toJson()).toList()));
    count.value = tickets.length;
  }
}
