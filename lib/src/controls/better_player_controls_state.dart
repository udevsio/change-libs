// Dart imports:
import 'dart:math';

// Project imports:
import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/hls/better_player_hls_audio_track.dart';
import 'package:better_player/src/hls/better_player_hls_track.dart';
import 'package:better_player/src/video_player/video_player.dart';

// Flutter imports:
import 'package:flutter/material.dart';

///Base class for both material and cupertino controls
abstract class BetterPlayerControlsState<T extends StatefulWidget>
    extends State<T> {
  ///Min. time of buffered video to hide loading timer (in milliseconds)
  static const int _bufferingInterval = 20000;

  BetterPlayerController get betterPlayerController;

  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration;

  VideoPlayerValue get latestValue;

  void cancelAndRestartTimer();

  bool isVideoFinished(VideoPlayerValue videoPlayerValue) {
    return videoPlayerValue?.position != null &&
        videoPlayerValue?.duration != null &&
        videoPlayerValue.position >= videoPlayerValue.duration;
  }

  void skipBack() {
    cancelAndRestartTimer();
    final beginning = const Duration().inMilliseconds;
    final skip = (latestValue.position -
            Duration(
                milliseconds: betterPlayerControlsConfiguration
                    .backwardSkipTimeInMilliseconds))
        .inMilliseconds;
    betterPlayerController.seekTo(Duration(milliseconds: max(skip, beginning)));
  }

  void skipForward() {
    cancelAndRestartTimer();
    final end = latestValue.duration.inMilliseconds;
    final skip = (latestValue.position +
            Duration(
                milliseconds: betterPlayerControlsConfiguration
                    .forwardSkipTimeInMilliseconds))
        .inMilliseconds;
    betterPlayerController.seekTo(Duration(milliseconds: min(skip, end)));
  }

  void onShowMoreClicked(Color color, Color textColor) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: _buildMoreOptionsList(color, textColor),
        );
      },
    );
  }

  Widget _buildMoreOptionsList(Color color, Color textColor) {
    final translations = betterPlayerController.translations;
    return SingleChildScrollView(
      // ignore: avoid_unnecessary_containers
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(16), topLeft: Radius.circular(16)),
          color: color,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 20, bottom: 20),
              child: Text(
                translations.setting,
                textAlign: TextAlign.start,
                style: TextStyle(
                    fontSize: 20,
                    color: textColor,
                    fontWeight: FontWeight.w700),
              ),
            ),
            if (betterPlayerControlsConfiguration.enableQualities)
              _buildMoreOptionsListRow(
                  betterPlayerControlsConfiguration.qualitiesIcon,
                  translations.overflowMenuQuality, () {
                Navigator.of(context).pop();
                _showQualitiesSelectionWidget(
                    translations.overflowMenuQuality, color, textColor);
              }, textColor),
            Divider(
                height: 1, thickness: 0.5, color: textColor.withOpacity(.5)),
            if (betterPlayerControlsConfiguration.enablePlaybackSpeed)
              _buildMoreOptionsListRow(
                  betterPlayerControlsConfiguration.playbackSpeedIcon,
                  translations.overflowMenuPlaybackSpeed, () {
                Navigator.of(context).pop();
                _showSpeedChooserWidget(
                    translations.overflowMenuPlaybackSpeed, color, textColor);
              }, textColor),
            // Divider(height: 1, thickness: 0.5, color: textColor.withOpacity(.5)),
            if (betterPlayerControlsConfiguration.enableSubtitles)
              _buildMoreOptionsListRow(
                  betterPlayerControlsConfiguration.subtitlesIcon,
                  translations.overflowMenuSubtitles, () {
                Navigator.of(context).pop();
                _showSubtitlesSelectionWidget();
              }, textColor),
            // Divider(height: 1, thickness: 0.5, color: textColor.withOpacity(.5)),
            if (betterPlayerControlsConfiguration.enableAudioTracks)
              _buildMoreOptionsListRow(
                  betterPlayerControlsConfiguration.audioTracksIcon,
                  translations.overflowMenuAudioTracks, () {
                Navigator.of(context).pop();
                _showAudioTracksSelectionWidget();
              }, textColor),
            // Divider(height: 1, thickness: 0.5, color: textColor.withOpacity(.5)),
            if (betterPlayerControlsConfiguration
                .overflowMenuCustomItems?.isNotEmpty)
              ...betterPlayerControlsConfiguration.overflowMenuCustomItems.map(
                (customItem) => _buildMoreOptionsListRow(
                    customItem.icon, customItem.title, () {
                  Navigator.of(context).pop();
                  customItem.onClicked?.call();
                }, textColor),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionsListRow(
      Widget icon, String name, void Function() onTap, Color textColor) {
    assert(icon != null, "Icon can't be null");
    assert(name != null, "Name can't be null");
    assert(onTap != null, "OnTap can't be null");
    return BetterPlayerMaterialClickableWidget(
      onTap: onTap,
      radius: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(color: textColor, fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedChooserWidget(String text, Color color, Color textColor) {
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return SafeArea(
            top: false,
            child: Container(
              height: 248,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    topLeft: Radius.circular(16)),
                color: color,
              ),
              child: Stack(children: [
                Positioned(
                  top: 24,
                  left: 16,
                  child: Text(
                    text,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: textColor),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 64),
                  child: ListView.separated(
                      separatorBuilder: (context, index) {
                        return Divider(
                            height: 1,
                            thickness: 0.5,
                            color: textColor.withOpacity(.5));
                      },
                      itemCount: speed.length,
                      physics: BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return _buildSpeedRow(speed[index], textColor);
                      }),
                )
              ]),
            ),
          );
        });
  }

  List<double> speed = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  Widget _buildSpeedRow(double value, Color textColor) {
    assert(value != null, "Value can't be null");
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController.setSpeed(value);
      },
      radius: 0,
      child: ListTile(
        title: Text(
          "$value x",
          style: TextStyle(color: textColor, fontWeight: FontWeight.normal),
        ),
        trailing: Visibility(
            visible: value ==
                betterPlayerController.videoPlayerController.value.speed,
            child: Icon(
              Icons.done,
              color: textColor,
            )),
      ),
    );
  }

  ///Latest value can be null
  bool isLoading(VideoPlayerValue latestValue) {
    if (latestValue != null) {
      if (!latestValue.isPlaying && latestValue.duration == null) {
        return true;
      }

      final Duration position = latestValue.position;

      Duration bufferedEndPosition;
      if (latestValue.buffered?.isNotEmpty == true) {
        bufferedEndPosition = latestValue.buffered.last.end;
      }

      if (position != null && bufferedEndPosition != null) {
        final difference = bufferedEndPosition - position;

        if (latestValue.isPlaying &&
            latestValue.isBuffering &&
            difference.inMilliseconds < _bufferingInterval) {
          return true;
        }
      }
    }
    return false;
  }

  void _showSubtitlesSelectionWidget() {
    final subtitles =
        List.of(betterPlayerController.betterPlayerSubtitlesSourceList);
    final noneSubtitlesElementExists = subtitles?.firstWhere(
            (source) => source.type == BetterPlayerSubtitlesSourceType.none,
            orElse: () => null) !=
        null;
    if (!noneSubtitlesElementExists) {
      subtitles?.add(BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.none));
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: subtitles
                  .map((source) => _buildSubtitlesSourceRow(source))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitlesSourceRow(BetterPlayerSubtitlesSource subtitlesSource) {
    assert(subtitlesSource != null, "SubtitleSource can't be null");

    final selectedSourceType =
        betterPlayerController.betterPlayerSubtitlesSource;
    final bool isSelected = (subtitlesSource == selectedSourceType) ||
        (subtitlesSource.type == BetterPlayerSubtitlesSourceType.none &&
            subtitlesSource?.type == selectedSourceType.type);

    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController.setupSubtitleSource(subtitlesSource);
      },
      radius: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              subtitlesSource.type == BetterPlayerSubtitlesSourceType.none
                  ? betterPlayerController.translations.generalNone
                  : subtitlesSource.name ??
                      betterPlayerController.translations.generalDefault,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///Build both track and resolution selection
  ///Track selection is used for HLS videos
  ///Resolution selection is used for normal videos
  void _showQualitiesSelectionWidget(
      String text, Color color, Color textColor) {
    final List<String> trackNames =
        betterPlayerController.betterPlayerDataSource.hlsTrackNames ?? [];
    final List<BetterPlayerHlsTrack> tracks =
        betterPlayerController.betterPlayerTracks;
    final List<Widget> children = [];
    for (var index = 0; index < tracks.length; index++) {
      final preferredName =
          trackNames.length > index ? trackNames[index] : null;
      children.add(_buildTrackRow(tracks[index], preferredName, textColor));
    }
    final resolutions =
        betterPlayerController.betterPlayerDataSource.resolutions;
    resolutions?.forEach((key, value) {
      children.add(_buildResolutionSelectionRow(key, value, textColor));
    });

    if (children.isEmpty) {
      children.add(_buildTrackRow(BetterPlayerHlsTrack(0, 0, 0),
          betterPlayerController.translations.generalDefault, textColor));
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            height: 248,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16), topLeft: Radius.circular(16)),
              color: color,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  left: 16,
                  child: Text(
                    text,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: textColor),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 64),
                  child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return Divider(
                          height: 1,
                          thickness: 0.5,
                          color: textColor.withOpacity(.5));
                    },
                    physics: BouncingScrollPhysics(),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      return children[index];
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackRow(
      BetterPlayerHlsTrack track, String preferredName, Color textColor) {
    assert(track != null, "Track can't be null");
    final String trackName = preferredName ??
        "${track.width}x${track.height} ${BetterPlayerUtils.formatBitrate(track.bitrate)}";

    final selectedTrack = betterPlayerController.betterPlayerTrack;
    final bool isSelected = selectedTrack != null && selectedTrack == track;

    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController.setTrack(track);
      },
      radius: 0,
      child: ListTile(
        title: Text(
          trackName,
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: textColor,
          ),
        ),
        trailing: Visibility(
            visible: isSelected,
            child: Icon(
              Icons.done,
              color: Colors.white,
            )),
      ),
    );
  }

  Widget _buildResolutionSelectionRow(
      String name, String url, Color textColor) {
    final bool isSelected =
        name == betterPlayerController.betterPlayerDataSource.quality;
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController.setResolution(url, name);
      },
      radius: 0,
      child: ListTile(
        title: Text(
          name,
          style: TextStyle(
              fontWeight: FontWeight.normal, color: textColor, fontSize: 17),
        ),
        trailing: Visibility(
            visible: isSelected,
            child: Icon(
              Icons.done,
              color: textColor,
            )),
      ),
    );
  }

  void _showAudioTracksSelectionWidget() {
    final List<BetterPlayerHlsAudioTrack> tracks =
        betterPlayerController.betterPlayerAudioTracks;
    final List<Widget> children = [];
    final BetterPlayerHlsAudioTrack selectedAudioTrack =
        betterPlayerController.betterPlayerAudioTrack;
    if (tracks != null) {
      for (var index = 0; index < tracks.length; index++) {
        children.add(_buildAudioTrackRow(tracks[index], selectedAudioTrack));
      }
    }

    if (children.isEmpty) {
      children.add(
        _buildAudioTrackRow(
            BetterPlayerHlsAudioTrack(
              label: betterPlayerController.translations.generalDefault,
            ),
            selectedAudioTrack),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: children,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioTrackRow(BetterPlayerHlsAudioTrack audioTrack,
      BetterPlayerHlsAudioTrack selectedAudioTrack) {
    assert(audioTrack != null, "Track can't be null");

    final bool isSelected =
        selectedAudioTrack != null && selectedAudioTrack == audioTrack;
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        betterPlayerController.setAudioTrack(audioTrack);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              audioTrack.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
