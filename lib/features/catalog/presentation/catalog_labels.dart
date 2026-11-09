/// A module number as the catalog prints it, zero-padded to two digits (web `SheetRow.number`).
String moduleNumber(int number) => number.toString().padLeft(2, '0');
