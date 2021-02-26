import 'dart:async';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/core/utils.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'better_player_clickable_widget.dart';
import 'better_player_cupertino_progress_bar.dart';

class BetterPlayerCupertinoControls extends StatefulWidget {
  final Function(bool visbility) onControlsVisibilityChanged;

  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerCupertinoControls({
    Key key,
    @required this.onControlsVisibilityChanged,
    @required this.controlsConfiguration,
  })  : assert(onControlsVisibilityChanged != null),
        assert(controlsConfiguration != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BetterPlayerCupertinoControlsState();
  }
}

class _BetterPlayerCupertinoControlsState
    extends BetterPlayerControlsState<BetterPlayerCupertinoControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _displayTapped = false;
  bool _wasLoading = false;
  VideoPlayerController _controller;
  BetterPlayerController _betterPlayerController;
  StreamSubscription _controlsVisibilityStreamSubscription;

  BetterPlayerControlsConfiguration get _controlsConfiguration => widget.controlsConfiguration;

  @override
  VideoPlayerValue get latestValue => _latestValue;

  @override
  BetterPlayerController get betterPlayerController => _betterPlayerController;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration => _controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    _wasLoading = isLoading(_latestValue);
    if (_latestValue?.hasError == true) {
      _hideStuff = false;

      return Container(
        color: Colors.black26,
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: () {
                        /* backCheckTrack(
                          seekDuration: _controller.value.position.inSeconds >= 10
                              ? (Duration(seconds: _controller.value.position.inSeconds - 10))
                              : Duration.zero,
                          lastDuration: Duration(
                            seconds: _controller.value.position.inSeconds > 0
                                ? (_controller.value.position.inSeconds)
                                : 0,
                          ),
                        );*/
                        skipBack();
                      },
                      onTap: () {
                        _hideStuff
                            ? cancelAndRestartTimer()
                            : setState(() {
                                _hideStuff = true;
                              });
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: () {
                        /* nextCheckTrack(
                          seekDuration:
                              Duration(seconds: _controller.value.position.inSeconds + 10),
                          lastDuration: _controller.value.position,
                        );*/
                        skipForward();
                      },
                      onTap: () {
                        _hideStuff
                            ? cancelAndRestartTimer()
                            : setState(() {
                                _hideStuff = true;
                              });
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: _buildErrorWidget(),
            ),
            Align(alignment: Alignment.bottomCenter, child: _buildBottomBar()),
          ],
        ),
      );
    }
    return MouseRegion(
      onHover: (_) {
        cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () {
          _hideStuff
              ? cancelAndRestartTimer()
              : setState(() {
                  _hideStuff = true;
                });
        },
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: [
              _wasLoading
                  ? Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                            top: getPaddingSize(_controlsConfiguration.controlBarHeight)),
                        child: Center(
                          child: _buildLoadingWidget(),
                        ),
                      ),
                    )
                  : _buildHitArea(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _controller?.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController.videoPlayerController;
    _latestValue = _controller.value;

    if (_oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildErrorWidget() {
    final errorBuilder = _betterPlayerController.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
          context, _betterPlayerController.videoPlayerController.value.errorDescription);
    } else {
      final textStyle = TextStyle(color: _controlsConfiguration.textColor);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: _controlsConfiguration.iconsColor,
            size: getIconSize(32),
          ),
          Text(
            _betterPlayerController.translations.generalDefaultError,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
          if (_controlsConfiguration.enableRetry)
            FlatButton(
              onPressed: () {
                _betterPlayerController.retryDataSource();
              },
              child: Text(
                _betterPlayerController.translations.generalRetry,
                style: textStyle.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          stops: gradientStops,
          end: Alignment.topCenter,
          begin: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: AnimatedOpacity(
          opacity: _hideStuff ? 0.0 : 1.0,
          duration: _controlsConfiguration.controlsHideTime,
          onEnd: _onPlayerHide,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: getPaddingWidth(0)),
            height: getPaddingSize(_controlsConfiguration.controlBarHeight),
            child: Column(
              children: [
                SizedBox(
                  height: getIconSize(24),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 8,
                      ),
                      _buildPlayPause(_controller, getIconSize(24), 0),
                      SizedBox(
                        width: 12,
                      ),
                      _buildMuteButton(_controller),
                      SizedBox(
                        width: 12,
                      ),
                      _buildCurrentPosition(),
                      _buildTotalPosition(),
                      Spacer(),
                      if (_betterPlayerController.isLiveStream())
                        _buildLiveWidget()
                      else
                        _controlsConfiguration.enableProgressText
                            ? _buildPosition()
                            : const SizedBox(),
                      _buildSettingButton(),
                      SizedBox(
                        width: 12,
                      ),
                      _buildExpandButton(),
                      SizedBox(
                        width: 8,
                      ),
                    ],
                  ),
                ),
                _buildProgressBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveWidget() {
    return Expanded(
      child: Text(
        _betterPlayerController.translations.controlsLive,
        style: TextStyle(color: _controlsConfiguration.liveTextColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildExpandButton() {
    return BetterPlayerMaterialClickableWidget(
      onTap: _onExpandCollapse,
      child: SizedBox(
          width: getIconSize(24),
          height: getIconSize(24),
          child: _betterPlayerController.isFullScreen
              ? _controlsConfiguration.exitFullScreen
              : _controlsConfiguration.enterFullScreen),
    );
  }

  Widget _buildHitArea() {
    if (!betterPlayerController.controlsEnabled) {
      return const SizedBox();
    }
    return Expanded(
      child: Container(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: _hideStuff ? 0.0 : 1.0,
          duration: _controlsConfiguration.controlsHideTime,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: () {
                            /*backCheckTrack(
                              seekDuration: _controller.value.position.inSeconds >= 10
                                  ? (Duration(seconds: _controller.value.position.inSeconds - 10))
                                  : Duration.zero,
                              lastDuration: Duration(
                                seconds: _controller.value.position.inSeconds > 0
                                    ? (_controller.value.position.inSeconds)
                                    : 0,
                              ),
                            );*/
                            skipBack();
                          },
                          onTap: () {
                            _hideStuff
                                ? cancelAndRestartTimer()
                                : setState(() {
                                    _hideStuff = true;
                                  });
                          },
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                          )),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: () {
                          /*nextCheckTrack(
                            seekDuration:
                                Duration(seconds: _controller.value.position.inSeconds + 10),
                            lastDuration: _controller.value.position,
                          );*/
                          skipForward();
                        },
                        onTap: () {
                          _hideStuff
                              ? cancelAndRestartTimer()
                              : setState(() {
                                  _hideStuff = true;
                                });
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Visibility(
                visible: _betterPlayerController.betterPlayerDataSource.isMiniVideo,
                child: Positioned(
                    top: 8,
                    left: _betterPlayerController.isFullScreen ? 16 : 8,
                    child: BetterPlayerMaterialClickableWidget(
                      onTap: _controlsConfiguration.closeMiniVideo,
                      color: Colors.black26,
                      child: Icon(
                        Icons.clear,
                        color: Colors.white,
                        size: getIconSize(32),
                      ),
                    )),
              ),
              _buildMiddleRow(),
              _buildNextVideoWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiddleRow() {
    return Container(
      margin: EdgeInsets.only(top: getPaddingSize(_controlsConfiguration.controlBarHeight)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSkipButton(),
            SizedBox(
              width: 32,
            ),
            _buildPrevButton(),
            SizedBox(
              width: 32,
            ),
            _buildCenterButton(4),
            SizedBox(
              width: 32,
            ),
            _buildNextButton(),
            SizedBox(
              width: 32,
            ),
            _buildForwardButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHitAreaClickableButton({Widget icon, void Function() onClicked}) {
    return BetterPlayerMaterialClickableWidget(
      onTap: onClicked,
      radius: 0,
      child: Align(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: icon,
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return BetterPlayerMaterialClickableWidget(
      child: Container(
        margin: EdgeInsets.all(4),
        child: Icon(
          _controlsConfiguration.skipBackIcon,
          size: getIconSize(32),
          color: _controlsConfiguration.iconsColor,
        ),
      ),
      onTap: () {
        /*  backCheckTrack(
          seekDuration: _controller.value.position.inSeconds >= 10
              ? (Duration(seconds: _controller.value.position.inSeconds - 10))
              : Duration.zero,
          lastDuration: Duration(
            seconds: _controller.value.position.inSeconds > 0
                ? (_controller.value.position.inSeconds)
                : 0,
          ),
        );*/
        skipBack();
      },
      // onDoubleTap: skipBack,
    );
  }

  Widget _buildPrevButton() {
    return Visibility(
      visible: _betterPlayerController.betterPlayerDataSource.isSerial,
      child: BetterPlayerMaterialClickableWidget(
        child: Container(
            width: getIconSize(32),
            height: getIconSize(32),
            margin: EdgeInsets.all(4),
            child: _controlsConfiguration.prev ?? SizedBox()),
        onTap: _controlsConfiguration.prevEpisode,
      ),
    );
  }

  Widget _buildNextButton() {
    return Visibility(
      visible: _betterPlayerController.betterPlayerDataSource.isSerial,
      child: BetterPlayerMaterialClickableWidget(
        child: Container(
            width: getIconSize(32),
            height: getIconSize(32),
            margin: EdgeInsets.all(4),
            child: _controlsConfiguration.next ?? SizedBox()),
        onTap: _controlsConfiguration.nextEpisode,
      ),
    );
  }

  Widget _buildForwardButton() {
    return BetterPlayerMaterialClickableWidget(
      child: Container(
        margin: EdgeInsets.all(4),
        child: Icon(
          _controlsConfiguration.skipForwardIcon,
          size: getIconSize(32),
          color: _controlsConfiguration.iconsColor,
        ),
      ),
      onTap: () {
        // _videoTrackList
        //     .add(VideoTrackDuration(start: _startPos, end: _controller.value.position.inSeconds));
        /* nextCheckTrack(
          seekDuration: Duration(seconds: _controller.value.position.inSeconds + 10),
          lastDuration: _controller.value.position,
        );*/
        skipForward();
      },
      // onDoubleTap: skipForward,
    );
  }

  Widget _buildCenterButton(double margin) {
    final bool isFinished = isVideoFinished(_latestValue);
    if (!isFinished) {
      return _buildPlayPause(_controller, getIconSize(40), margin);
    }
    return BetterPlayerMaterialClickableWidget(
      child: Container(
        margin: EdgeInsets.all(4),
        child: Icon(
          Icons.replay,
          size: getIconSize(32),
          color: _controlsConfiguration.iconsColor,
        ),
      ),
      onTap: () {
        if (_latestValue != null && _latestValue.isPlaying) {
          if (_displayTapped) {
            setState(() {
              _hideStuff = true;
            });
          } else {
            cancelAndRestartTimer();
          }
        } else {
          _onPlayPause();
          setState(() {
            _hideStuff = true;
          });
        }
      },
    );
  }

  Widget _buildNextVideoWidget() {
    return StreamBuilder<int>(
      stream: _betterPlayerController.nextVideoTimeStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          return BetterPlayerMaterialClickableWidget(
            onTap: () {
              _betterPlayerController.playNextVideo();
            },
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4, right: 24),
                decoration: BoxDecoration(
                  color: _controlsConfiguration.controlBarColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "${_betterPlayerController.translations.controlsNextVideoIn} ${snapshot.data} ...",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildSettingButton() {
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        onShowMoreClicked(_controlsConfiguration.bottomSheet, _controlsConfiguration.textColor);
      },
      child: SizedBox(
          width: getIconSize(24), height: getIconSize(24), child: _controlsConfiguration.setting),
    );
  }

  Widget _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        cancelAndRestartTimer();
        if (_latestValue.volume == 0) {
          _betterPlayerController.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          _betterPlayerController.setVolume(0.0);
        }
      },
      child: Icon(
        (_latestValue != null && _latestValue.volume > 0)
            ? _controlsConfiguration.muteIcon
            : _controlsConfiguration.unMuteIcon,
        color: _controlsConfiguration.iconsColor,
        size: getIconSize(24),
      ),
    );
  }

  Widget _buildPlayPause(VideoPlayerController controller, double size, double margin) {
    return BetterPlayerMaterialClickableWidget(
      onTap: _onPlayPause,
      child: Container(
          height: size,
          width: size,
          margin: EdgeInsets.all(margin),
          child: controller.value.isPlaying
              ? _controlsConfiguration.pause
              : _controlsConfiguration.play),
    );
  }

  Widget _buildPosition() {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Text(
        '${BetterPlayerUtils.formatDuration(position)} / ${BetterPlayerUtils.formatDuration(duration)}',
        style: TextStyle(
          fontSize: 14,
          color: _controlsConfiguration.textColor,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();
    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<void> _initialize() async {
    _controller.addListener(_updateState);
    // _betterPlayerController.addEventsListener((event) {
    //   if (event.betterPlayerEventType == BetterPlayerEventType.play) {
    //     // _startPos = _controller.value.position.inSeconds;
    //     print("PLAYYYYYYYYYY");
    //   } else if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
    //     print("PAUSEEEEEEEEE");
    //     _betterPlayerController.addVideoTrack(
    //         start: _startPos, end: _controller.value.position.inSeconds);
    //     _startPos = _controller.value.position.inSeconds + 1;
    //   }
    // });
    _updateState();

    if ((_controller.value != null && _controller.value.isPlaying) ||
        _betterPlayerController.betterPlayerDataSource.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }

    _controlsVisibilityStreamSubscription =
        _betterPlayerController.controlsVisibilityStream.listen((state) {
      setState(() {
        _hideStuff = !state;
      });
      if (!_hideStuff) {
        cancelAndRestartTimer();
      }
    });
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;
      _betterPlayerController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(_controlsConfiguration.controlsHideTime, () {
        setState(() {
          cancelAndRestartTimer();
        });
      });
    });
  }

  Widget _buildCurrentPosition() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    String textPosition = position != null ? formatDuration(position) : '00:00';

    if (position != null && duration != null && position >= duration) {
      _controlsConfiguration.onVideoEnd();
    }

    if (!_betterPlayerController.isOffline &&
        position != null &&
        position.inSeconds != 0 &&
        position.inSeconds % 30 == 0) {
      // _controlsConfiguration.track(position.inSeconds);
    }

    return Text(
      "${textPosition} / ",
      style: TextStyle(fontSize: 14, color: Colors.white),
    );
  }

  Widget _buildTotalPosition() {
    String textDuration =
        _controller.value.duration != null ? formatDuration(_controller.value.duration) : '00:00';
    return Text(
      textDuration,
      style: TextStyle(fontSize: 14, color: Colors.white),
    );
  }

  void _onPlayPause() {
    bool isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue.position >= _latestValue.duration;
    }

    setState(() {
      if (_controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        _betterPlayerController.pause();
      } else {
        cancelAndRestartTimer();
        if (!_controller.value.initialized) {
        } else {
          if (isFinished) {
            _betterPlayerController.seekTo(const Duration());
          }

          _betterPlayerController.play();
          _betterPlayerController.cancelNextVideoTimer();
        }
      }
    });
  }

  void _startHideTimer() {
    if (_betterPlayerController.controlsAlwaysVisible) {
      return;
    }
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  int _oldPos = 0;

  void _updateState() {
    if (mounted) {
      if (!_hideStuff ||
          isVideoFinished(_controller.value) ||
          _wasLoading ||
          isLoading(_controller.value)) {
        setState(() {
          _latestValue = _controller.value;
          if (isVideoFinished(_latestValue)) {
            _hideStuff = false;
          }
        });
      }
      if (_controller.value.position.inSeconds == _oldPos) return;
      _betterPlayerController.changeTrack(true, _controller.value.position.inSeconds ~/ 1.7);
      _oldPos = _controller.value.position.inSeconds;
      /*  if (_controller.value.position.inSeconds > 0 &&
          _startPos == _controller.value.position.inSeconds) {
        _isSeen = false;
      }
      if (_controller.value.position.inSeconds == _lastSeenInterval.start) {
        _betterPlayerController.addVideoTrack(start: _startPos, end: _lastSeenInterval.start - 1);
        _startPos = _lastSeenInterval.end + 1;
        _isSeen = true;
      }*/
    }
  }

/*

  Demo checkInterval(Duration seekDuration) {
    print("SEEKDURATION: ${seekDuration.inSeconds}");
    bool isFind = false;
    int findElementEndPos;
    int findElementStartPos;
    if (seekDuration.inSeconds == 0)
      return Demo(isFind: true, findElementEndPos: 0, findElementStartPos: 0);

    _betterPlayerController.videoTrackList.forEach((element) {
      if (seekDuration.inSeconds >= element.start && seekDuration.inSeconds <= element.end) {
        findElementEndPos = element.end;
        findElementStartPos = element.start;
        print("WWWWWWWWWWWWWW: KO'RILGAN");
        isFind = true;
      }
    });
    if (!isFind) {
      print("WWWWWWWWWWWWWW: KO'RILMAGAN");
      _isSeen = false;
    }
    return Demo(
        isFind: isFind,
        findElementEndPos: findElementEndPos ?? seekDuration.inSeconds,
        findElementStartPos: findElementStartPos ?? seekDuration.inSeconds);
  }

  void backCheckTrack({Duration seekDuration, Duration lastDuration}) {
    print("WWWWWWWWWWWWWW: BACK");
    print("WWWWWWWWWWWWWW: ${_isSeen}");
    if (_isSeen && _lastSeenInterval.start < seekDuration.inSeconds) {
      return;
    }
    var a = checkInterval(seekDuration);
    if (seekDuration.inSeconds >= _startPos && lastDuration.inSeconds > seekDuration.inSeconds) {
      _isSeen = true;
      betterPlayerController.addVideoTrack(start: _startPos, end: lastDuration.inSeconds);
      _startPos = lastDuration.inSeconds + 1;
      return;
    }
    if (a.isFind &&
        a.findElementEndPos < lastDuration.inSeconds &&
        !(lastDuration.inSeconds > _lastSeenInterval.start &&
            lastDuration.inSeconds < _lastSeenInterval.end)) {
      _isSeen = true;
      betterPlayerController.addVideoTrack(start: _startPos, end: lastDuration.inSeconds);
      _startPos = a.findElementEndPos + 1;
      _lastSeenInterval =
          VideoTrackDuration(start: a.findElementStartPos, end: a.findElementEndPos);
    } else if (a.isFind &&
        !(lastDuration.inSeconds > _lastSeenInterval.start &&
            lastDuration.inSeconds < _lastSeenInterval.end)) {
      _startPos = a.findElementEndPos + 1;
    } else {
      betterPlayerController.addVideoTrack(start: _startPos, end: lastDuration.inSeconds);
      _startPos = a.findElementEndPos + 1;
      _lastSeenInterval =
          VideoTrackDuration(start: a.findElementStartPos, end: a.findElementEndPos);
      _isSeen = false;
    }
    _isSeen = false;
  }

  void nextCheckTrack({Duration seekDuration, Duration lastDuration}) {
    print("WWWWWWWWWWWWWW: GO");
    var a = checkInterval(seekDuration);
    print("${_isSeen} AAAAAAAAAAAAAAAAA");
    if (_isSeen) {
      return;
    }
    print("aaaaa");
    if (!a.isFind) {
      _isSeen = false;
      print("WWWWWWWWWWWWWW: GO ADD");
      _betterPlayerController.addVideoTrack(start: _startPos, end: lastDuration.inSeconds);
      _startPos = seekDuration.inSeconds;
      return;
    }
    if (a.isFind) {
      _isSeen = true;
      _betterPlayerController.addVideoTrack(start: _startPos, end: a.findElementStartPos);
      _startPos = a.findElementEndPos + 1;
      _lastSeenInterval =
          VideoTrackDuration(start: a.findElementStartPos, end: a.findElementEndPos);
      return;
    }
    _isSeen = false;
  }
*/

  int _startPos = 0;
  bool _isSeen = false;
  VideoTrackDuration _lastSeenInterval = VideoTrackDuration(start: 0, end: 0);

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          right: 12,
          left: 12,
        ),
        child: BetterPlayerCupertinoVideoProgressBar(
          _controller,
          _betterPlayerController,
          onDragStart: () {
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            _startHideTimer();
          },
          onSeek: (seekDuration, lastDuration) {
            /* if (_controller.value.isPlaying) {
              if (seekDuration.inSeconds < lastDuration.inSeconds) {
                backCheckTrack(seekDuration: seekDuration, lastDuration: lastDuration);
              } else {
                nextCheckTrack(seekDuration: seekDuration, lastDuration: lastDuration);
              }
            } else {
              _startPos = _controller.value.position.inSeconds;
            }*/
          },
          colors: BetterPlayerProgressColors(
            playedColor: _controlsConfiguration.progressBarPlayedColor,
            handleColor: _controlsConfiguration.progressBarHandleColor,
            bufferedColor: _controlsConfiguration.progressBarBufferedColor,
            backgroundColor: _controlsConfiguration.progressBarBackgroundColor,
          ),
        ),
      ),
    );
  }

  void _onPlayerHide() {
    _betterPlayerController.toggleControlsVisibility(!_hideStuff);
    widget.onControlsVisibilityChanged(!_hideStuff);
  }

  Widget _buildLoadingWidget() {
    if (_controlsConfiguration.loadingWidget != null) {
      return _controlsConfiguration.loadingWidget;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () {
                    skipBack();
                    /*_betterPlayerController.setupDataSource(betterPlayerController.betterPlayerDataSource.copyWith(
                        startAt: Duration(seconds: _betterPlayerController.videoPlayerController.value.position.inSeconds - 10
                        )));*/
                  },
                  onTap: () {
                    _hideStuff
                        ? cancelAndRestartTimer()
                        : setState(() {
                            _hideStuff = true;
                          });
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () {
                    skipForward();
                    /*_betterPlayerController.setupDataSource(betterPlayerController.betterPlayerDataSource.copyWith(
                        startAt: Duration(seconds: _betterPlayerController.videoPlayerController.value.position.inSeconds + 10
                        )));*/
                  },
                  onTap: () {
                    _hideStuff
                        ? cancelAndRestartTimer()
                        : setState(() {
                            _hideStuff = true;
                          });
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              )
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                _controlsConfiguration.loadingColor ?? _controlsConfiguration.controlBarColor),
          ),
        ),
      ],
    );
  }

  double getIconSize(double height) {
    return _betterPlayerController.isFullScreen ? _controlsConfiguration.iconTime * height : height;
  }

  double getPaddingSize(double height) {
    return _betterPlayerController.isFullScreen ? 16.0 + height : 0.0 + height;
  }

  double getPaddingWidth(double height) {
    return _betterPlayerController.isFullScreen ? 12.0 + height : 0.0 + height;
  }
}

List<double> gradientStops = [
  0.0125,
  0.025,
  0.05,
  0.1,
  0.15,
  0.2,
  0.25,
  0.3,
  0.35,
  0.4,
  0.45,
  0.5,
  0.55,
  0.6,
  0.65,
  0.7,
  0.75,
  0.8,
  0.85,
  0.93,
  0.95,
  0.97,
  0.99,
  1.0
];
List<Color> gradientColors = [
  Colors.black.withOpacity(0.93),
  Colors.black.withOpacity(0.91),
  Colors.black.withOpacity(0.9),
  Colors.black.withOpacity(0.87),
  Colors.black.withOpacity(0.85),
  Colors.black.withOpacity(0.8),
  Colors.black.withOpacity(0.75),
  Colors.black.withOpacity(0.7),
  Colors.black.withOpacity(0.65),
  Colors.black.withOpacity(0.6),
  Colors.black.withOpacity(0.55),
  Colors.black.withOpacity(0.5),
  Colors.black.withOpacity(0.45),
  Colors.black.withOpacity(0.4),
  Colors.black.withOpacity(0.35),
  Colors.black.withOpacity(0.3),
  Colors.black.withOpacity(0.25),
  Colors.black.withOpacity(0.2),
  Colors.black.withOpacity(0.15),
  Colors.black.withOpacity(0.1),
  Colors.black.withOpacity(0.05),
  Colors.black.withOpacity(0.025),
  Colors.black.withOpacity(0.0125),
  Colors.black.withOpacity(0.00625),
];

class VideoTrackDuration {
  int start;
  int end;

  VideoTrackDuration({this.start, this.end});
}

class Demo {
  bool isFind;
  int findElementEndPos;
  int findElementStartPos;

  Demo({this.isFind, this.findElementStartPos, this.findElementEndPos});
}
