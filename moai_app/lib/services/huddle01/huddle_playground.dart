import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huddle01_flutter_client/data/value_notifiers.dart' as huddlevns;
import 'package:huddle01_flutter_client/huddle_client.dart';
import 'package:moai_app/extensions/extensions.dart';
import 'package:moai_app/extensions/miscextensions.dart';

import 'package:moai_app/services/huddle01/huddle_engine.dart';
import 'package:moai_app/main.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';

class HuddlePlayground extends ConsumerStatefulWidget {
  const HuddlePlayground({super.key});

  @override
  ConsumerState<HuddlePlayground> createState() => _HuddlePlaygroundState();
}

class _HuddlePlaygroundState extends ConsumerState<HuddlePlayground> {
  @override
  void initState() {
    HuddleEngine.grantPermissions();
    HuddleEngine.huddleClient.huddleEventListeners();
    super.initState();
  }

  TextEditingController ridc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final roomID = ref.watch(HuddleEngine.currentlyActiveRoom);
    final muted = ref.watch(HuddleEngine.muteState);
    final videoOff = ref.watch(HuddleEngine.cameraOffState);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Huddle Playground'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: huddlevns.roomState,
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
                        style:
                            const TextStyle(fontSize: 15, color: Colors.black),
                      ),
                    ],
                  ),
                ).center();
              },
            ),
            SizedBox(height: 20),
            Text('Room ID').center(),
            Text(roomID.isEmpty ? 'Nil' : roomID).size(30),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final wp = gpc.read(moaiWalletController);
                if (!wp.isWalletActive) return print('Inactive Wallet');
                await HuddleEngine.createRoom(
                  hostAddress: wp.accountAddress!,
                  title: '0xROOOOM',
                );
              },
              child: Text('Create New Room'),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Join Room'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: ridc,
                                decoration: const InputDecoration(
                                    hintText: 'Enter RoomID'),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (ridc.value.text.isEmpty) return;
                                    await HuddleEngine.joinRoom(
                                        ridc.value.text);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black),
                                  child: const Text('Join Room'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Text('Join Existing Room'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await HuddleEngine.leaveRoom();
                  },
                  child: Text('Leave Room').color(Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ).addLeftMargin(10),
              ],
            ).addTopMargin(10),
            Container(
              height: 200,
              width: 140,
              color: Colors.grey,
            ).addVerticalMargin(20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: IconButton(
                    onPressed: () {
                      HuddleEngine.toggleMuteState();
                    },
                    icon: muted
                        ? Icons.volume_off.toIcon()
                        : Icons.volume_up.toIcon(),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: IconButton(
                    onPressed: () {
                      HuddleEngine.toggleCameraState();
                    },
                    icon: videoOff
                        ? Icons.videocam_off.toIcon()
                        : Icons.video_call.toIcon(),
                  ),
                ).addLeftMargin(20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
