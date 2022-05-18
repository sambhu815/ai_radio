import 'dart:convert';

import 'package:ai_radio/model/radio.dart';
import 'package:ai_radio/utils/ai_util.dart';
import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MyRadio> radios = [];

  final url = "https://api.jsonbin.io/b/6278e094019db46796981188";
  late MyRadio _selectedRadio;
  Color? _selectedColor;
  bool _isPlaying = false;
  final sugg = [
    "Play",
    "Stop",
    "Play rock music",
    "Play 107 FM",
    "Play next",
    "Play 104 FM",
    "Pause",
    "Play previous",
    "Play pop music"
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    setupAlon();
    fetchRadio();

    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.PLAYING) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      setState(() {});
    });
  }

  setupAlon() {
    AlanVoice.addButton(
        "47870ac95efe8b55eecca9bbd67487932e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_LEFT);
    AlanVoice.callbacks.add((command) => _handleCommands(command.data));
  }

  _handleCommands(Map<String, dynamic> response) {
    switch (response["command"]) {
      case "play":
        _playMusic(_selectedRadio.url);
        break;

      case "play_channel":
        final id = response["id"];
        MyRadio newRadio = radios.firstWhere((element) => element.id == id);
        radios.remove(newRadio);
        radios.insert(0, newRadio);
        _playMusic(newRadio.url);
        break;

      case "stop":
        _audioPlayer.stop();
        break;

      case "next":
        final index = _selectedRadio.id;
        MyRadio newRadio;
        if (index + 1 > radios.length) {
          newRadio = radios.firstWhere((element) => element.id == 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        } else {
          newRadio = radios.firstWhere((element) => element.id == index + 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;
      case "prev":
        final index = _selectedRadio.id;
        MyRadio newRadio;
        if (index - 1 <= 0) {
          newRadio = radios.firstWhere((element) => element.id == 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        } else {
          newRadio = radios.firstWhere((element) => element.id == index - 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;
    }
  }

  fetchRadio() async {
    final response = await http.get(Uri.parse(url));
    final radioJson = response.body;
    final decodeData = jsonDecode(radioJson);
    final radioData = decodeData["radios"];
    radios = List.from(radioData)
        .map<MyRadio>((radio) => MyRadio.fromMap(radio))
        .toList();
    _selectedRadio = radios[0];
    _selectedColor = Color(int.tryParse(_selectedRadio.color)!);
    setState(() {});
  }

  _playMusic(String url) {
    _audioPlayer.play(url);
    _selectedRadio = radios.firstWhere((element) => element.url == url);
    print(_selectedRadio.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: _selectedColor ?? AIUtil.primaryColor2,
        child: radios.isNotEmpty
            ? VStack(
                [
                  100.heightBox,
                  "All Channels".text.xl.white.semiBold.make().px12(),
                  20.heightBox,
                  ListView(
                    padding: Vx.m0,
                    shrinkWrap: true,
                    children: radios
                        .map((e) => ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(e.image),
                              ),
                              title: "${e.name} FM".text.white.make(),
                              subtitle: e.tagline.text.white.make(),
                            ))
                        .toList(),
                  ).expand()
                ],
                crossAlignment: CrossAxisAlignment.start,
              )
            : const Offstage(),
      ),
      body: Stack(
        children: [
          VxAnimatedBox()
              .size(context.screenWidth, context.screenHeight)
              .withGradient(LinearGradient(colors: [
                AIUtil.primaryColor1,
                _selectedColor ?? AIUtil.primaryColor2
              ], begin: Alignment.topLeft, end: Alignment.bottomRight))
              .make(),
          [
            AppBar(
              title: "AI Radio".text.xl2.bold.white.make().shimmer(
                  primaryColor: Vx.purple300, secondaryColor: Vx.white),
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0.0,
            ).h(80),
            20.heightBox,
            "Start with - Hey Alan".text.italic.semiBold.white.make(),
            20.heightBox,
            VxSwiper.builder(
                autoPlay: true,
                autoPlayAnimationDuration: 3.seconds,
                autoPlayCurve: Curves.linear,
                enableInfiniteScroll: true,
                height: 50.0,
                viewportFraction: 0.35,
                itemCount: sugg.length,
                itemBuilder: (context, index) {
                  final s = sugg[index];
                  return Chip(
                      label: s.text.make(), backgroundColor: Vx.randomColor);
                }),
          ].vStack(),
          30.heightBox,
          radios.isNotEmpty
              ? VxSwiper.builder(
                  itemCount: radios.length,
                  aspectRatio: context.mdWindowSize == MobileDeviceSize.small
                      ? 1.0
                      : context.mdWindowSize == MobileDeviceSize.medium
                          ? 2.0
                          : 1.0,
                  enlargeCenterPage: true,
                  onPageChanged: (index) {
                    final colorHex = radios[index].color;
                    _selectedColor = Color(int.tryParse(colorHex)!);
                    _selectedRadio = radios[index];
                    setState(() {});
                  },
                  itemBuilder: (context, index) {
                    final rad = radios[index];

                    return VxBox(
                            child: ZStack(
                      [
                        Positioned(
                            top: 0.0,
                            right: 0.0,
                            child: VxBox(
                              child: rad.category.text.uppercase.white
                                  .make()
                                  .px16(),
                            )
                                .height(40)
                                .black
                                .alignCenter
                                .withRounded(value: 10.0)
                                .make()),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: VStack(
                            [
                              rad.name.text.xl3.white.bold.make(),
                              5.heightBox,
                              rad.tagline.text.sm.white.semiBold.make()
                            ],
                            crossAlignment: CrossAxisAlignment.center,
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: [
                            const Icon(
                              CupertinoIcons.play_circle,
                              color: Colors.white,
                            ),
                            10.heightBox,
                            "Double tab to play".text.gray300.make()
                          ].vStack(),
                        )
                      ],
                    ))
                        .clip(Clip.antiAlias)
                        .bgImage(DecorationImage(
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken),
                            image: NetworkImage(rad.image)))
                        .border(color: Colors.black, width: 5.0)
                        .withRounded(value: 60.0)
                        .make()
                        .onInkDoubleTap(() {
                      _playMusic(rad.url);
                    }).p16();
                  },
                ).centered()
              : const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                ),
          Align(
            alignment: Alignment.bottomCenter,
            child: [
              if (_isPlaying)
                "Playing Now - ${_selectedRadio.name} FM"
                    .text
                    .white
                    .makeCentered()
                    .shimmer(),
              Icon(
                      _isPlaying
                          ? CupertinoIcons.stop_circle
                          : CupertinoIcons.play_circle,
                      size: 50.0,
                      color: Colors.white)
                  .onInkTap(() {
                if (_isPlaying) {
                  _audioPlayer.stop();
                } else {
                  _playMusic(_selectedRadio.url);
                }
              })
            ].vStack(),
          ).pOnly(bottom: context.percentHeight * 12)
        ],
        fit: StackFit.expand,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
