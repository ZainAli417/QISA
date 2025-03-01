import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:videosdk_flutter_example/utils/toast.dart';

// Directly assigned API URL and Token (Replace with your actual values)
const String VIDEOSDK_API_ENDPOINT = "https://api.videosdk.live/v2";
const String AUTH_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiJhNmQ5OTI3NC1hMTIyLTRiYzMtYmJhOS0wNDYyOTcyNWNiMDQiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIl0sImlhdCI6MTczNjIyMzYzNywiZXhwIjoxODk0MDExNjM3fQ.TdZwUNK6jQ-SZjCvabdIvnnbpk2wWvSCruRSxLKEMsY"; // Truncated for readability

Future<String> fetchToken(BuildContext context) async {
  if (AUTH_TOKEN.isEmpty) {
    showSnackBarMessage(
        message: "Please set the AUTH_TOKEN", context: context);
    throw Exception("AUTH_TOKEN is not set.");
  }
  return AUTH_TOKEN;
}

Future<String> createMeeting(String token) async {
  final Uri getMeetingIdUrl = Uri.parse('$VIDEOSDK_API_ENDPOINT/rooms');

  final http.Response meetingIdResponse = await http.post(
    getMeetingIdUrl,
    headers: {"Authorization": token},
  );

  if (meetingIdResponse.statusCode != 200) {
    throw Exception(json.decode(meetingIdResponse.body)["error"]);
  }

  return json.decode(meetingIdResponse.body)['roomId'];
}

Future<bool> validateMeeting(String token, String meetingId) async {
  final Uri validateMeetingUrl =
  Uri.parse('$VIDEOSDK_API_ENDPOINT/rooms/validate/$meetingId');

  final http.Response validateMeetingResponse = await http.get(
    validateMeetingUrl,
    headers: {"Authorization": token},
  );

  if (validateMeetingResponse.statusCode != 200) {
    throw Exception(json.decode(validateMeetingResponse.body)["error"]);
  }

  return true;
}

Future<dynamic> fetchSession(String token, String meetingId) async {
  final Uri getMeetingIdUrl =
  Uri.parse('$VIDEOSDK_API_ENDPOINT/sessions?roomId=$meetingId');

  final http.Response meetingIdResponse = await http.get(
    getMeetingIdUrl,
    headers: {"Authorization": token},
  );

  return jsonDecode(meetingIdResponse.body)['data'].first;
}
