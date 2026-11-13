import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Project-wide reusable [EventTransformer]s.
///
/// Picking a transformer is part of designing an event: a write needs drop-while-running to defeat a double tap, and
/// ordered changes need one at a time. The two below are the ones the app uses, under one name each.
class EventTransformers {
  EventTransformers._();

  /// Re-export of bloc_concurrency's [droppable] under our naming so all
  /// transformers are reached via [EventTransformers]. Use for submit /
  /// delete / write events to prevent concurrent re-execution.
  static EventTransformer<E> dropConcurrent<E>() => droppable<E>();

  /// Re-export of bloc_concurrency's [sequential]. Use when handler order
  /// must equal event order (e.g. pagination, ordered mutations).
  static EventTransformer<E> queue<E>() => sequential<E>();
}
