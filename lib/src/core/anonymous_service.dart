import 'dart:async';

import 'service.dart';

/// An easy helper class to create one-off services without having to create an entire class.
///
/// Well-suited for testing.
class AnonymousService<Id, Data> extends Service<Id, Data> {
  FutureOr Function([Map<String, dynamic>]) _index;
  FutureOr Function(Id, [Map<String, dynamic>]) _read, _remove;
  FutureOr Function(Data, [Map<String, dynamic>]) _create;
  Function(Id, Data, [Map<String, dynamic>]) _modify, _update;

  AnonymousService(
      {FutureOr index([Map params]),
      FutureOr read(Id id, [Map params]),
      FutureOr create(Data data, [Map params]),
      FutureOr modify(Id id, Data data, [Map params]),
      FutureOr update(Id id, Data data, [Map params]),
      FutureOr remove(Id id, [Map params])})
      : super() {
    _index = index;
    _read = read;
    _create = create;
    _modify = modify;
    _update = update;
    _remove = remove;
  }

  @override
  index([Map<String, dynamic> params]) => new Future.sync(
      () => _index != null ? _index(params) : super.index(params));

  @override
  read(Id id, [Map<String, dynamic> params]) => new Future.sync(
      () => _read != null ? _read(id, params) : super.read(id, params));

  @override
  create(Data data, [Map<String, dynamic> params]) => new Future.sync(() =>
      _create != null ? _create(data, params) : super.create(data, params));

  @override
  modify(Id id, Data data, [Map<String, dynamic> params]) =>
      new Future.sync(() => _modify != null
          ? _modify(id, data, params)
          : super.modify(id, data, params));

  @override
  update(Id id, Data data, [Map<String, dynamic> params]) =>
      new Future.sync(() => _update != null
          ? _update(id, data, params)
          : super.update(id, data, params));

  @override
  remove(Id id, [Map<String, dynamic> params]) => new Future.sync(
      () => _remove != null ? _remove(id, params) : super.remove(id, params));
}
