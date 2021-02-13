///Class used to hold translations for all features within Better Player
class BetterPlayerTranslations {
  final String languageCode;
  final String generalDefaultError;
  final String generalNone;
  final String generalDefault;
  final String generalRetry;
  final String playlistLoadingNextVideo;
  final String controlsLive;
  final String controlsNextVideoIn;
  final String overflowMenuPlaybackSpeed;
  final String overflowMenuSubtitles;
  final String overflowMenuQuality;
  final String overflowMenuAudioTracks;
  final String setting;

  BetterPlayerTranslations({
    this.languageCode = "en",
    this.generalDefaultError = "Video can't be played",
    this.generalNone = "None",
    this.setting = "Settings",
    this.generalDefault = "Default",
    this.generalRetry = "Retry",
    this.playlistLoadingNextVideo = "Loading next video",
    this.controlsNextVideoIn = "Next video in",
    this.controlsLive = "LIVE",
    this.overflowMenuPlaybackSpeed = "Playback speed",
    this.overflowMenuSubtitles = "Subtitles",
    this.overflowMenuQuality = "Quality",
    this.overflowMenuAudioTracks = "Audio",
  });

  factory BetterPlayerTranslations.ru() => BetterPlayerTranslations(
        languageCode: "ru",
        generalDefaultError: "Видео не может\nбыть воспроизведено",
        generalNone: "Никто",
        setting: "Параметр",
        generalDefault: "По умолчонию",
        generalRetry: "Повторить",
        playlistLoadingNextVideo: "Загрузка следующего видео",
        controlsNextVideoIn: "Следующее видео в",
        controlsLive: "LIVE",
        overflowMenuPlaybackSpeed: "Скорость воспроизведения",
        overflowMenuSubtitles: "Субтитры",
        overflowMenuQuality: "Качество",
        overflowMenuAudioTracks: "Аудио",
      );

  factory BetterPlayerTranslations.kr() => BetterPlayerTranslations(
        languageCode: "kr",
        generalDefaultError: "Видеони ижро\nқилиб бо‘лмайди",
        generalNone: "Йўқ",
        setting: "Созламалар",
        generalDefault: "Одатий",
        generalRetry: "Қайта уриниш",
        playlistLoadingNextVideo: "Кейинги видео юкланмоқда",
        controlsNextVideoIn: "Кейинги видео",
        controlsLive: "LIVE",
        overflowMenuPlaybackSpeed: "Видео тезлиги",
        overflowMenuSubtitles: "Субтитрлар",
        overflowMenuQuality: "Формат",
        overflowMenuAudioTracks: "Аудио",
      );

  factory BetterPlayerTranslations.uz() => BetterPlayerTranslations(
        languageCode: "uz",
        generalDefaultError: "Videoni ijro\nqilib bo‘lmaydi",
        generalNone: "Yo'q",
        setting: "Sozlamalar",
        generalDefault: "Odatiy",
        generalRetry: "Qayta urinish",
        playlistLoadingNextVideo: "Keyingi video yuklanmoqda",
        controlsNextVideoIn: "Keyingi video",
        controlsLive: 'LIVE',
        overflowMenuPlaybackSpeed: "Video tezligi",
        overflowMenuSubtitles: "Subtitrlar",
        overflowMenuQuality: "Format",
        overflowMenuAudioTracks: "Audio",
      );
}
