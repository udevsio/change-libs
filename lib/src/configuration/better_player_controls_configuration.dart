// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:better_player/better_player.dart';

// Project imports:
import 'package:better_player/src/controls/better_player_overflow_menu_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///UI configuration of Better Player. Allows to change colors/icons/behavior
///of controls. Used in BetterPlayerConfiguration.
class BetterPlayerControlsConfiguration {
  ///Color of the control bars
  final Color controlBarColor;

  ///Color of texts
  final Color textColor;

  ///Color of icons
  final Color iconsColor;

  final Color bottomSheet;

  ///Icon of play
  final IconData playIcon;

  ///Icon of pause
  final IconData pauseIcon;

  ///Icon of mute
  final IconData muteIcon;

  ///Icon of unmute
  final IconData unMuteIcon;

  ///Icon of fullscreen mode enable
  final IconData fullscreenEnableIcon;

  ///Icon of fullscreen mode disable
  final IconData fullscreenDisableIcon;

  ///Cupertino only icon, icon of skip
  final Widget skipBackIcon;

  ///Cupertino only icon, icon of forward
  final Widget skipForwardIcon;

  ///Flag used to enable/disable fullscreen
  final bool enableFullscreen;

  ///Flag used to enable/disable mute
  final bool enableMute;

  ///Flag used to enable/disable progress texts
  final bool enableProgressText;

  ///Flag used to enable/disable progress bar
  final bool enableProgressBar;

  ///Flag used to enable/disable progress bar drag
  final bool enableProgressBarDrag;

  ///Flag used to enable/disable play-pause
  final bool enablePlayPause;

  ///Flag used to enable skip forward and skip back
  final bool enableSkips;

  ///Progress bar played color
  final Color progressBarPlayedColor;

  ///Progress bar circle color
  final Color progressBarHandleColor;

  ///Progress bar buffered video color
  final Color progressBarBufferedColor;

  ///Progress bar background color
  final Color progressBarBackgroundColor;

  ///Time to hide controls
  final Duration controlsHideTime;

  ///Parameter used to build custom controls
  final Widget Function(BetterPlayerController controller)
      customControlsBuilder;

  ///Parameter used to change theme of the player
  final BetterPlayerTheme playerTheme;

  ///Flag used to show/hide controls
  final bool showControls;

  ///Flag used to show controls on init
  final bool showControlsOnInitialize;

  ///Control bar height
  final double controlBarHeight;

  final double iconTime;

  ///Live text color;
  final Color liveTextColor;

  ///Flag used to show/hide overflow menu which contains playback, subtitles,
  ///qualities options.
  final bool enableOverflowMenu;

  ///Flag used to show/hide playback speed
  final bool enablePlaybackSpeed;

  ///Flag used to show/hide subtitles
  final bool enableSubtitles;

  ///Flag used to show/hide qualities
  final bool enableQualities;

  ///Flag used to show/hide PiP mode
  final bool enablePip;

  ///Flag used to enable/disable retry feature
  final bool enableRetry;

  ///Flag used to show/hide audio tracks
  final bool enableAudioTracks;

  ///Custom items of overflow menu
  final List<BetterPlayerOverflowMenuItem> overflowMenuCustomItems;

  ///Icon of the overflow menu
  final IconData overflowMenuIcon;

  final Function nextEpisode;

  final Function closeMiniVideo;

  final Function track;

  final Function onVideoEnd;

  final Function prevEpisode;

  final Widget setting;

  final Widget enterFullScreen;

  final Widget exitFullScreen;

  final Widget play;

  final Widget prev;

  final Widget next;

  final Widget pause;

  final Widget brightness;

  final Widget volume;

  ///Icon of the PiP menu
  final IconData pipMenuIcon;

  ///Icon of the playback speed menu item from overflow menu
  final Widget playbackSpeedIcon;

  ///Icon of the subtitles menu item from overflow menu
  final Widget subtitlesIcon;

  ///Icon of the qualities menu item from overflow menu
  final Widget qualitiesIcon;

