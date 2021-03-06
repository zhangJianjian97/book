import 'package:audioplayers/audioplayers.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/Screen.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/VoiceModel.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/voice/Fast.dart';
import 'package:book/view/voice/VoiceScrollList.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VoiceDetailView extends StatefulWidget {
  String link;
  int idx;

  //  int position;
  VoiceDetailView(this.link, this.idx);

  @override
  _VoiceDetailState createState() => _VoiceDetailState();
}

class _VoiceDetailState extends State<VoiceDetailView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  ColorModel _colorModel;
  VoiceModel _voiceModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _colorModel = Store.value<ColorModel>(context);
    _voiceModel = Store.value<VoiceModel>(context);

    if (_voiceModel.voiceDetail == null &&
        (_voiceModel.audioPlayer.state == AudioPlayerState.PLAYING)) {
      _voiceModel.audioPlayer.release();
    }
    if (_voiceModel.audioPlayer.state == AudioPlayerState.PLAYING) {
      if (this.widget.link != _voiceModel.link) {
        _voiceModel.link = widget.link;
        _voiceModel.idx = widget?.idx ?? 0;
        _voiceModel.init();
      }
    } else {
      _voiceModel.idx = widget?.idx ?? 0;
      _voiceModel.link = widget.link;
      _voiceModel.init();
    }
    _voiceModel.hasEntity = true;
    if (mounted) {
      setState(() {});
    }
  }

//旋转
  Widget buildRotationTransition() {
    return Center(
        child: Container(
      width: 200,
      height: 270,
      child: PicWidget(
        _voiceModel.voiceDetail.cover,
        width: 160,
        height: 220,
      ),
      decoration: BoxDecoration(
          image: DecorationImage(
              image: _voiceModel.voiceDetail.cover.isEmpty
                  ? AssetImage("images/nocover.jpg")
                  : CachedNetworkImageProvider(_voiceModel.voiceDetail.cover),
              fit: BoxFit.cover)),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await _voiceModel.saveRecord();

    // if (state == AppLifecycleState.inactive) {
    //   if (_audioPlayer.state == AudioPlayerState.PLAYING) {
    //     _audioPlayer.pause();
    //   }
    // } else if (state == AppLifecycleState.resumed) {
    //   if (_audioPlayer.state == AudioPlayerState.PAUSED) {
    //     _audioPlayer.resume();
    //   }
    // }
  }

  @override
  void dispose() async {
    super.dispose();
  }

  Widget _tap(img, func) {
    return InkWell(
      child: Container(
        width: 40,
        height: 40,
        child: Image(
          color: Color(0xDFFFFFFF),
          image: AssetImage("images/$img.png"),
        ),
      ),
      onTap: func,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<VoiceModel>(
        builder: (context, VoiceModel model, child) {
      return model.voiceDetail == null
          ? Scaffold()
          : Scaffold(
              body: Container(
              height: Screen.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.accents[_colorModel.idx].shade100,
                  Colors.accents[_colorModel.idx].shade200,
                  // Colors.accents[value.idx].shade400,
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: Screen.topSafeHeight + 100,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildRotationTransition(),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Column(
                      children: [
                        Text(
                          model.voiceDetail?.title ?? '',
                          style: TextStyle(color: Colors.white, fontSize: 25),
                        ),
                        Text(
                          model.voiceDetail?.author ?? '',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          model.voiceDetail?.chapters[_voiceModel.idx].name ??
                              '',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    )
                  ]),
                  SizedBox(
                    height: 40,
                  ),
                  Expanded(child: Container()),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          model.start,
                          style: TextStyle(color: Colors.white),
                        ),
                        Expanded(
                            child: Slider(
                          value: model.position,
                          max: model.len,
                          min: 0.0,
                          onChanged: (v) {
                            model.audioPlayer
                                .seek(Duration(milliseconds: v.floor()));
                          },
                          activeColor: Colors.white,
                          inactiveColor: Colors.white10,
                        )),
                        Text(
                          model.end,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _listCps(),
                        _tap("btx", () {
                          model.changeUrl(-1);
                        }),
                        model.loading == 0
                            ? _tap(model.stateImg, () async {
                                model.toggleState();
                              })
                            : CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                        _tap("btu", () {
                          model.changeUrl(1);
                        }),
                        _fast(),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                ],
              ),
            ));
    });
  }

  Widget _listCps() {
    return InkWell(
        child: Container(
          width: 40,
          height: 40,
          child: Image(
            color: Color(0xFFFFFFFF),
            image: AssetImage("images/list.png"),
          ),
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            builder: (BuildContext context) {
              return VoiceScrollList();
            },
          );
        });
  }

  Widget _fast() {
    return InkWell(
        child: Container(
          width: 40,
          height: 40,
          child: Image(
            color: Color(0xDFFFFFFF),
            image: AssetImage("images/fast.png"),
          ),
        ),
        onTap: () {
          showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              builder: (BuildContext context) {
                return Fast();
              });
        });
  }
}
