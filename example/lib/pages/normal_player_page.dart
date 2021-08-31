import 'dart:io';

import 'package:better_player/better_player.dart';
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
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 12,
      fit: BoxFit.contain,
      fullScreenByDefault: true,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        setting: SvgPicture.asset(
          'assets/svg/settings.svg',
          color: Colors.white,
        ),
        brightness: SvgPicture.asset(
          'assets/svg/brightnes.svg',
          height: 24,
          width: 24,
        ),
        progressBarPlayedColor: Colors.red,
        volume: SvgPicture.asset(
          'assets/svg/volume.svg',
          height: 24,
          width: 24,
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
        closeMiniVideo: () {
          _betterPlayerController.exitFullScreen();
        },
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
        textColor: Colors.white,
      ),
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        // "https://voxe-cdn.s3.eu-north-1.amazonaws.com/720p/9445712b398b74e9a917666587265bdd/video.m3u8",
        "https://voxe-cdn.s3.eu-north-1.amazonaws.com/720p/dd8addc7286ad02d73b049ee33244931/video.m3u8",
        cacheConfiguration: getCacheConfiguration(),
        isMiniVideo: true,
        volume: 1.0,
        useHlsAudioTracks: false,
        useHlsSubtitles: false,
        useHlsTracks: false,
        // isPrefetch: true,
        isSerial: true,
        // rotation: 1280 / 720
        rotation: 1280 / 534
        // startAt: Duration(seconds: 35),
        // autoPlay: true,
        );

    /// 1280:720
    /// 1280:534
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.addEventsListener((event) {
      debugPrint("TTT: ${event.betterPlayerEventType.toString()}");
      if (event.betterPlayerEventType == BetterPlayerEventType.hideFullscreen) {
        _betterPlayerController.pause();
      }
    });
    super.initState();
  }

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
          BetterPlayer(
            controller: _betterPlayerController,
            locale: Locale('uz', 'UZ'),
          ),
          ElevatedButton(
            child: Text("Play file data source"),
            onPressed: () async {
              // _betterPlayerController.stop();
              /*String url = await Utils.getFileUrl(Constants.testUrl);
              BetterPlayerDataSource dataSource =
                  BetterPlayerDataSource(BetterPlayerDataSourceType.file, url);
              _betterPlayerController.setupDataSource(dataSource);*/
            },
          ),
        ],
      ),
    );
  }

  BetterPlayerCacheConfiguration getCacheConfiguration() {
    return Platform.isAndroid
        ? BetterPlayerCacheConfiguration(
            useCache: true,
            maxCacheFileSize: 8096 * 8096 * 8096,
            maxCacheSize: 8096 * 8096 * 8096)
        : BetterPlayerCacheConfiguration(useCache: false);
  }
}
