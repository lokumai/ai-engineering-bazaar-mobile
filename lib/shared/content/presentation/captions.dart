import 'package:ai_engineering_bazaar/generated/l10n.dart';

/// The caption of an image or a diagram: `FIG. <number>`, then ` · <title>` when the block has a title (spec 3.6.3;
/// the web's em dash is a middle dot here, A14).
String figureCaption(S s, {required String number, String? title}) => _withTitle(s.block_figure_caption(number), title);

/// The caption of a table: `TBL. <number>`, then ` · <title>` when the block has a title.
String tableCaption(S s, {required String number, String? title}) => _withTitle(s.block_table_caption(number), title);

String _withTitle(String label, String? title) => title == null || title.isEmpty ? label : '$label · $title';
