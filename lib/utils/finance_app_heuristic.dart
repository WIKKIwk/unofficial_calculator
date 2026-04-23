/// Curated Android application IDs (`packageName`) for Uzbekistan retail
/// finance apps you asked to recognise. Values were taken from public
/// Google Play listings (`…/store/apps/details?id=…`) as of 2026-04.
///
/// You can extend this map when you have another Play URL: copy the `id=`
/// query parameter exactly (case-sensitive in the store; we normalise to
/// lowercase for matching).
///
/// References (package → Play):
/// - **Uzum Bank**: `uz.kapitalbank.android`
/// - **Payme**: `uz.dida.p2me` (also listed: `uz.dida.payme` for related Payme)
/// - **Click SuperApp**: `air.com.ssdsoftwaresolutions.clickuz`
/// - **Anorbank**: `uz.anormobile.retail`
/// - **Ipak Yo'li Mobile**: `com.ipakyulibank.mobile`
const Map<String, String> curatedUzbekistanFinancePackages = {
  'uz.kapitalbank.android': 'Uzum Bank',
  'uz.dida.p2me': 'Payme',
  'uz.dida.payme': 'Payme (alternate listing)',
  'air.com.ssdsoftwaresolutions.clickuz': 'Click SuperApp',
  'uz.anormobile.retail': 'Anorbank',
  'com.ipakyulibank.mobile': "Ipak Yo'li Mobile",
};

/// Common SMS/Messages app package ids across major Android vendors.
const Map<String, String> curatedSmsPackages = {
  'com.google.android.apps.messaging': 'Google Messages',
  'com.android.mms': 'Android Messages (AOSP/OEM)',
  'com.samsung.android.messaging': 'Samsung Messages',
  'com.miui.smsextra': 'Xiaomi Messaging service',
  'com.mi.android.globalminusscreen': 'Xiaomi system messaging helper',
};

String _normPackage(String packageName) => packageName.toLowerCase().trim();

/// True when [packageName] matches a curated Play `applicationId`.
bool isCuratedFinancePackage(String packageName) {
  return curatedUzbekistanFinancePackages.containsKey(
    _normPackage(packageName),
  );
}

bool isCuratedSmsPackage(String packageName) {
  return curatedSmsPackages.containsKey(_normPackage(packageName));
}

/// Heuristic matcher: curated packages first, then keyword fragments on
/// [appName] / [packageName] for other banks.
bool matchesFinanceHeuristic(String appName, String packageName) {
  if (isCuratedFinancePackage(packageName)) {
    return true;
  }
  final name = appName.toLowerCase();
  final pkg = packageName.toLowerCase();

  for (final hint in _financeHints) {
    if (name.contains(hint) || pkg.contains(hint)) {
      return true;
    }
  }
  return false;
}

/// Matcher for the app-selection screen:
/// includes both finance apps and SMS apps.
bool matchesTrackedAppHeuristic(String appName, String packageName) {
  if (matchesFinanceHeuristic(appName, packageName)) {
    return true;
  }
  if (isCuratedSmsPackage(packageName)) {
    return true;
  }

  final name = appName.toLowerCase();
  final pkg = packageName.toLowerCase();
  for (final hint in _smsHints) {
    if (name.contains(hint) || pkg.contains(hint)) {
      return true;
    }
  }
  return false;
}

/// Lowercase fragments matched against app name or package id (fallback).
const _financeHints = <String>[
  // English
  'bank', 'banking', 'finance', 'wallet', 'payment', 'credit', 'invest',
  'loan', 'insurance', 'swift', 'iban', 'visa', 'mastercard',
  // Uzbek / regional names (Latin)
  'kapital', 'milly', 'xalq', 'ipoteka', 'asaka', 'agro', 'hamkor',
  'sqb', 'nbu', 'aloqa', 'turon', 'anor', 'ziraat', 'saderat',
  'payme', 'click', 'humo', 'uzcard', 'apelsin', 'paynet',
  'tbc', 'infin', 'leobank', 'octo', 'unired',
  // Russian (common in store names)
  'банк', 'финанс', 'кредит',
];

const _smsHints = <String>[
  'sms',
  'message',
  'messages',
  'messaging',
  'xabar',
  'xabarlar',
  'сообщение',
  'сообщения',
];
