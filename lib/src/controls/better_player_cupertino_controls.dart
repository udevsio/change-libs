import 'dart:async';
import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/core/boxed_vertical_seekbar.dart';
import 'package:better_player/src/core/utils.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volume_control/volume_control.dart';
import 'better_player_clickable_widget.dart';
import 'better_player_cupertino_progress_bar.dart';
import 'package:screen/screen.dart';

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

class _BetterPlayerCupertinoControlsState extends BetterPlayerControlsState<BetterPlayerCupertinoControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = false;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _displayTapped = false;
  bool _wasLoading = false;
  VideoPlayerController _controller;
  BetterPlayerController _betterPlayerController;
  StreamSubscription _controlsVisibilityStreamSubscription;
  bool _isDraging = false;
  Offset _dragStart;
  Offset _dragcurrent;
  double _dragDelta;
  int _dragDrection; //0:x,1:y
  int _controlType; //1:volume,0:brightness
  double _volume = 1;
  double _notifierVolume = 1;
  double _notifierBrightness = 1;
  double _brightness = 1;
  var lastTapDown = 0;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // initConnectivity();
    // _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (_betterPlayerController.isVideoInitialized()) {
      final snackBar = SnackBar(
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(6), topLeft: Radius.circular(6)),
        ),
        padding: EdgeInsets.zero,
        content: SizedBox(
          height: 24,
          child: Center(
            child: Text(
                result == ConnectivityResult.none
                    ? _betterPlayerController.translations.noInternet
                    : _betterPlayerController.translations.hasInternet,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500)),
          ),
        ),
        backgroundColor: result == ConnectivityResult.none
            ? Color(0xFFd50000)
            : Colors.green,
      );
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }
  Timer _timer;
  Timer _getPlayerPostionTimer;

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
            Positioned(
              bottom: getPaddingSize(_controlsConfiguration.controlBarHeight),
              left: 0,
              right: 0,
              top: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: () {
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

    return Stack(
      children: [
        MouseRegion(
          onHover: (_) {
            cancelAndRestartTimer();
          },
          child: GestureDetector(
            onHorizontalDragStart: (_) {},
            onHorizontalDragEnd: (_) {},
            onVerticalDragStart: (_) async {
              if (_betterPlayerController.isFullScreen) {
                _isDraging = true;
                _dragStart = _.globalPosition;
                _dragDrection = 1;
                _notifierBrightness = await Screen.brightness;
                _notifierVolume = await VolumeControl.volume;
                RenderBox _rb = context.findRenderObject();
                final topLeftPosition = _rb.localToGlobal(Offset.zero);
                if (topLeftPosition.dx + _dragStart.dx < _rb.size.width / 2) {
                  _controlType = 0;
                } else {
                  _controlType = 1;
                }
              }
            },
            onVerticalDragEnd: (_) {
              if (_betterPlayerController.isFullScreen) {
                _isDraging = false;
                updateUI();
                if (_controlType == 1) {
                  _notifierVolume = _volume;
                  _betterPlayerController.setVolume(_volume);
                } else {
                  _notifierBrightness = _brightness;
                }
              }
            },
            onTapDown: (TapDownDetails details){
              var now = DateTime.now().millisecondsSinceEpoch;
              if (now - lastTapDown < 300) {
                  if(details.globalPosition.dx > MediaQuery.of(context).size.width / 2){
                    skipForward();
                  }
                  else {
                    skipBack();
                  }
              }
              else {
                _hideStuff
                    ? cancelAndRestartTimer()
                    : setState(() {
                  _hideStuff = true;
                });
              }
              lastTapDown = now;
            },
            onHorizontalDragUpdate: (_) {},
            onVerticalDragUpdate: (_) {
              if (_betterPlayerController.isFullScreen) {
                _dragcurrent = _.globalPosition;
                _dragDelta = _dragStart.dy - _dragcurrent.dy;
                updateUI();
              }
            },
            child: AbsorbPointer(
              absorbing: _hideStuff,
              child: Column(
                children: [
                  _wasLoading
                      ? Expanded(
                          child: Container(
                            margin: EdgeInsets.only(top: getPaddingSize(_controlsConfiguration.controlBarHeight)),
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
        ),
        _buildCenter(context),
      ],
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _timer?.cancel();
    _getPlayerPostionTimer?.cancel();
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
      return errorBuilder(context, _betterPlayerController.videoPlayerController.value.errorDescription);
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
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            stops: gradientStops,
            end: Alignment.topCenter,
            begin: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
                      if (_betterPlayerController.isLiveStream()) _buildLiveWidget() else _controlsConfiguration.enableProgressText ? _buildPosition() : const SizedBox(),
                      _buildSettingButton(),
                      SizedBox(
                        width: 16,
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
          child: _betterPlayerController.isFullScreen ? _controlsConfiguration.exitFullScreen : _controlsConfiguration.enterFullScreen),
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

  Widget _buildCenterWhenDraging(BuildContext context) {
    if (_betterPlayerController.videoPlayerController.value.duration != null) {
      if (_dragDrection == 0 &&
          _betterPlayerController.videoPlayerController.value.position != null &&
          _betterPlayerController.videoPlayerController.value.duration.inMilliseconds > 0) {
        RenderBox _rb = context.findRenderObject();
        var _size = _rb.size;
        int _ds = _dragDelta * _betterPlayerController.videoPlayerController.value.duration.inSeconds ~/ _size.width;
        Duration title = Duration(seconds: _betterPlayerController.videoPlayerController.value.position.inSeconds + _ds);
        Duration subTitle = Duration(seconds: _ds);
        var _dss = '';
        var _timer = "";
        _timer = title.inHours > 0
            ? "${title.inHours}:${(title.inMinutes % 60).toString().padLeft(2, "0")}:${(title.inSeconds % 60).toString().padLeft(2, '0')}"
            : "${title.inMinutes}:${(title.inSeconds % 60).toString().padLeft(2, '0')}";
        _dss = subTitle.inHours > 0
            ? "${subTitle.inHours}:${(subTitle.inMinutes % 60).toString().padLeft(2, "0")}:${(subTitle.inSeconds % 60).toString().padLeft(2, '0')}"
            : "${subTitle.inMinutes}:${(subTitle.inSeconds % 60).toString().padLeft(2, '0')}";
        if (_timer.startsWith('-')) {
          _timer = "00:00";
          subTitle = _betterPlayerController.videoPlayerController.value.position;
          _dss = subTitle.inHours > 0
              ? "-${subTitle.inHours}:${(subTitle.inMinutes % 60).toString().padLeft(2, "0")}:${(subTitle.inSeconds % 60).toString().padLeft(2, '0')}"
              : "-${subTitle.inMinutes}:${(subTitle.inSeconds % 60).toString().padLeft(2, '0')}";
        }
        return Center(
            child: Container(
          height: 48,
          width: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _timer,
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                _ds > 0 ? '+$_dss' : _dss,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ));
      } else {
        if (_dragDrection == 1 && _dragDelta != null) {
          // final screen = await Screen.brightness;
          String _p; //ui上显示的百分比
          IconData _icon; //icon
          if (_controlType == 0) {
            _brightness = _dragDelta / (MediaQuery.of(context).size.height - 200) + _notifierBrightness;
            if (_brightness < 0.01) {
              _brightness = 0.01;
            } else if (_brightness > 1.0) {
              _brightness = 1.0;
            }
            _p = ((_brightness * 100)).toStringAsFixed(0) + '%';
            _icon = _brightness < 0.5 ? Icons.brightness_low : (_brightness > 0.8 ? Icons.brightness_high : Icons.brightness_medium);
            Screen.setBrightness(_brightness);
          } else {
            _volume = _dragDelta / (MediaQuery.of(context).size.height - 200) + _notifierVolume;
            if (_volume < 0.01) {
              _volume = 0.0;
            } else if (_volume > 1.0) {
              _volume = 1.0;
            }
            _p = ((_volume * 100)).toStringAsFixed(0) + '%';
            _icon = _volume == 0 ? Icons.volume_off : (_volume > 0.5 ? Icons.volume_up : Icons.volume_down);
            VolumeControl.setVolume(_volume);
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Container(
                  height: 100,
                  width: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        _icon,
                        size: 32.0,
                        color: Colors.white,
                      ),
                      Text(
                        _p,
                        style: TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                right: 40,
                left: 40,
                child: Row(
                  children: [
                    Visibility(
                      visible: _controlType == 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _betterPlayerController.betterPlayerConfiguration.controlsConfiguration.brightness,
                          SizedBox(
                            height: 8,
                          ),
                          BoxedVerticalSeekBar(
                            height: MediaQuery.of(context).size.height - 200,
                            width: 6,
                            onValueChanged: (newValue) => _notifierBrightness = newValue,
                            value: _brightness * 20,
                            min: 0,
                            max: 20,
                            movingBox:
                                DecoratedBox(decoration: BoxDecoration(color: _betterPlayerController.betterPlayerConfiguration.controlsConfiguration.progressBarPlayedColor)),
                            fixedBox: DecoratedBox(
                              decoration: BoxDecoration(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Visibility(
                      visible: _controlType == 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _betterPlayerController.betterPlayerConfiguration.controlsConfiguration.volume,
                          SizedBox(
                            height: 8,
                          ),
                          BoxedVerticalSeekBar(
                            height: MediaQuery.of(context).size.height - 200,
                            width: 6,
                            onValueChanged: (newValue) => _notifierVolume = newValue,
                            value: _volume * 20,
                            min: 0,
                            max: 20,
                            movingBox:
                                DecoratedBox(decoration: BoxDecoration(color: _betterPlayerController.betterPlayerConfiguration.controlsConfiguration.progressBarPlayedColor)),
                            fixedBox: DecoratedBox(
                              decoration: BoxDecoration(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          return Container();
        }
      }
    }
    return Container();
  }

  Widget _buildCenter(BuildContext context) {
    if (_isDraging && _betterPlayerController.isFullScreen) {
      return _buildCenterWhenDraging(context);
    }
    return Container();
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
              width: 20,
            ),
            _buildPrevButton(),
            SizedBox(
              width: 20,
            ),
            _buildCenterButton(4),
            SizedBox(
              width: 20,
            ),
            _buildNextButton(),
            SizedBox(
              width: 20,
            ),
            _buildForwardButton(),
          ],
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
        skipBack();
        // _betterPlayerController.play();
      },
      // onDoubleTap: skipBack,
    );
  }

  Widget _buildPrevButton() {
    return Visibility(
      visible: _betterPlayerController.betterPlayerDataSource.isSerial,
      child: BetterPlayerMaterialClickableWidget(
        child: Container(width: getIconSize(32), height: getIconSize(32), margin: EdgeInsets.all(4), child: _controlsConfiguration.prev ?? SizedBox()),
        onTap: _controlsConfiguration.prevEpisode,
      ),
    );
  }

  Widget _buildNextButton() {
    return Visibility(
      visible: _betterPlayerController.betterPlayerDataSource.isSerial,
      child: BetterPlayerMaterialClickableWidget(
        child: Container(width: getIconSize(32), height: getIconSize(32), margin: EdgeInsets.all(4), child: _controlsConfiguration.next ?? SizedBox()),
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
        skipForward();
        // _betterPlayerController.play();
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
      child: SizedBox(width: getIconSize(24), height: getIconSize(24), child: _controlsConfiguration.setting),
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
          VolumeControl.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          _betterPlayerController.setVolume(0.0);
        }
      },
      child: Icon(
        (_latestValue != null && _latestValue.volume > 0) ? _controlsConfiguration.muteIcon : _controlsConfiguration.unMuteIcon,
        color: _controlsConfiguration.iconsColor,
        size: getIconSize(24),
      ),
    );
  }

  Widget _buildPlayPause(VideoPlayerController controller, double size, double margin) {
    return BetterPlayerMaterialClickableWidget(
      onTap: _onPlayPause,
      child: Container(height: size, width: size, margin: EdgeInsets.all(margin), child: controller.value.isPlaying ? _controlsConfiguration.pause : _controlsConfiguration.play),
    );
  }

  Widget _buildPosition() {
    final position = _latestValue != null && _latestValue.position != null ? _latestValue.position : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null ? _latestValue.duration : Duration.zero;
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

    _updateState();

    if ((_controller.value != null && _controller.value.isPlaying) || _betterPlayerController.betterPlayerDataSource.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }

    _controlsVisibilityStreamSubscription = _betterPlayerController.controlsVisibilityStream.listen((state) {
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

    try {
      if (!_betterPlayerController.isOffline && position != null && position.inSeconds != 0 && position.inSeconds % 30 == 0) {
        _controlsConfiguration?.track(position?.inSeconds ?? 0);
      }
    } catch (e) {}

    return Text(
      "${textPosition} / ",
      style: TextStyle(fontSize: 14, color: Colors.white),
    );
  }

  Widget _buildTotalPosition() {
    String textDuration = _controller.value.duration != null ? formatDuration(_controller.value.duration) : '00:00';
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

  void _updateState() {
    if (mounted) {
      if (!_hideStuff || isVideoFinished(_controller.value) || _wasLoading || isLoading(_controller.value)) {
        setState(() {
          _latestValue = _controller.value;
          if (isVideoFinished(_latestValue)) {
            _hideStuff = false;
          }
        });
      }
    }
  }

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
          colors: BetterPlayerProgressColors(
              playedColor: _controlsConfiguration.progressBarPlayedColor,
              handleColor: _controlsConfiguration.progressBarHandleColor,
              bufferedColor: _controlsConfiguration.progressBarBufferedColor,
              backgroundColor: _controlsConfiguration.progressBarBackgroundColor),
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
            valueColor: AlwaysStoppedAnimation<Color>(_controlsConfiguration.progressBarPlayedColor),
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

  void updateUI() {
    if (mounted) {
      setState(() {});
    }
  }
}

List<double> gradientStops = [0.0125, 0.025, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.93, 0.95, 0.97, 0.99, 1.0];
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
