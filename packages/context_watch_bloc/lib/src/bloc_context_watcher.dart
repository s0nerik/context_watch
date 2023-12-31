import 'dart:async';

import 'package:context_watch_base/context_watch_base.dart';
import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';

class _Subscription implements ContextWatchSubscription {
  _Subscription({
    required StreamSubscription<dynamic> streamSubscription,
  }) : _sub = streamSubscription;

  final StreamSubscription _sub;

  @override
  Object? getData() => null;

  @override
  void cancel() => _sub.cancel();
}

class BlocContextWatcher extends ContextWatcher<StateStreamable> {
  BlocContextWatcher._();

  static final instance = BlocContextWatcher._();

  @override
  ContextWatchSubscription createSubscription<T>(
      BuildContext context, StateStreamable observable) {
    final bloc = observable;
    final element = context as Element;

    late final _Subscription subscription;

    final streamSubscription = bloc.stream.listen((data) {
      if (!canNotify(context, bloc)) {
        return;
      }
      element.markNeedsBuild();
    });

    subscription = _Subscription(
      streamSubscription: streamSubscription,
    );

    return subscription;
  }
}

extension BlocContextWatchExtension<T> on StateStreamable<T> {
  /// Watch this [StateStreamable] for changes.
  ///
  /// Whenever this [StateStreamable] emits new value, the [context] will be
  /// rebuilt.
  ///
  /// It is safe to call this method multiple times within the same build
  /// method.
  T watch(BuildContext context) {
    final watchRoot = InheritedContextWatch.of(context);
    context.dependOnInheritedElement(watchRoot);
    watchRoot.watch<T>(context, this);
    return state;
  }
}
