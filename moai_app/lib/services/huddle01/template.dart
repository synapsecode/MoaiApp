import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:huddle01_flutter_client/huddle01_flutter_client.dart';
import 'package:moai_app/main.dart';
import 'package:moai_app/secrets.dart';
import 'package:moai_app/services/huddle01/acl_methods.dart';
import 'package:moai_app/services/huddle01/huddle_engine.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';

import 'package:permission_handler/permission_handler.dart';

class HuddleTemplateHome extends StatefulWidget {
  const HuddleTemplateHome({super.key});

  @override
  State<HuddleTemplateHome> createState() => _HuddleTemplateHomeState();
}

class _HuddleTemplateHomeState extends State<HuddleTemplateHome> {
  HuddleClient huddleClient = HuddleClient();
  String projectId = HUDDLE01_PROJECT_ID;
  String roomId = '';

  permissionRequester(Permission perm, [int retryCount = 0]) async {
    final status = await perm.status;

    if (retryCount > 2) {
      print('permissionRequester max retries exceeded for $perm');
      return;
    }

    if (status.isDenied) {
      await perm.request();
    }

    if (status.isGranted) {
      return;
    } else if (status.isDenied) {
      await Permission.camera.request();
      permissionRequester(perm, 1);
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  getPermissions() async {
    await permissionRequester(Permission.camera);
    await permissionRequester(Permission.microphone);
  }

  @override
  void initState() {
    getPermissions();
    huddleClient.huddleEventListeners();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // remote-stream
  RTCVideoRenderer? remoteRenderer;
  initilialize() async {
    remoteRenderer = RTCVideoRenderer();
    await remoteRenderer!.initialize();
    remoteRenderer!.srcObject = huddleClient.getFirstRemoteStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Huddle01 Flutter SDK Example'),
      ),
      body: Row(
        children: [
          Expanded(
              child: ListView(
            children: [
              const SizedBox(
                height: 10,
              ),
              Column(
                children: [
                  Text(
                    'Room => $roomId',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    child: const Text('INITIALIZE'),
                    onPressed: () {
                      if (huddleClient.isInitializedCallable()) {
                        huddleClient.initialize(projectId);
                      } else {
                        customSnackbar(context, 'INITIALIZE');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('Create Room'),
                    onPressed: () async {
                      // final wp = gpc.read(moaiWalletController);
                      // if (!wp.isWalletActive) return print('Inactive Wallet');

                      // final rid = await HuddleEngine.createRoom(
                      //     hostAddress: wp.accountAddress!, title: '0xROOOOM');

                      // if (rid == null) return print('Null RoomID');
                      // roomId = rid;
                      // setState(() {});
                    },
                  ),
                  TextButton(
                    child: const Text('JOIN-LOBBY'),
                    onPressed: () {
                      if (huddleClient.isJoinLobbyCallable()) {
                        huddleClient.joinLobby(roomId);
                      } else {
                        customSnackbar(context, 'JOIN-LOBBY');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('JOIN-ROOM'),
                    onPressed: () {
                      if (huddleClient.isJoinRoomCallable()) {
                        huddleClient.joinRoom();
                      } else {
                        customSnackbar(context, 'JOIN-ROOM');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('LEAVE-LOBBY'),
                    onPressed: () {
                      if (huddleClient.isLeaveLobbyCallable()) {
                        huddleClient.leaveLobby();
                      } else {
                        customSnackbar(context, 'LEAVE-LOBBY');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('LEAVE-ROOM'),
                    onPressed: () {
                      if (huddleClient.isleaveRoomCallable()) {
                        huddleClient.leaveRoom();
                      } else {
                        customSnackbar(context, 'LEAVE-ROOM');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('END-ROOM'),
                    onPressed: () {
                      if (huddleClient.isEndRoomCallable()) {
                        huddleClient.endRoom();
                      } else {
                        customSnackbar(context, 'END-ROOM');
                      }
                    },
                  ),
                  const Text(
                    'Audio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                      onPressed: () {
                        huddleClient.enumerateMicDevices();
                      },
                      child: const Text(
                        "ENUMERATE MIC DEVICE",
                        textAlign: TextAlign.center,
                      )),
                  TextButton(
                    child: const Text('FETCH AUDIO STREAM'),
                    onPressed: () {
                      if (huddleClient.isFetchAudioStreamCallable()) {
                        huddleClient.fetchAudioStream();
                      } else {
                        customSnackbar(context, 'FETCH AUDIO STREAM');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('PRODUCE AUDIO'),
                    onPressed: () {
                      if (huddleClient.isProduceAudioCallable()) {
                        huddleClient
                            .produceAudio(huddleClient.getAudioStream());
                      } else {
                        customSnackbar(context, 'PRODUCE AUDIO');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'STOP AUDIO STREAM',
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () {
                      if (huddleClient.isStopAudioStreamCallable()) {
                        huddleClient.stopAudioStream();
                      } else {
                        customSnackbar(context, 'STOP AUDIO STREAM');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'STOP PRODUCING AUDIO',
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () {
                      if (huddleClient.isStopProducingAudioCallable()) {
                        huddleClient.stopProducingAudio();
                      } else {
                        customSnackbar(context, 'STOP PRODUCING AUDIO');
                      }
                    },
                  ),
                  const Text(
                    'Video',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                      onPressed: () {
                        huddleClient.enumerateCamDevices();
                      },
                      child: const Text(
                        "ENUMERATE CAM DEVICE",
                        textAlign: TextAlign.center,
                      )),
                  TextButton(
                    child: const Text(
                      'FETCH VIDEO STREAM',
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () {
                      if (huddleClient.isFetchVideoStreamCallable()) {
                        huddleClient.fetchVideoStream();
                      } else {
                        customSnackbar(context, 'FETCH VIDEO STREAM');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('PRODUCE VIDEO'),
                    onPressed: () {
                      if (huddleClient.isProduceVideoCallable()) {
                        huddleClient
                            .produceVideo(huddleClient.getVideoStream());
                      } else {
                        customSnackbar(context, 'PRODUCE VIDEO');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'STOP VIDEO STREAM',
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () {
                      if (huddleClient.isStopVideoStreamCallable()) {
                        huddleClient.stopVideoStream();
                      } else {
                        customSnackbar(context, 'STOP VIDEO STREAM');
                      }
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'STOP PRODUCING VIDEO',
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () {
                      if (huddleClient.isStopProducingVideoCallable()) {
                        huddleClient.stopProducingVideo();
                      } else {
                        customSnackbar(context, 'STOP PRODUCTING VIDEO');
                      }
                    },
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  // ACL METHODS
                  ACLMethods(huddleClient: huddleClient)
                ],
              ),
            ],
          )),
          Expanded(
            child: ListView(
              children: [
                Column(
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    ValueListenableBuilder(
                      valueListenable: roomState,
                      builder: (ctx, val, _) {
                        return Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.blueGrey.shade100),
                          child: Column(
                            children: [
                              Text(
                                "Room State\n ${val['roomState']}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    ValueListenableBuilder(
                      valueListenable: peersList,
                      builder: (ctx, val, _) {
                        return Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.blueGrey.shade100),
                          child: Column(
                            children: [
                              Text(
                                "Peers\n $val",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                      ),
                      child: const Text(
                        'Get Local Video Stream',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () {
                        setState(() {});
                      },
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: Container(
                        color: Colors.grey,
                        width: 500,
                        height: 250,
                        child: huddleClient.getRenderer() != null
                            ? RTCVideoView(
                                huddleClient.getRenderer()!,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                      ),
                      child: const Text(
                        'Get Remote Stream',
                        style: TextStyle(fontSize: 14),
                      ),
                      onPressed: () async {
                        await initilialize();
                        setState(() {});
                      },
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                      child: Container(
                        color: Colors.grey,
                        width: 500,
                        height: 250,
                        child: huddleClient.getConsumers().isNotEmpty &&
                                remoteRenderer != null
                            ? RTCVideoView(
                                remoteRenderer!,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

customSnackbar(BuildContext context, String snackbarText) {
  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('$snackbarText -> not callable yet'),
    backgroundColor: Colors.red,
    elevation: 4,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(5),
    duration: const Duration(seconds: 1),
  ));
}
