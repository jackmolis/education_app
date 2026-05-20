String getLocalizedText({
  required String langCode,
  required String en,
  required String fr,
  required String ar,
}) {
  switch (langCode) {
    case 'ar':
      return ar.isNotEmpty ? ar : (en.isNotEmpty ? en : (fr.isNotEmpty ? fr : ''));
    case 'fr':
      return fr.isNotEmpty ? fr : (en.isNotEmpty ? en : (ar.isNotEmpty ? ar : ''));
    default:
      return en.isNotEmpty ? en : (fr.isNotEmpty ? fr : (ar.isNotEmpty ? ar : ''));
  }
}
