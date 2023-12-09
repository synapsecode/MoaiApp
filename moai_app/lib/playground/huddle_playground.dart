import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huddle01_flutter_client/data/value_notifiers.dart' as huddlevns;
import 'package:moai_app/extensions/extensions.dart';

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
        title: const Text('Huddle Playground'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
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
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black),
                          ),
                        ],
                      ),
                    ).center();
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: huddlevns.peersList,
                  builder: (ctx, val, _) {
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.blueGrey.shade100),
                      child: Column(
                        children: [
                          Text(
                            "Peers\n ${val.length}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black),
                          ),
                        ],
                      ),
                    );
                  },
                ).addLeftMargin(20),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Room ID').center(),
            Text(roomID.isEmpty ? 'Nil' : roomID).size(30),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final wp = gpc.read(moaiWalletController);
                if (!wp.isWalletActive) return print('Inactive Wallet');
                await HuddleEngine.createRoom(
                  hostAddress: wp.accountAddress!,
                  title: '0xROOOOM',
                );
              },
              child: const Text('Create New Room'),
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
                          title: const Text('Join Room'),
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
                  child: const Text('Join Existing Room'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await HuddleEngine.leaveRoom();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Leave Room').color(Colors.white),
                ).addLeftMargin(10),
              ],
            ).addTopMargin(10),
            Stack(
              children: [
                Container(
                  color: Colors.grey,
                  width: 220,
                  height: 300,
                  child: HuddleEngine.getLocalVideoView(),
                ).addVerticalMargin(20),
                Positioned(
                  bottom: 30,
                  left: 10,
                  child: Container(
                    color: Colors.black.withAlpha(100),
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: const Text('Me').color(Colors.white),
                  ),
                ),
              ],
            ),
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
            const SizedBox(height: 20),
            const Text('Other Members').size(28),
            const SizedBox(height: 20),
            ValueListenableBuilder(
              valueListenable: huddlevns.peersList,
              builder: (ctx, val, _) {
                if (val.isEmpty) {
                  return const Text('No Members').center().addTopMargin(50);
                }
                print("PeersVal => $val");
                return Wrap(
                  children: [
                    for (int i = 0; i < val.length; i++) ...[
                      Stack(
                        children: [
                          Container(
                            color: Colors.grey,
                            width: 100,
                            height: 180,
                            child: HuddleEngine.getRemoteVideoViewByIndex(i),
                          ).addVerticalMargin(5).addHorizontalMargin(5),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Container(
                              color: Colors.black.withAlpha(100),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              child: Text('Guest ${i + 1}')
                                  .color(Colors.white)
                                  .size(10),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                );
              },
            ).addLeftMargin(20),
            const SizedBox(height: 220),
          ],
        ),
      ),
    );
  }
}
