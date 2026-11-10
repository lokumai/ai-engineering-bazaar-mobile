import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:flutter/widgets.dart';

/// Builds the quiz of the module [moduleKey] from its [items] (Decision A38): the reader names the slot without
/// importing the quiz feature, and the router passes the quiz feature's panel. The key lets the quiz keep its score.
typedef QuizBuilder = Widget Function(BuildContext context, String moduleKey, List<QuizItem> items);
