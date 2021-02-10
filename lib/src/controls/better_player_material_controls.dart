// Dart imports:
import 'dart:async';

// Project imports:
import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/core/utils.dart';
import 'package:better_player/src/video_player/video_player.dart';

// Flutter imports:
import 'package:flutter/material.dart';
import 'better_player_clickable_widget.dart';

class BetterPlayerMaterialControls extends StatefulWidget {
  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;

  ///Controls config
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerMaterialControls({
    Key key,
    @required this.onControlsVisibilityChanged,
    @required this.controlsConfiguration,
  })  : assert(onControlsVisibilityChanged != null),
        assert(controlsConfiguration != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BetterPlayerMaterialControlsState();
  }
}

class _BetterPlayerMaterialControlsState extends BetterPlayerControlsState<BetterPlayerMaterialControls> {
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
      return Container(
        color: Colors.black26,
        margin: EdgeInsets.only(top: 48),
        child: _buildErrorWidget(),
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
        onDoubleTap: () {
          cancelAndRestartTimer();
          _onPlayPause();
        },
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: [
              if (_wasLoading) Expanded(child: Container(margin: EdgeInsets.only(top: 48), child: Center(child: _buildLoadingWidget()))) else _buildHitArea(),
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
      return errorBuilder(context, _betterPlayerController.videoPlayerController.value.errorDescription);
    } else {
      final textStyle = TextStyle(color: _controlsConfiguration.textColor);
      return Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: _controlsConfiguration.iconsColor,
                size: 42,
              ),
              Text(
                _betterPlayerController.translations.generalDefaultError,
                style: textStyle,
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
                )
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBottomBar() {
    if (!betterPlayerController.controlsEnabled) {
      return const SizedBox();
    }
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: Container(
        height: _controlsConfiguration.controlBarHeight,
        // color: _controlsConfiguration.controlBarColor,
        child: Column(
          children: [
            SizedBox(
              height: 24,
              child: Row(
                children: [
                  SizedBox(
                    width: 8,
                  ),
                  _buildPlayPause(_controller, 24),
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
      child: _betterPlayerController.isFullScreen ? _controlsConfiguration.exitFullScreen : _controlsConfiguration.enterFullScreen,
    );
  }

  Widget _buildHitArea() {
    if (!betterPlayerController.controlsEnabled) {
      return const SizedBox();
    }
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(top: 48),
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity: _hideStuff ? 0.0 : 1.0,
            duration: _controlsConfiguration.controlsHideTime,
            child: Stack(
              children: [
                _buildMiddleRow(),
                _buildNextVideoWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiddleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSkipButton(),
          _buildPrevButton(),
          _buildCenterButton(),
          _buildNextButton(),
          _buildForwardButton(),
        ],
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
      child: Icon(
        _controlsConfiguration.skipBackIcon,
        size: 32,
        color: _controlsConfiguration.iconsColor,
      ),
      onTap: skipBack,
    );
  }

  Widget _buildPrevButton() {
    return Visibility(
      visible: _betterPlayerController.betterPlayerDataSource.isSerial,
      child: BetterPlayerMaterialClickableWidget(
        child: _controlsConfiguration.prev ?? SizedBox(),
        onTap: _controlsConfiguration.nextEpisode,
      ),
    );
  }

  Widget _buildNextButton() {
    return Visibility(
      visible: _betterPlayerController.betterPlayerDataSource.isSerial,
      child: BetterPlayerMaterialClickableWidget(
        child: _controlsConfiguration.next ?? SizedBox(),
        onTap: _controlsConfiguration.prevEpisode,
      ),
    );
  }

  Widget _buildForwardButton() {
    return BetterPlayerMaterialClickableWidget(
      child: Icon(
        _controlsConfiguration.skipForwardIcon,
        size: 32,
        color: _controlsConfiguration.iconsColor,
      ),
      onTap: skipForward,
    );
  }

  Widget _buildCenterButton() {
    final bool isFinished = isVideoFinished(_latestValue);
    if (!isFinished) {
      return _buildPlayPause(_controller, 48);
    }
    return BetterPlayerMaterialClickableWidget(
      child: Icon(
        Icons.replay,
        size: 48,
        color: _controlsConfiguration.iconsColor,
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
      child: _controlsConfiguration.setting,
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
        (_latestValue != null && _latestValue.volume > 0) ? _controlsConfiguration.muteIcon : _controlsConfiguration.unMuteIcon,
        color: _controlsConfiguration.iconsColor,
      ),
    );
  }

  Widget _buildPlayPause(VideoPlayerController controller, double size) {
    return BetterPlayerMaterialClickableWidget(
      onTap: _onPlayPause,
      child: SizedBox(height: size, width: size, child: controller.value.isPlaying ? _controlsConfiguration.pause : _controlsConfiguration.play),
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

    if ((_controller.value != null && _controller.value.isPlaying) || _betterPlayerController.betterPlayerConfiguration.autoPlay) {
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

    if (position != null && position.inSeconds != 0 && position.inSeconds % 30 == 0) {
      _controlsConfiguration.track(position.inSeconds);
    }

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
        padding: const EdgeInsets.only(right: 12, left: 12),
        child: BetterPlayerMaterialVideoProgressBar(
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

    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(_controlsConfiguration.loadingColor ?? _controlsConfiguration.controlBarColor),
    );
  }
}
