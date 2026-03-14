// lib/services/sheets_service.dart
// HTTP service for communicating with Google Apps Script Web App

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/sync_queue_model.dart';
import '../database/database_helper.dart';

class SheetsService {
  SheetsService._();
  static final SheetsService instance = SheetsService._();

  static const Duration _timeout = Duration(seconds: 15);

  // ─── Register a new member ────────────────────────────────────────────────

  /// POST registration data to Apps Script.
  /// On failure, adds payload to offline sync_queue.
  Future<bool> registerMember(String webAppUrl, UserModel user) async {
    final payload = {
      'action': 'register',
      'headers': UserModel.headers,
      'values': user.toSheetRow(),
    };

    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (_) {
      // Offline — add to sync queue
      await DatabaseHelper.instance.insertSyncItem(
        SyncQueueItem(
          payload: jsonEncode(payload),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return false;
    }
  }

  // ─── Initialize empty table (headers only) ────────────────────────────────

  /// Initialize Google Sheet with headers only (no data rows)
  Future<bool> initializeTable(String webAppUrl) async {
    final payload = {'action': 'initTable', 'headers': UserModel.headers};

    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Fetch all members (Admin) ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllMembers(String webAppUrl) async {
    try {
      debugPrint('📡 Fetching all members from Sheets...');

      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'getAll'}),
          )
          .timeout(_timeout);

      debugPrint('📡 Response status: ${response.statusCode}');

      // Handle redirect (302)
      if (response.statusCode == 302) {
        debugPrint('📡 Got redirect, following...');

        // Extract redirect URL from HTML response
        final htmlBody = response.body;
        final urlMatch = RegExp(r'HREF="([^"]+)"').firstMatch(htmlBody);

        if (urlMatch != null) {
          final redirectUrl = urlMatch.group(1)!.replaceAll('&amp;', '&');
          debugPrint('📡 Redirect URL: $redirectUrl');

          // Follow redirect with GET request
          final redirectResponse = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_timeout);

          debugPrint(
            '📡 Redirect response status: ${redirectResponse.statusCode}',
          );
          debugPrint('📡 Redirect response body: ${redirectResponse.body}');

          if (redirectResponse.statusCode == 200) {
            final body =
                jsonDecode(redirectResponse.body) as Map<String, dynamic>;
            if (body['status'] == 'ok') {
              final members = List<Map<String, dynamic>>.from(
                body['members'] as List,
              );
              debugPrint(
                '✅ Fetched ${members.length} members from Sheets (via redirect)',
              );
              return members;
            }
          }
        }
      } else if (response.statusCode == 200) {
        debugPrint('📡 Response body: ${response.body}');

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'ok') {
          final members = List<Map<String, dynamic>>.from(
            body['members'] as List,
          );
          debugPrint('✅ Fetched ${members.length} members from Sheets');
          return members;
        }
      }

      debugPrint('⚠️ No members returned from Sheets');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching members: $e');
      return [];
    }
  }

  // ─── Update member status (Admin Approve) ────────────────────────────────

  Future<bool> updateMemberStatus(
    String webAppUrl,
    String gmail,
    String newStatus,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'updateStatus',
              'gmail': gmail,
              'newStatus': newStatus,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Check user by Gmail ──────────────────────────────────────────────────

  /// Returns user map from Sheet or null if not found / offline
  Future<Map<String, dynamic>?> checkUser(
    String webAppUrl,
    String gmail,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'checkUser', 'gmail': gmail}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'ok' && body['found'] == true) {
          return body['user'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Retry offline sync queue ─────────────────────────────────────────────

  Future<void> retrySync(String webAppUrl) async {
    final items = await DatabaseHelper.instance.getAllSyncItems();
    for (final item in items) {
      try {
        final response = await http
            .post(
              Uri.parse(webAppUrl),
              headers: {'Content-Type': 'application/json'},
              body: item.payload,
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['status'] == 'ok' && item.id != null) {
            await DatabaseHelper.instance.deleteSyncItem(item.id!);
          }
        }
      } catch (_) {
        // Still offline — keep in queue
      }
    }
  }

  // ─── Fetch all admins from Admins sheet ───────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllAdmins(String webAppUrl) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'getAllAdmins'}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'ok') {
          return List<Map<String, dynamic>>.from(body['admins'] as List);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── Delete admin from Admins sheet ───────────────────────────────────────

  Future<bool> deleteAdmin(String webAppUrl, String gmail) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'deleteAdmin', 'gmail': gmail}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 302) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
