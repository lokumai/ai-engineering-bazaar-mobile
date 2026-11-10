import 'package:ai_engineering_bazaar/features/progress/application/data_bloc.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';

/// The backup line of the data line and the erase dialog (web `DataPanel.tsx:236-240`).
String backupLineText(S s, BackupLine line) => switch (line) {
  BackedUp(:final day) => s.data_backed_up(day),
  BackupNotWritten() => s.data_backup_not_written,
};

/// The count of module states a record holds, as the erase and restore dialogs show it (web `erase.ts:71,86-90`).
String tallyText(S s, int sheets) => sheets == 0 ? s.data_tally_nothing : s.data_tally_states(sheets);
