import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NormalPlayerPage extends StatefulWidget {
  @override
  _NormalPlayerPageState createState() => _NormalPlayerPageState();
}

class _NormalPlayerPageState extends State<NormalPlayerPage> {
  BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      translations: [],
      allowedScreenSleep: false,
      // autoDetectFullscreenDeviceOrientation: true,
      controlsConfiguration: BetterPlayerControlsConfiguration(
          setting: SvgPicture.asset(
            'assets/svg/settings.svg',
            color: Colors.white,
          ),
          playerTheme: BetterPlayerTheme.cupertino,
          play: Container(
            padding: EdgeInsets.only(left: 4),
            child: SvgPicture.asset(
              'assets/svg/play.svg',
              color: Colors.white,
            ),
          ),
          pause: SvgPicture.asset(
            'assets/svg/ic_pause.svg',
            color: Colors.white,
          ),
          closeMiniVideo: () {},
          enterFullScreen: SvgPicture.asset(
            'assets/svg/maximize.svg',
            color: Colors.white,
          ),
          exitFullScreen: SvgPicture.asset(
            'assets/svg/minimize.svg',
            color: Colors.white,
          ),
          next: SvgPicture.asset(
            'assets/svg/skip_next.svg',
            color: Colors.white,
            width: 32,
            height: 32,
          ),
          onVideoEnd: () {},
          track: () {},
          prev: SvgPicture.asset(
            'assets/svg/skip_prev.svg',
            color: Colors.white,
            width: 32,
            height: 32,
          ),
          skipBackIcon: Icons.replay_10,
          skipForwardIcon: Icons.forward_10,
          nextEpisode: () {},
          prevEpisode: () {},
          enableAudioTracks: false,
          enableSubtitles: false,
          qualitiesIcon: SvgPicture.asset(
            'assets/svg/settings.svg',
            color: Colors.white,
          ),
          subtitlesIcon: SvgPicture.asset(
            'assets/svg/file_text.svg',
            color: Colors.white,
          ),
          playbackSpeedIcon: SvgPicture.asset(
            'assets/svg/play_circle.svg',
            color: Colors.white,
          ),
          bottomSheet: Color(0xff263c44),
          textColor: Colors.white),
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      "http://cdn.theoplayer.com/video/elephants-dream/playlist.m3u8",
      cacheConfiguration: getCacheConfiguration(),
      isMiniVideo: true,
      volume: 1.0,
      // isPrefetch: true,
      isSerial: true,
      // startAt: Duration(seconds: 35),
      // autoPlay: true,
    );
    _betterPlayerController =
        BetterPlayerController(betterPlayerConfiguration, onAddTrack: onChangeTrack);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  void onChangeTrack() {
    setState(() {});
  }

  String percent = '';

  @override
  Widget build(BuildContext context) {
    // _betterPlayerController.changeOfflineMode(true);
    return Scaffold(
      appBar: AppBar(
        title: Text("Normal player"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Normal player with configuration managed by developer.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(
              controller: _betterPlayerController,
              locale: Locale('uz', 'UZ'),
            ),
          ),
          ElevatedButton(
            child: Text("Play file data source"),
            onPressed: () async {
              var trueList = _betterPlayerController.trackList.where((element) => element);
              setState(() {
                percent = "${(trueList.length / _betterPlayerController.trackList.length) * 100}";
              });
              // _betterPlayerController.stop();
              /*String url = await Utils.getFileUrl(Constants.testUrl);
              BetterPlayerDataSource dataSource =
                  BetterPlayerDataSource(BetterPlayerDataSourceType.file, url);
              _betterPlayerController.setupDataSource(dataSource);*/
            },
          ),
          Text(
            percent,
            style: TextStyle(fontSize: 22, color: Colors.black),
          ),
          /*Expanded(
            child: ListView.builder(
                padding: EdgeInsets.all(12),
                physics: BouncingScrollPhysics(),
                itemCount: _betterPlayerController.videoTrackList.length,
                itemBuilder: (context, index) {
                  return Text(
                    "${_betterPlayerController.videoTrackList[index].start} - ${_betterPlayerController.videoTrackList[index].end}",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),
          ),*/
        ],
      ),
    );
  }

  BetterPlayerCacheConfiguration getCacheConfiguration() {
    return Platform.isAndroid
        ? BetterPlayerCacheConfiguration(
            useCache: true, maxCacheFileSize: 8096 * 8096 * 8096, maxCacheSize: 8096 * 8096 * 8096)
        : BetterPlayerCacheConfiguration(useCache: false);
  }
}