  ///Icon of the audios menu item from overflow menu
  final Widget audioTracksIcon;

  ///Color of overflow menu icons
  final Color overflowMenuIconsColor;

  ///Time which will be used once user uses forward
  final int forwardSkipTimeInMilliseconds;

  ///Time which will be used once user uses backward
  final int backwardSkipTimeInMilliseconds;

  ///Color of default loading indicator
  final Color loadingColor;

  ///Widget which can be used instead of default progress
  final Widget loadingWidget;

  ///Color of the background, when no frame is displayed.
  final Color backgroundColor;

  const BetterPlayerControlsConfiguration({
    this.controlBarColor = Colors.black87,
    this.textColor = Colors.white,
    this.bottomSheet = Colors.black,
    this.iconsColor = Colors.white,
    this.playIcon = Icons.play_arrow,
    this.pauseIcon = Icons.pause,
    this.brightness,
    this.volume,
    this.muteIcon = Icons.volume_up,
    this.unMuteIcon = Icons.volume_mute,
    this.fullscreenEnableIcon = Icons.fullscreen,
    this.fullscreenDisableIcon = Icons.fullscreen_exit,
    this.skipBackIcon,
    this.skipForwardIcon,
    this.enableFullscreen = true,
    this.enableMute = true,
    this.iconTime = 1.5,
    this.onVideoEnd,
    this.closeMiniVideo,
    this.track,
    this.prev,
    this.next,
    this.nextEpisode,
    this.prevEpisode,
    this.setting,
    this.play,
    this.exitFullScreen,
    this.enterFullScreen,
    this.pause,
    this.enableProgressText = false,
    this.enableProgressBar = true,
    this.enableProgressBarDrag = true,
    this.enablePlayPause = true,
    this.enableSkips = true,
    this.enableAudioTracks = true,
    this.progressBarPlayedColor = Colors.white,
    this.progressBarHandleColor = Colors.white,
    this.progressBarBufferedColor = Colors.white70,
    this.progressBarBackgroundColor = Colors.white60,
    this.controlsHideTime = const Duration(milliseconds: 300),
    this.customControlsBuilder,
    this.playerTheme,
    this.showControls = true,
    this.showControlsOnInitialize = true,
    this.controlBarHeight = 56.0,
    this.liveTextColor = Colors.red,
    this.enableOverflowMenu = true,
    this.enablePlaybackSpeed = true,
    this.enableSubtitles = true,
    this.enableQualities = true,
    this.enablePip = true,
    this.enableRetry = true,
    this.overflowMenuCustomItems = const [],
    this.overflowMenuIcon = Icons.more_vert,
    this.pipMenuIcon = Icons.picture_in_picture,
    this.playbackSpeedIcon,
    this.qualitiesIcon,
    this.subtitlesIcon,
    this.audioTracksIcon,
    this.overflowMenuIconsColor = Colors.black,
    this.forwardSkipTimeInMilliseconds = 10000,
    this.backwardSkipTimeInMilliseconds = 10000,
    this.loadingColor = Colors.white,
    this.loadingWidget,
    this.backgroundColor = Colors.black,
  });

  factory BetterPlayerControlsConfiguration.white() {
    return const BetterPlayerControlsConfiguration(
        controlBarColor: Colors.white,
        textColor: Colors.black,
        iconsColor: Colors.black,
        progressBarPlayedColor: Colors.black,
        progressBarHandleColor: Colors.black,
        progressBarBufferedColor: Colors.black54,
        progressBarBackgroundColor: Colors.white70);
  }

  factory BetterPlayerControlsConfiguration.cupertino() {
    return const BetterPlayerControlsConfiguration(
        fullscreenEnableIcon: CupertinoIcons.fullscreen,
        fullscreenDisableIcon: CupertinoIcons.fullscreen_exit,
        playIcon: CupertinoIcons.play_arrow_solid,
        pauseIcon: CupertinoIcons.pause_solid,
        enableProgressText: true);
  }
}
