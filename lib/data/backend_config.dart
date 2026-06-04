// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:http_parser/http_parser.dart'; // Required for MediaType

import 'package:server_site/data/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const backendUrl = 'https://key-backend-for-friendsmp75-website.vercel.app/';
const accessToken = String.fromEnvironment("ACCESS_TOKEN");

class BackendData {
  static User? get user => Supabase.instance.client.auth.currentUser;

  /// Helper to generate headers including the Supabase JWT for RLS
  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'X-Access-Token': accessToken,
    };

    if (includeAuth) {
      // Fetch the current JWT session from Supabase
      final String? jwt =
          Supabase.instance.client.auth.currentSession?.accessToken;
      if (jwt != null) {
        headers['Authorization'] = 'Bearer $jwt';
      }
    }
    return headers;
  }

  // --- Base HTTP Methods ---

  static Future<dynamic> retrieveData(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(backendUrl + endpoint),
        headers: _getHeaders(includeAuth: requireAuth),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Backend error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print('Error Retrieving Data from backend $e');
    }
    return 'Error Retrieving Data';
  }

  static Future<String?> sendData(
    String endpoint,
    Map<String, dynamic> content,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(backendUrl + endpoint),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(content),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;
      } else {
        print("Backend error: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error contacting backend! $e");
      return null;
    }
  }

  static Future<String?> removeData(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse(backendUrl + endpoint),
        headers: _getHeaders(includeAuth: true),
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print("Backend error: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error contacting backend! $e");
      return null;
    }
  }

  // --- Getters ---

  static Future<String?> getOwnerAuthID() async {
    try {
      final data = await retrieveData('check-owner', requireAuth: false);
      if (data != null && data is Map) {
        return data['UUID_ID'] as String?;
      }
    } catch (e) {
      print('Error getting owner auth id: $e');
    }
    return null;
  }

  static Future<List<dynamic>?> getUUID() async {
    try {
      final result = await retrieveData('get-staff-uuids', requireAuth: true);
      if (result is List<dynamic>) return result;
    } catch (e) {
      print('Error when getting uuid $e');
    }
    return null;
  }

  static Future<List<dynamic>?> getAnnouncements() async {
    try {
      final result = await retrieveData(
        'get-announcements',
        requireAuth: false,
      );
      if (result is List<dynamic>) return result;
    } catch (e) {
      debugPrint('Error when getting announcements: $e');
    }
    return null;
  }

  /// Retrieves image metadata (author, taken date, etc.)
  static Future<List<dynamic>?> getGalleryData() async {
    try {
      final result = await retrieveData('get-gallery-data', requireAuth: false);
      if (result is List<dynamic>) return result;
    } catch (e) {
      debugPrint('Error fetching gallery data: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>?> getPublicApprovedImages() async {
    try {
      final result = await retrieveData(
        'public-approved-images',
        requireAuth: false,
      );

      if (result is List) {
        return result.whereType<Map>().map((item) {
          return item.map((key, value) => MapEntry(key.toString(), value));
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching public approved images: $e');
    }
    return null;
  }

  static Future<bool> getStaffAppStatus() async {
    try {
      final response = await retrieveData(
        'staff-app-status',
        requireAuth: false,
      );
      if (response != null && response is List && response.isNotEmpty) {
        final config = response.first as Map<String, dynamic>;
        return config['is_open'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error getting response $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>?> getMemberMemoryRequests({
    required String memberUuid,
  }) async {
    try {
      final uri = Uri.parse(
        '${backendUrl}member-memory-requests',
      ).replace(queryParameters: {'uuid': memberUuid});

      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      if (response.statusCode != 200) {
        print(
          'My memory requests error: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.whereType<Map>().map((item) {
          return item.map((key, value) => MapEntry(key.toString(), value));
        }).toList();
      }

      return const [];
    } catch (e) {
      print('Error fetching member memory requests: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getStaffMemoryRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${backendUrl}staff-memory-requests'),
        headers: _getHeaders(includeAuth: true),
      );

      if (response.statusCode != 200) {
        print(
          'Staff memory requests error: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.whereType<Map>().map((item) {
          return item.map((key, value) => MapEntry(key.toString(), value));
        }).toList();
      }

      return const [];
    } catch (e) {
      print('Error fetching staff memory requests: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStaffApplicationStatus() async {
    try {
      final response = await retrieveData(
        'staff-application-check',
        requireAuth: true,
      );

      if (response == null) return null;

      if (response is List) {
        if (response.isNotEmpty) {
          return Map<String, dynamic>.from(response.first as Map);
        }
        return null;
      }

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      debugPrint('Error parsing staff Application data: $e');
    }
    return null;
  }

  static Future<bool> updateMemoryRequestStatus({
    required Map<String, dynamic> request,
    required bool approved,
  }) async {
    try {
      final headers = _getHeaders(includeAuth: true);
      final status = approved ? 'approved' : 'rejected';
      final action = approved ? 'approve' : 'reject';

      final requestId =
          request['id'] ?? request['request_id'] ?? request['uuid'];
      final title =
          request['title'] ?? request['memory_title'] ?? request['name'];
      final memberUuid =
          request['author_uuid'] ?? request['member_uuid'] ?? request['uuid'];
      final displayName =
          request['display_name'] ??
          request['player'] ??
          request['author'] ??
          request['username'] ??
          request['name'] ??
          'Unknown';
      final dateTaken =
          request['time_taken'] ??
          request['taken_date'] ??
          request['date_taken'] ??
          request['date'] ??
          '';

      final payload = <String, dynamic>{
        'status': status,
        'request_status': status,
        'action': action,
        'approved': approved,
        if (requestId != null) ...{'id': requestId, 'request_id': requestId},
        if (title != null) ...{'title': title, 'memory_title': title},
        if (memberUuid != null) ...{
          'member_uuid': memberUuid,
          'author_uuid': memberUuid,
          'uuid': memberUuid,
        },
      };

      final endpointAttempts = <Map<String, String>>[
        {'method': 'PATCH', 'endpoint': 'staff-memory-requests'},
        {'method': 'POST', 'endpoint': 'staff-memory-requests'},
        {'method': 'PATCH', 'endpoint': 'staff-memory-request-action'},
        {'method': 'POST', 'endpoint': 'staff-memory-request-action'},
        {'method': 'PATCH', 'endpoint': 'memory-request-action'},
        {'method': 'POST', 'memory-request-action': 'memory-request-action'},
        {'method': 'PATCH', 'endpoint': 'memory-request-status'},
        {'method': 'POST', 'endpoint': 'memory-request-status'},
        {'method': 'POST', 'memory-request-$action': 'memory-request-$action'},
      ];

      for (final attempt in endpointAttempts) {
        final endpoint = attempt['endpoint']!;
        final method = attempt['method']!;
        final uri = Uri.parse('$backendUrl$endpoint');

        http.Response response;
        if (method == 'PATCH') {
          response = await http.patch(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          );
        } else {
          response = await http.post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          );
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (approved) {
            await notifyDiscordApprovedMemoryRequest(
              displayName: displayName.toString(),
              uuid: memberUuid?.toString() ?? 'Unknown',
              title: title?.toString() ?? 'Untitled request',
              dateTaken: dateTaken.toString(),
            );
          }
          return true;
        }
      }

      print('Failed to update memory request status on all known endpoints.');
      return false;
    } catch (e) {
      print('Error updating memory request status: $e');
      return false;
    }
  }

  static Future<bool> deleteMemoryRequest({
    required Map<String, dynamic> request,
  }) async {
    try {
      final headers = _getHeaders(includeAuth: true);
      final requestId =
          request['id'] ?? request['request_id'] ?? request['uuid'];

      if (requestId == null) {
        print('Delete memory request failed: missing request id.');
        return false;
      }

      final payload = <String, dynamic>{
        'id': requestId,
        'request_id': requestId,
      };

      final pathDeleteAttempts = <String>[
        'staff-memory-requests/$requestId',
        'staff-memory-request/$requestId',
        'memory-request/$requestId',
        'memory-requests/$requestId',
        'member-memory-requests/$requestId',
      ];

      for (final endpoint in pathDeleteAttempts) {
        final response = await http.delete(
          Uri.parse('$backendUrl$endpoint'),
          headers: headers,
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          return true;
        }
      }

      final bodyDeleteAttempts = <String>[
        'staff-memory-requests',
        'staff-memory-request-delete',
        'memory-request-delete',
        'member-memory-request-delete',
      ];

      for (final endpoint in bodyDeleteAttempts) {
        final response = await http.delete(
          Uri.parse('$backendUrl$endpoint'),
          headers: headers,
          body: jsonEncode(payload),
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          return true;
        }
      }

      final postDeleteAttempts = <String>[
        'staff-memory-request-delete',
        'memory-request-delete',
      ];

      for (final endpoint in postDeleteAttempts) {
        final response = await http.post(
          Uri.parse('$backendUrl$endpoint'),
          headers: headers,
          body: jsonEncode(payload),
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          return true;
        }
      }

      print('Failed to delete memory request on all known endpoints.');
      return false;
    } catch (e) {
      print('Error deleting memory request: $e');
      return false;
    }
  }

  // --- Senders ---

  static Future<String?> sendUUID(String uuid, String nickname) async {
    return await sendData('add-uuid', {'uuid': uuid, 'nickname': nickname});
  }

  static Future<bool> sendDirectMessage({
    required String recipientDiscordId,
    required String message,
    String? senderUuid,
    String? senderName,
    String? senderDiscordId,
    String serverName = 'FriendSMP75',
    bool? behalfOfStaff,
  }) async {
    try {
      final sentAt = DateTime.now().toUtc().toIso8601String();
      final safeSenderName =
          (senderName != null && senderName.trim().isNotEmpty)
          ? senderName.trim()
          : 'Unknown';
      final safeSenderUuid =
          (senderUuid != null && senderUuid.trim().isNotEmpty)
          ? senderUuid.trim()
          : 'Unknown';
      final safeSenderDiscordId =
          (senderDiscordId != null && senderDiscordId.trim().isNotEmpty)
          ? senderDiscordId.trim()
          : 'Unknown';

      final spacedMessage = '\n\n${message.trim()}';

      final payload = <String, dynamic>{
        'recipient_discord_id': recipientDiscordId,
        'discord_id': recipientDiscordId,
        'recipient_uuid': recipientDiscordId,
        'uuid': recipientDiscordId,
        'message': spacedMessage,
        'raw_message': message,
        'sender_uuid': safeSenderUuid,
        'sender_name': safeSenderName,
        'sender_discord_id': safeSenderDiscordId,
        'sent_at': sentAt,
        'server_name': serverName,
        'source_server': serverName,
        'behalf_of_staff': behalfOfStaff,
      };

      final response = await http.post(
        Uri.parse('${backendUrl}send-dm'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      print('Send DM error: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      print('Send DM exception: $e');
      return false;
    }
  }

  static Future<({int sentCount, List<String> failedIds})>
  sendDirectMessageToMany({
    required List<String> recipientDiscordIds,
    required String message,
    String? senderUuid,
    String? senderName,
    String? senderDiscordId,
    String serverName = 'FriendSMP75',
    bool? behalfOfStaff,
  }) async {
    int sentCount = 0;
    final failedIds = <String>[];

    for (final id in recipientDiscordIds) {
      final ok = await sendDirectMessage(
        recipientDiscordId: id,
        message: message,
        senderUuid: senderUuid,
        senderName: senderName,
        senderDiscordId: senderDiscordId,
        serverName: serverName,
        behalfOfStaff: behalfOfStaff,
      );

      if (ok) {
        sentCount++;
      } else {
        failedIds.add(id);
      }
    }

    return (sentCount: sentCount, failedIds: failedIds);
  }

  static Future<String?> newAnnouncement(String title, String body) async {
    try {
      final author = SupabaseConfig.getDisplayName(user);
      final authorUUID = SupabaseConfig.getSupabaseUUID(user);

      final result = await sendData('new-announcements', {
        'title': title,
        'body': body,
        'author': author,
        'author_uuid': authorUUID,
      });

      await notifyDiscordAnnouncement(
        title: title,
        body: body,
        author: author,
        authorUuid: authorUUID,
      );

      return result;
    } catch (e) {
      return 'Error: $e';
    }
  }

  static Future<String?> sendDiscordWebhook({
    required String content,
    String? username,
    String? avatarUrl,
    List<Map<String, dynamic>>? embeds,
    Map<String, dynamic>? extra,
  }) async {
    final payload = <String, dynamic>{'content': content};

    if (username != null && username.trim().isNotEmpty) {
      payload['username'] = username.trim();
    }

    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      payload['avatar_url'] = avatarUrl.trim();
    }

    if (embeds != null) {
      payload['embeds'] = embeds;
    }

    if (extra != null && extra.isNotEmpty) {
      payload.addAll(extra);
    }

    return await sendData('discord-webhook', payload);
  }

  static Future<String?> notifyDiscordAnnouncement({
    required String title,
    required String body,
    required String author,
    required String authorUuid,
  }) async {
    return await sendDiscordWebhook(
      content: '📢 New announcement posted by $author',
      embeds: [
        {
          'title': title,
          'description': body,
          'color': 3447003,
          'fields': [
            {'name': 'Author', 'value': author, 'inline': true},
            {'name': 'Author UUID', 'value': authorUuid, 'inline': true},
          ],
        },
      ],
    );
  }

  static Future<String?> notifyDiscordMemoryRequest({
    required String displayName,
    required String uuid,
    required String title,
    required String dateTaken,
  }) async {
    final messageTitle = title.trim().isNotEmpty
        ? title.trim()
        : 'Member memory request submitted';

    return await sendDiscordWebhook(
      content: '🖼️ New member memory request received',
      embeds: [
        {
          'title': messageTitle,
          'color': 15844367,
          'fields': [
            {'name': 'Display Name', 'value': displayName, 'inline': true},
            {'name': 'UUID', 'value': uuid, 'inline': true},
            {'name': 'Date Taken', 'value': dateTaken, 'inline': true},
          ],
        },
      ],
    );
  }

  static Future<String?> notifyDiscordApprovedMemoryRequest({
    required String displayName,
    required String uuid,
    required String title,
    required String dateTaken,
  }) async {
    final messageTitle = title.trim().isNotEmpty
        ? title.trim()
        : 'Member memory request approved';

    return await sendDiscordWebhook(
      content: '✅ Member memory request approved by staff',
      embeds: [
        {
          'title': messageTitle,
          'color': 3066993,
          'fields': [
            {'name': 'Display Name', 'value': displayName, 'inline': true},
            {'name': 'UUID', 'value': uuid, 'inline': true},
            {'name': 'Date Taken', 'value': dateTaken, 'inline': true},
          ],
        },
      ],
    );
  }

  static Future<String?> deleteUUID(String uuid) async {
    return await removeData('delete-uuid/$uuid');
  }

  // --- UPLOAD METHOD (WEB ONLY) ---
  static Future<String?> uploadImage({
    required List<int> imageBytes,
    required String filename,
    required String takenDate,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final headers = _getHeaders(includeAuth: true);
      headers.remove('Content-Type');

      final ext = filename.split('.').last.toLowerCase();
      final mimeType = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : 'png';

      final dioClient = dio.Dio(
        dio.BaseOptions(
          baseUrl: backendUrl,
          headers: headers,
          responseType: dio.ResponseType.plain,
        ),
      );

      final formData = dio.FormData.fromMap({
        'author': SupabaseConfig.getDisplayName(user),
        'author_uuid': SupabaseConfig.getSupabaseUUID(user).toString(),
        'taken_date': takenDate,
        'image': dio.MultipartFile.fromBytes(
          imageBytes,
          filename: filename,
          contentType: MediaType('image', mimeType),
        ),
      });

      final response = await dioClient.post(
        'upload-image',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data?.toString();
      }

      print('Backend upload error: ${response.statusCode} ${response.data}');
      return null;
    } catch (e) {
      print("Upload exception: $e");
      return null;
    }
  }

  static Future<String?> addMemoryRequest({
    required List<int> imageBytes,
    required String filename,
    required String uuid,
    required String displayName,
    required String timeTaken,
    String? title,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final normalizedTitle = title?.trim() ?? '';
      if (normalizedTitle.isEmpty) {
        print('Memory request validation error: title is required.');
        return null;
      }

      final headers = _getHeaders(includeAuth: true);
      headers.remove('Content-Type');
      final ext = filename.split('.').last.toLowerCase();
      final mimeType = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : 'png';

      final dioClient = dio.Dio(
        dio.BaseOptions(
          baseUrl: backendUrl,
          headers: headers,
          responseType: dio.ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final formDataMap = <String, dynamic>{
        'uuid': uuid,
        'author_uuid': uuid,
        'display_name': displayName,
        'displayname': displayName,
        'author': displayName,
        'time_taken': timeTaken,
        'date_taken': timeTaken,
        'taken_date': timeTaken,
        'title': normalizedTitle,
        'image': dio.MultipartFile.fromBytes(
          imageBytes,
          filename: filename,
          contentType: MediaType('image', mimeType),
        ),
      };

      final response = await dioClient.post(
        'memory-request-add',
        data: dio.FormData.fromMap(formDataMap),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 8) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data?.toString();
      }

      print(
        'Memory request upload error: ${response.statusCode} ${response.data}',
      );
      return null;
    } catch (e) {
      if (e is dio.DioException) {
        print(
          'Memory request upload exception: ${e.response?.statusCode} ${e.response?.data}',
        );
      } else {
        print('Memory request upload exception: $e');
      }
      return null;
    }
  }

  static Future<String?> powerAction(String action) async {
    try {
      return await sendData('server-$action', {'value': null});
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> serverStatus() async {
    try {
      final response = await retrieveData('server-status');
      if (response == null) return null;
      if (response is Map<String, dynamic>) return response;
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<dynamic> updateStaffAppStatus(bool status) async {
    try {
      final response = await http.patch(
        Uri.parse('${backendUrl}update-staff-app-status'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({'is_open': status}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          'Failed to update status. Status Code: ${response.statusCode}, Body: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error updating via endpoint: $e');
      return null;
    }
  }

  // --- 📝 STAFF APPLICATION PIPELINE HANDLERS ---

  /// Requests form templates directly, then executes a client-side layout map query 
  /// using profiles join architecture to assign custom Discord usernames seamlessly.
static Future<List<dynamic>> fetchSubmittedApplications() async {
  try {
    final result = await retrieveData('get-submitted-applications', requireAuth: true);
    if (result is List<dynamic>) {
      return result
          .map((application) => Map<String, dynamic>.from(application as Map))
          .toList();
    }
  } catch (e) {
    print('Backend architecture query error fetching applications: $e');
  }
  return [];
}
  /// Appends or changes a staff member's active assessment vote status (YES/NO) on a target form submission.
  static Future<void> submitStaffVote(String appUid, String voteType) async {
    try {
      final response = await sendData('submit-staff-vote', {
        'application_uid': appUid,
        'vote_type': voteType,
      });
      if (response == null) {
        throw Exception('Server rejected the staff evaluation action mapping matrix.');
      }
    } catch (e) {
      print('Backend error processing vote pipeline entry context: $e');
      throw Exception('Failed to register vote transaction context configuration.');
    }
  }

  /// Concludes a review lifecycle by committing a final verdict resolution package along with its summary verification note.
  static Future<void> finalizeStaffApplication(String appUid, String decision, String explanation) async {
    try {
      final response = await sendData('finalize-staff-application', {
        'application_uid': appUid,
        'status': decision,
        'review_explanation': explanation,
      });
      if (response == null) {
        throw Exception('Server rejected writing decision resolution parameters down to active state storage maps.');
      }
    } catch (e) {
      print('Backend error committing final resolution structural block payload: $e');
      throw Exception('Failed to finalize applicant record routing.');
    }
  }
}