import 'dart:convert';
import 'dart:io';
import 'package:angel_client/io.dart' as c;
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_shelf/angel_shelf.dart';
import 'package:angel_test/angel_test.dart';
import 'package:charcode/charcode.dart';
import 'package:logging/logging.dart';
import 'package:pretty_logging/pretty_logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

main() {
  c.Angel client;
  HttpServer server;
  String url;

  String _path(String p) {
    return Uri(
            scheme: 'http',
            host: server.address.address,
            port: server.port,
            path: p)
        .toString();
  }

  setUp(() async {
    var handler = shelf.Pipeline().addHandler((shelf.Request request) {
      if (request.url.path == 'two') {
        return shelf.Response(200, body: json.encode(2));
      } else if (request.url.path == 'error') {
        throw AngelHttpException.notFound();
      } else if (request.url.path == 'status') {
        return shelf.Response.notModified(headers: {'foo': 'bar'});
      } else if (request.url.path == 'hijack') {
        request.hijack((StreamChannel<List<int>> channel) {
          var sink = channel.sink;
          sink.add(utf8.encode('HTTP/1.1 200 OK\r\n'));
          sink.add([$lf]);
          sink.add(utf8.encode(json.encode({'error': 'crime'})));
          sink.close();
        });
        return null;
      } else if (request.url.path == 'throw') {
        return null;
      } else {
        return shelf.Response.ok('Request for "${request.url}"');
      }
    });

    var logger = Logger.detached('angel_shelf')..onRecord.listen(prettyLog);
    var app = Angel(logger: logger);
    var http = AngelHttp(app);
    app.get('/angel', (req, res) => 'Angel');
    app.fallback(embedShelf(handler, throwOnNullResponse: true));

    server = await http.startServer(InternetAddress.loopbackIPv4, 0);
    client = c.Rest(url = http.uri.toString());
  });

  tearDown(() async {
    await client.close();
    await server.close(force: true);
  });

  test('expose angel side', () async {
    var response = await client.get(_path('/angel'));
    expect(json.decode(response.body), equals('Angel'));
  });

  test('expose shelf side', () async {
    var response = await client.get(_path('/foo'));
    expect(response, hasStatus(200));
    expect(response.body, equals('Request for "foo"'));
  });

  test('shelf can return arbitrary values', () async {
    var response = await client.get(_path('/two'));
    expect(response, isJson(2));
  });

  test('shelf can hijack', () async {
    try {
      var client = HttpClient();
      var rq = await client.openUrl('GET', Uri.parse('$url/hijack'));
      var rs = await rq.close();
      var body = await rs.cast<List<int>>().transform(utf8.decoder).join();
      print('Response: $body');
      expect(json.decode(body), {'error': 'crime'});
    } on HttpException catch (e, st) {
      print('HTTP Exception: ' + e.message);
      print(st);
      rethrow;
    }
  }, skip: '');

  test('shelf can set status code', () async {
    var response = await client.get(_path('/status'));
    expect(response, allOf(hasStatus(304), hasHeader('foo', 'bar')));
  });

  test('shelf can throw error', () async {
    var response = await client.get(_path('/error'));
    expect(response, hasStatus(404));
  });

  test('throw on null', () async {
    var response = await client.get(_path('/throw'));
    expect(response, hasStatus(500));
  });
}
