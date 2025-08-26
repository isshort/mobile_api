/// App Cache key
enum CacheEnum {
  /// for onboarding
  onboard('bp-onboard'),

  /// register user control
  register('bp-register'),

  /// for accepting agreement
  agreement('bp-agreement'),

  /// theme
  theme('bp-theme'),

  /// system theme
  // systemTheme('bp-system-theme'),

  /// for language cache
  lang('bp-lang'),

  /// for refresh token
  refresh('bp-refresh'),

  /// for access token
  token('bp-token'),

  /// for login status
  login('bp-login'),

  /// for cookie token
  cookie('bp-cookie'),

  /// for biometric info
  biometric('bp-biometric'),

  /// for phone number
  phoneNumber('bp-phone-number-exist'),
  terminalId('bp-terminal-id-exist'),
  versionCode('bp-version-code-exist'),

  // for pin code
  pinCode('bp-pin-code'),
  // offline qrcode
  offlineQrCode('bp-offline-qr-code'),
  ;

  const CacheEnum(this.name);
  final String name;

  /// project init value
  static Iterable<String> get getInitValue => [
        refresh.name,
        token.name,
        theme.name,
      ];

  static Map<CacheEnum, String> saveToken(
    String newAccessToken,
    String newRefreshToken,
  ) =>
      {
        token: newAccessToken,
        refresh: newRefreshToken,
      };

  static Map<CacheEnum, String> getInitValueMap(
    String newAccessToken,
    String newRefreshToken,
    String newPinCode,
  ) =>
      {
        token: newAccessToken,
        refresh: newRefreshToken,
        pinCode: newPinCode,
      };
}
