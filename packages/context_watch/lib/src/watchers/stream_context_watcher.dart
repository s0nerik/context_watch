import 'dart:async';

import 'package:context_watch_base/context_watch_base.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/streams.dart';

class _Subscription implements ContextWatchSubscription {
  _Subscription({
    required StreamSubscription<dynamic> streamSubscription,
    required this.snapshot,
  }) : _sub = streamSubscription;

  final StreamSubscription _sub;
  AsyncSnapshot snapshot;

  @override
  Object? getData() => snapshot;

  @override
  void cancel() => _sub.cancel();
}

class StreamContextWatcher extends ContextWatcher<Stream> {
  @override
  ContextWatchSubscription createSubscription<T>(
    BuildContext context,
    Stream observable,
  ) {
    final stream = observable as Stream<T>;
    final element = context as Element;

    late final _Subscription subscription;
    final streamSubscription = stream.listen((data) {
      if (!canNotify(context, stream)) {
        return;
      }

      subscription.snapshot =
          AsyncSnapshot<T>.withData(ConnectionState.active, data);
      element.markNeedsBuild();
    }, onError: (Object error, StackTrace stackTrace) {
      if (!canNotify(context, stream)) {
        return;
      }

      subscription.snapshot =
          AsyncSnapshot<T>.withError(ConnectionState.active, error, stackTrace);
      element.markNeedsBuild();
    }, onDone: () {
      if (!canNotify(context, stream)) {
        return;
      }

      subscription.snapshot =
          subscription.snapshot.inState(ConnectionState.done);
      element.markNeedsBuild();
    });

    subscription = _Subscription(
      streamSubscription: streamSubscription,
      snapshot: _initialSnapshot<T>(stream),
    );

    return subscription;
  }
}

AsyncSnapshot<T> _initialSnapshot<T>(Stream stream) {
  if (stream is ValueStream<T>) {
    if (stream.hasValue) {
      return AsyncSnapshot<T>.withData(
        ConnectionState.waiting,
        stream.value,
      );
    }
    if (stream.hasError) {
      if (stream.stackTrace != null) {
        return AsyncSnapshot<T>.withError(
          ConnectionState.waiting,
          stream.error,
          stream.stackTrace!,
        );
      }
      return AsyncSnapshot<T>.withError(
        ConnectionState.waiting,
        stream.error,
      );
    }
  }
  return AsyncSnapshot<T>.nothing().inState(ConnectionState.waiting);
}

extension StreamContextWatchExtension<T> on Stream<T> {
  /// Watch this [Stream] for changes.
  ///
  /// Whenever this [Stream] emits new value, the [context] will be
  /// rebuilt.
  ///
  /// If this [Stream] is a [ValueStream], the initial value will be used
  /// as the initial value of the [AsyncSnapshot].
  ///
  /// It is safe to call this method multiple times within the same build
  /// method.
  AsyncSnapshot<T> watch(BuildContext context) {
    final watchRoot = InheritedContextWatch.of(context);
    context.dependOnInheritedElement(watchRoot);
    final snapshot = watchRoot.watch<T>(context, this);
    if (snapshot == null) {
      return AsyncSnapshot<T>.nothing();
    }
    return snapshot as AsyncSnapshot<T>;
  }
}
