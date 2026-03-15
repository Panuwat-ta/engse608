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

      // Handle both 200 and 302 (Google Apps Script redirect)
      if (response.statusCode == 200 || response.statusCode == 302) {
        if (response.statusCode == 302) {
          return true; // 302 means success for Google Apps Script
        }
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Error initializing table: $e');
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

      // Handle both 200 and 302 (Google Apps Script redirect)
      if (response.statusCode == 200 || response.statusCode == 302) {
        // For 302, the operation was successful even though it redirected
        if (response.statusCode == 302) {
          return true;
        }

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Error updating member status: $e');
      return false;
    }
  }

  // ─── Delete user from Google Sheets ──────────────────────────────────────

  Future<bool> deleteUser(String webAppUrl, String gmail) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'deleteUser', 'gmail': gmail}),
          )
          .timeout(_timeout);

      // Handle both 200 and 302 (Google Apps Script redirect)
      if (response.statusCode == 200 || response.statusCode == 302) {
        // For 302, the operation was successful even though it redirected
        if (response.statusCode == 302) {
          return true;
        }

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting user: $e');
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
      debugPrint('📡 Fetching all admins from Sheets...');

      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'getAllAdmins'}),
          )
          .timeout(_timeout);

      debugPrint('📡 Admins response status: ${response.statusCode}');

      // Handle redirect (302)
      if (response.statusCode == 302) {
        debugPrint('📡 Got redirect for admins, following...');

        // Extract redirect URL from HTML response
        final htmlBody = response.body;
        final urlMatch = RegExp(r'HREF="([^"]+)"').firstMatch(htmlBody);

        if (urlMatch != null) {
          final redirectUrl = urlMatch.group(1)!.replaceAll('&amp;', '&');
          debugPrint('📡 Admins redirect URL: $redirectUrl');

          // Follow redirect with GET request
          final redirectResponse = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_timeout);

          debugPrint(
            '📡 Admins redirect response status: ${redirectResponse.statusCode}',
          );

          if (redirectResponse.statusCode == 200) {
            final body =
                jsonDecode(redirectResponse.body) as Map<String, dynamic>;
            if (body['status'] == 'ok') {
              final admins = List<Map<String, dynamic>>.from(
                body['admins'] as List,
              );
              debugPrint(
                '✅ Fetched ${admins.length} admins from Sheets (via redirect)',
              );
              return admins;
            }
          }
        }
      } else if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'ok') {
          final admins = List<Map<String, dynamic>>.from(
            body['admins'] as List,
          );
          debugPrint('✅ Fetched ${admins.length} admins from Sheets');
          return admins;
        }
      }

      debugPrint('⚠️ No admins returned from Sheets');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching admins: $e');
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

  // ─── Fetch all equipment from Equipment sheet ────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllEquipment(String webAppUrl) async {
    try {
      debugPrint('📡 Fetching all equipment from Sheets...');

      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'getAllEquipment'}),
          )
          .timeout(_timeout);

      debugPrint('📡 Equipment response status: ${response.statusCode}');

      // Handle redirect (302)
      if (response.statusCode == 302) {
        debugPrint('📡 Got redirect for equipment, following...');

        final htmlBody = response.body;
        final urlMatch = RegExp(r'HREF="([^"]+)"').firstMatch(htmlBody);

        if (urlMatch != null) {
          final redirectUrl = urlMatch.group(1)!.replaceAll('&amp;', '&');
          debugPrint('📡 Equipment redirect URL: $redirectUrl');

          final redirectResponse = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_timeout);

          debugPrint(
            '📡 Equipment redirect response status: ${redirectResponse.statusCode}',
          );

          if (redirectResponse.statusCode == 200) {
            final body =
                jsonDecode(redirectResponse.body) as Map<String, dynamic>;
            if (body['status'] == 'ok') {
              final equipment = List<Map<String, dynamic>>.from(
                body['equipment'] as List,
              );
              debugPrint(
                '✅ Fetched ${equipment.length} equipment from Sheets (via redirect)',
              );
              return equipment;
            }
          }
        }
      } else if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'ok') {
          final equipment = List<Map<String, dynamic>>.from(
            body['equipment'] as List,
          );
          debugPrint('✅ Fetched ${equipment.length} equipment from Sheets');
          return equipment;
        }
      }

      debugPrint('⚠️ No equipment returned from Sheets');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching equipment: $e');
      return [];
    }
  }

  // ─── Add equipment to Equipment sheet ─────────────────────────────────────

  Future<bool> addEquipment(
    String webAppUrl,
    Map<String, dynamic> equipment,
  ) async {
    try {
      debugPrint('📡 Adding equipment to Sheets...');

      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'addEquipment',
              'updatedAt': DateTime.now().toIso8601String(),
              ...equipment,
            }),
          )
          .timeout(_timeout);

      debugPrint('📡 Add equipment response status: ${response.statusCode}');

      // Handle redirect (302)
      if (response.statusCode == 302) {
        debugPrint('📡 Got redirect for add equipment, following...');

        final htmlBody = response.body;
        final urlMatch = RegExp(r'HREF="([^"]+)"').firstMatch(htmlBody);

        if (urlMatch != null) {
          final redirectUrl = urlMatch.group(1)!.replaceAll('&amp;', '&');
          debugPrint('📡 Add equipment redirect URL: $redirectUrl');

          final redirectResponse = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_timeout);

          debugPrint(
            '📡 Add equipment redirect response status: ${redirectResponse.statusCode}',
          );

          if (redirectResponse.statusCode == 200) {
            final body =
                jsonDecode(redirectResponse.body) as Map<String, dynamic>;
            return body['status'] == 'ok';
          }
        }
      } else if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error adding equipment: $e');
      return false;
    }
  }

  // ─── Update equipment in Equipment sheet ──────────────────────────────────

  Future<Map<String, dynamic>> updateEquipment(
    String webAppUrl,
    int id,
    Map<String, dynamic> equipment,
  ) async {
    try {
      debugPrint('📡 Updating equipment in Sheets (ID: $id)...');

      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'updateEquipment',
              'id': id,
              'updatedAt':
                  equipment['updated_at'] ?? DateTime.now().toIso8601String(),
              ...equipment,
            }),
          )
          .timeout(_timeout);

      debugPrint('📡 Update equipment response status: ${response.statusCode}');

      // Handle redirect (302)
      if (response.statusCode == 302) {
        debugPrint('📡 Got redirect for update equipment, following...');

        final htmlBody = response.body;
        final urlMatch = RegExp(r'HREF="([^"]+)"').firstMatch(htmlBody);

        if (urlMatch != null) {
          final redirectUrl = urlMatch.group(1)!.replaceAll('&amp;', '&');
          debugPrint('📡 Update equipment redirect URL: $redirectUrl');

          final redirectResponse = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_timeout);

          debugPrint(
            '📡 Update equipment redirect response status: ${redirectResponse.statusCode}',
          );

          if (redirectResponse.statusCode == 200) {
            final body =
                jsonDecode(redirectResponse.body) as Map<String, dynamic>;
            return {
              'success': body['status'] == 'ok' || body['status'] == 'conflict',
              'status': body['status'],
              'message': body['message'],
              'sheetUpdatedAt': body['sheetUpdatedAt'],
            };
          }
        }
      } else if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': body['status'] == 'ok' || body['status'] == 'conflict',
          'status': body['status'],
          'message': body['message'],
          'sheetUpdatedAt': body['sheetUpdatedAt'],
        };
      }
      return {'success': false, 'status': 'error', 'message': 'HTTP error'};
    } catch (e) {
      debugPrint('❌ Error updating equipment: $e');
      return {'success': false, 'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Delete equipment from Equipment sheet ────────────────────────────────

  Future<bool> deleteEquipment(String webAppUrl, int id) async {
    try {
      debugPrint('📡 Deleting equipment from Sheets (ID: $id)...');

      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'deleteEquipment', 'id': id}),
          )
          .timeout(_timeout);

      debugPrint('📡 Delete equipment response status: ${response.statusCode}');

      // Handle redirect (302)
      if (response.statusCode == 302) {
        debugPrint('📡 Got redirect for delete equipment, following...');

        final htmlBody = response.body;
        final urlMatch = RegExp(r'HREF="([^"]+)"').firstMatch(htmlBody);

        if (urlMatch != null) {
          final redirectUrl = urlMatch.group(1)!.replaceAll('&amp;', '&');
          debugPrint('📡 Delete equipment redirect URL: $redirectUrl');

          final redirectResponse = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_timeout);

          debugPrint(
            '📡 Delete equipment redirect response status: ${redirectResponse.statusCode}',
          );

          if (redirectResponse.statusCode == 200) {
            final body =
                jsonDecode(redirectResponse.body) as Map<String, dynamic>;
            return body['status'] == 'ok';
          }
        }
      } else if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting equipment: $e');
      return false;
    }
  }

  // ─── Fetch all transactions from Transactions sheet ──────────────────────

  Future<List<Map<String, dynamic>>> fetchAllTransactions(
    String webAppUrl,
  ) async {
    try {
      debugPrint('📡 Fetching all transactions from Sheets...');

      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'getAllTransactions'}),
          )
          .timeout(_timeout);

      debugPrint('📡 Transactions response status: ${response.statusCode}');

      // Handle redirect (302)
      if (response.statusCode == 302) {
        debugPrint('📡 Got redirect for transactions, following...');

        final htmlBody = response.body;
        final urlMatch = RegExp(r'HREF="([^"]+)"').firstMatch(htmlBody);

        if (urlMatch != null) {
          final redirectUrl = urlMatch.group(1)!.replaceAll('&amp;', '&');
          debugPrint('📡 Transactions redirect URL: $redirectUrl');

          final redirectResponse = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_timeout);

          debugPrint(
            '📡 Transactions redirect response status: ${redirectResponse.statusCode}',
          );

          if (redirectResponse.statusCode == 200) {
            final body =
                jsonDecode(redirectResponse.body) as Map<String, dynamic>;
            if (body['status'] == 'ok') {
              final transactions = List<Map<String, dynamic>>.from(
                body['transactions'] as List,
              );
              debugPrint(
                '✅ Fetched ${transactions.length} transactions from Sheets (via redirect)',
              );
              return transactions;
            }
          }
        }
      } else if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'ok') {
          final transactions = List<Map<String, dynamic>>.from(
            body['transactions'] as List,
          );
          debugPrint(
            '✅ Fetched ${transactions.length} transactions from Sheets',
          );
          return transactions;
        }
      }

      debugPrint('⚠️ No transactions returned from Sheets');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching transactions: $e');
      return [];
    }
  }

  // ─── Add Transaction to Transactions sheet ───────────────────────────────

  Future<Map<String, dynamic>> addTransaction(
    String webAppUrl,
    Map<String, dynamic> transaction,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'addTransaction',
              'id': transaction['id'],
              'equipmentId': transaction['equipment_id'],
              'userGmail': transaction['user_gmail'],
              'borrowDate': transaction['borrow_date'],
              'returnDate': transaction['return_date'],
              'actualReturnDate': transaction['actual_return_date'],
              'status': transaction['status'],
              'notes': transaction['notes'],
            }),
          )
          .timeout(_timeout);

      // Handle both 200 and 302 (Google Apps Script redirect)
      if (response.statusCode == 200 || response.statusCode == 302) {
        if (response.statusCode == 302) {
          return {'status': 'ok', 'message': 'Transaction added (302)'};
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Record Return to Returns sheet ──────────────────────────────────────

  Future<Map<String, dynamic>> recordReturn(
    String webAppUrl, {
    required int transactionId,
    required int equipmentId,
    required String equipmentName,
    required String userGmail,
    required String userName,
    required String borrowDate,
    required String returnDate,
    required String actualReturnDate,
    required String approvedBy,
    String notes = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'recordReturn',
              'transactionId': transactionId
                  .toString(), // Use transaction ID as return ID
              'equipmentId': equipmentId.toString(),
              'equipmentName': equipmentName,
              'userGmail': userGmail,
              'userName': userName,
              'borrowDate': borrowDate,
              'returnDate': returnDate,
              'actualReturnDate': actualReturnDate,
              'approvedBy': approvedBy,
              'notes': notes,
            }),
          )
          .timeout(_timeout);

      // Handle both 200 and 302 (Google Apps Script redirect)
      if (response.statusCode == 200 || response.statusCode == 302) {
        if (response.statusCode == 302) {
          return {'status': 'ok', 'message': 'Return recorded (302)'};
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      debugPrint('Error recording return: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Fetch all returns from Returns sheet ────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllReturns(String webAppUrl) async {
    try {
      debugPrint('📡 Fetching all returns from Sheets...');

      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'getAllReturns'}),
          )
          .timeout(_timeout);

      debugPrint('📡 Returns response status: ${response.statusCode}');

      // Handle redirect (302)
      if (response.statusCode == 302) {
        debugPrint('📡 Got redirect for returns, following...');

        final htmlBody = response.body;
        final urlMatch = RegExp(r'HREF="([^"]+)"').firstMatch(htmlBody);

        if (urlMatch != null) {
          final redirectUrl = urlMatch.group(1)!.replaceAll('&amp;', '&');
          debugPrint('📡 Returns redirect URL: $redirectUrl');

          final redirectResponse = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_timeout);

          debugPrint(
            '📡 Returns redirect response status: ${redirectResponse.statusCode}',
          );

          if (redirectResponse.statusCode == 200) {
            final body =
                jsonDecode(redirectResponse.body) as Map<String, dynamic>;
            if (body['status'] == 'ok') {
              final returns = List<Map<String, dynamic>>.from(
                body['returns'] as List,
              );
              debugPrint(
                '✅ Fetched ${returns.length} returns from Sheets (via redirect)',
              );
              return returns;
            }
          }
        }
      } else if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'ok') {
          final returns = List<Map<String, dynamic>>.from(
            body['returns'] as List,
          );
          debugPrint('✅ Fetched ${returns.length} returns from Sheets');
          return returns;
        }
      }

      debugPrint('⚠️ No returns returned from Sheets');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching returns: $e');
      return [];
    }
  }

  // ─── Update return approval status ────────────────────────────────────────

  Future<bool> updateReturnApproval(
    String webAppUrl,
    String returnId,
    String approvedBy,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'updateReturnApproval',
              'transactionId':
                  returnId, // Use transaction ID to find the return
              'approvedBy': approvedBy,
              'approvedAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 302) {
        if (response.statusCode == 302) {
          return true;
        }
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Error updating return approval: $e');
      return false;
    }
  }
}
