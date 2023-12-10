import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:huddle01_flutter_client/huddle_client.dart';
import 'package:moai_app/main.dart';
import 'package:moai_app/secrets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class HuddleEngine {
  static final currentlyActiveRoom = StateProvider<String>((ref) => '');
  static final muteState = StateProvider<bool>((ref) => true);
  static final cameraOffState = StateProvider<bool>((ref) => true);

  static List<RTCVideoRenderer> remoteVideoRenderers = [];

  // static RTCVideoRenderer? remoteRenderer;
  static final HuddleClient huddleClient = HuddleClient();

  static String get RID => gpc.read(currentlyActiveRoom);
  static BuildContext get context => navigatorKey.currentState!.context;

  static Future<void> createRoom({
    required String hostAddress,
    required String title,
  }) async {
    final res = await http.post(
      Uri.parse('https://api.huddle01.com/api/v1/create-room'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': HUDDLE01_API_KEY,
      },
      body: jsonEncode(
        {
          'title': title,
          'hostWallets': [hostAddress],
        },
      ),
    );
    if (res.statusCode == 200) {
      final resdata = jsonDecode(res.body);
      print(resdata);
      final dat = resdata['data'];
      final rid = dat['roomId'];
      gpc.read(currentlyActiveRoom.notifier).state = rid;
      _initializeHuddle();
    } else {
      print('Error in Creating Room');
    }
  }

  static joinRoom(String roomID) async {
    await _initializeHuddle();
    await _joinLobby(roomID);
    print('Joined lobby; Joining Room next');
    await Future.delayed(const Duration(seconds: 1));
    await huddleClient.joinRoom();
    gpc.read(currentlyActiveRoom.notifier).state = roomID;
  }

  static leaveRoom() async {
    gpc.read(currentlyActiveRoom.notifier).state = '';

    //Stop Audio & Video
    await huddleClient.stopProducingAudio();
    await huddleClient.stopAudioStream();
    huddleClient.stopProducingVideo();
    huddleClient.stopVideoStream();
    gpc.read(muteState.notifier).state = true;
    gpc.read(cameraOffState.notifier).state = true;

    await huddleClient.leaveRoom();
    await huddleClient.leaveLobby();
  }

  static toggleMuteState() async {
    final ms = gpc.read(muteState);
    if (ms) {
      await huddleClient.fetchAudioStream();
      await huddleClient.produceAudio(huddleClient.getAudioStream());
      print('Unmuted Audio');
    } else {
      await huddleClient.stopProducingAudio();
      await huddleClient.stopAudioStream();
      print('Muted Audio');
    }
    gpc.read(muteState.notifier).state = !ms;
  }

  static toggleCameraState() async {
    final cs = gpc.read(cameraOffState);
    if (cs) {
      await huddleClient.fetchVideoStream();
      await huddleClient.produceVideo(huddleClient.getVideoStream());
      print('Turned Camera On');
    } else {
      huddleClient.stopProducingVideo();
      huddleClient.stopVideoStream();
      print('Turned Camera Off');
    }
    gpc.read(cameraOffState.notifier).state = !cs;
  }

  static getLocalVideoView() {
    return huddleClient.getRenderer() != null
        ? RTCVideoView(
            huddleClient.getRenderer()!,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          )
        : null;
  }

  static Future<Widget?> getRTCViewByIndex(int idx) async {
    final remoteRenderer = await initializeRemoteRendererByIndex(idx);
    return RTCVideoView(
      remoteRenderer!,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    );
  }

  static initializeRemoteRendererByIndex(int index) async {
    if (index >= remoteVideoRenderers.length) {
      remoteVideoRenderers.add(RTCVideoRenderer());
    }
    await remoteVideoRenderers[index].initialize();
    remoteVideoRenderers[index].srcObject = _getMediaStreamByIndex(index);
    final renderer = remoteVideoRenderers[index];
    // print('Renderer: $renderer');
    return renderer;
  }

  static MediaStream? _getMediaStreamByIndex(int idx) {
    final consumers = huddleClient.getConsumers();
    if (idx > consumers.length) {
      print('getMediaStreamByIndex: Index Greater than number of consumers.');
      return null;
    }
    return (consumers.values.toList()[idx]).stream;
  }

  static getRemoteVideoViewByIndex(int idx) {
    return FutureBuilder(
        future: getRTCViewByIndex(idx),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data ?? const FlutterLogo();
          }
          return const CircularProgressIndicator();
        });
  }

  // ================ Internal Functions =============

  static _initializeHuddle() {
    if (huddleClient.isInitializedCallable()) {
      huddleClient.initialize(HUDDLE01_PROJECT_ID);
    } else {
      print('Already Initialized or Cannot Initialize');
      // customSnackbar(navigatorKey.currentState!.context, 'INITIALIZE');
    }
  }

  static _joinLobby(String providedRoomID) async {
    await huddleClient.joinLobby(providedRoomID);
  }

  // ================= Permissions ===================
  static permissionRequester(Permission perm, [int retryCount = 0]) async {
    final status = await perm.status;

    if (retryCount > 2) {
      print('permissionRequester max retries exceeded for $perm');
      return;
    }

    if (status.isDenied) {
      await perm.request();
    }

    if (status.isGranted) {
      print("$perm Granted!");
      return;
    } else if (status.isDenied) {
      await Permission.camera.request();
      permissionRequester(perm, 1);
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  static grantPermissions() async {
    await permissionRequester(Permission.camera);
    await permissionRequester(Permission.microphone);
  }
}
