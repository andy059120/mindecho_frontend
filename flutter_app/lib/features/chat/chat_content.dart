import 'dart:convert';

import 'package:flutter/services.dart';

class ChatContent {
  const ChatContent(this.welcomes, this.corpus);
  final Map<String, dynamic> welcomes;
  final Map<String, dynamic> corpus;
  static Future<ChatContent> load() async => ChatContent(
    jsonDecode(await rootBundle.loadString('assets/data/chat_welcomes.json'))
        as Map<String, dynamic>,
    jsonDecode(await rootBundle.loadString('assets/data/crisis_lexicon.json'))
        as Map<String, dynamic>,
  );

  String _normalize(String text) => text.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]', unicode: true),
    '',
  );

  bool _matches(String text, String phrase, String language) {
    if (language != 'en') return _normalize(text).contains(_normalize(phrase));
    final flexible = phrase
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map(RegExp.escape)
        .join(r'\s+');
    return RegExp('\\b$flexible\\b', caseSensitive: false).hasMatch(text);
  }

  bool _groupMatches(String key, String text) {
    final languages = corpus[key] as Map<String, dynamic>;
    for (final language in languages.entries) {
      for (final phrases in (language.value as Map<String, dynamic>).values) {
        for (final phrase in phrases as List) {
          if (_matches(text, phrase as String, language.key)) return true;
        }
      }
    }
    return false;
  }

  /// 沿用 Swift 的優先序：HIGH → 否定語境 → MEDIUM；LOW 不觸發警示。
  bool containsCrisisTerms(String text) {
    if (_groupMatches('HIGH', text)) return true;
    final negations = corpus['NEGATION_CONTEXTS'] as Map<String, dynamic>;
    for (final language in negations.entries) {
      for (final phrase in language.value as List) {
        if (_matches(text, phrase as String, language.key)) return false;
      }
    }
    return _groupMatches('MEDIUM', text);
  }
}
