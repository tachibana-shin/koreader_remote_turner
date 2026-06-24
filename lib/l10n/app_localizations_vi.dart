// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'KOReader Remote';

  @override
  String get appDescription => 'Điều khiển từ xa cho trình đọc sách KOReader';

  @override
  String get tabAbout => 'Giới thiệu';

  @override
  String get tabHome => 'Trang chủ';

  @override
  String get tabLogs => 'Nhật ký';

  @override
  String get tabSettings => 'Cài đặt';

  @override
  String get aboutTitle => 'KOReader Remote';

  @override
  String get aboutAuthor => 'Tác giả';

  @override
  String get aboutRepo => 'Kho mã nguồn';

  @override
  String get aboutLicense => 'Giấy phép';

  @override
  String get aboutDonate => 'Ủng hộ';

  @override
  String get connectionStatusOff => 'Máy chủ đã tắt';

  @override
  String get connectionStatusWaiting => 'Đang chờ kết nối...';

  @override
  String connectionStatusConnected(Object deviceName) {
    return 'Đã kết nối: $deviceName';
  }

  @override
  String get serverStart => 'Bật máy chủ';

  @override
  String get serverStop => 'Tắt máy chủ';

  @override
  String serverInfo(Object address, Object port) {
    return 'Máy chủ: $address:$port';
  }

  @override
  String totalEvents(Object count) {
    return 'Tổng số sự kiện: $count';
  }

  @override
  String avgSpeed(Object speed) {
    return 'Tốc độ TB: $speed/phút';
  }

  @override
  String get eventForward => 'Tiến';

  @override
  String get eventBackward => 'Lùi';

  @override
  String get eventSleep => 'Ngủ';

  @override
  String get xiaomiNote =>
      'Lưu ý: Thiết bị Xiaomi HyperOS/MiUI cần tắt \"Tạm dừng hoạt động ứng dụng nếu không sử dụng\" và đổi cài đặt pin thành \"Không hạn chế\"';

  @override
  String get logTitle => 'Nhật ký sự kiện';

  @override
  String get logEmpty => 'Chưa có sự kiện';

  @override
  String get logTime => 'Thời gian';

  @override
  String get logEvent => 'Sự kiện';

  @override
  String get logStatus => 'Trạng thái';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsTheme => 'Chủ đề';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsThemeSystem => 'Hệ thống';

  @override
  String get settingsPort => 'Cổng máy chủ';

  @override
  String get settingsTimeout => 'Thời gian tự tắt (phút)';

  @override
  String get settingsTimeoutNone => 'Không bao giờ';

  @override
  String get settingsKeyMapping => 'Gán phím';

  @override
  String get settingsKeyForward => 'Phím tiến';

  @override
  String get settingsKeyBackward => 'Phím lùi';

  @override
  String get settingsKeySleep => 'Phím ngủ';

  @override
  String get settingsAutoStart => 'Tự bật server khi mở app';

  @override
  String get settingsOnlyWhileOpen => 'Chỉ chặn phím khi app đang mở';

  @override
  String get settingsPassword => 'Mật khẩu kết nối';

  @override
  String get settingsPasswordNone => 'Không có mật khẩu';

  @override
  String get settingsPasswordSet => 'Đặt mật khẩu';

  @override
  String get settingsSave => 'Lưu';

  @override
  String get volumeUp => 'Tăng âm lượng';

  @override
  String get volumeDown => 'Giảm âm lượng';

  @override
  String get enter => 'Enter';

  @override
  String get none => 'Không';
}
