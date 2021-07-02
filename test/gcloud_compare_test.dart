import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('google storage', () {
    _testHead(Uri.parse(fileFun));
  });

  group('local', () {
    _testHead(
        Uri.parse('http://localhost:55490/dart_sdk_test_example.sha256sum'));
  });
}

void _testHead(Uri uri) {
  group('head', () {
    void doTest(
      String name,
      Map<String, String> headers,
      void Function(Response) checker,
    ) {
      test(name, () async {
        final response = await head(uri, headers: headers);
        expect(response.statusCode, 206);
        expect(response.headers, containsPair('accept-ranges', 'bytes'));
        expect(response.headers, contains('date'));
        expect(response.headers, contains('last-modified'));
        expect(response.contentLength, 0);
        expect(response.bodyBytes, isEmpty);
        checker(response);
      });
    }

    doTest('no headers', {}, (response) {
      expect(response.headers, containsPair('content-length', '96'));
      expect(response.headers, isNot(contains('content-range')));
    });

    doTest('valid range', {'range': 'bytes=0-4'}, (response) {
      expect(response.headers, containsPair('content-length', '5'));
      expect(response.headers, containsPair('content-range', 'bytes 0-4/96'));
    });

    doTest('too long range', {'range': 'bytes=0-256'}, (response) {
      expect(response.headers, containsPair('content-length', '96'));
      expect(response.headers, containsPair('content-range', 'bytes 0-95/96'));
    });

    doTest('range too far out', {'range': 'bytes=256-512'}, (response) {
      // Google inconsistent!
      expect(
        response.headers,
        containsPair(
          'content-length',
          anyOf('0', '169'),
        ),
      );
      expect(
        response.headers,
        anyOf(
          isNot(contains('content-range')),
          containsPair('content-range', 'bytes */96'),
        ),
      );
    });

    doTest('junk range', {'range': 'bytes=4242'}, (response) {
      expect(
        response.headers,
        containsPair('content-length', '96'),
      );
      expect(response.headers, isNot(contains('content-range')));
    });
  });

  group('get', () {
    void doTest(
      String name,
      Map<String, String> headers,
      void Function(Response) checker,
    ) {
      test(name, () async {
        final response = await get(uri, headers: headers);
        expect(response.statusCode, 206);
        expect(response.headers, containsPair('accept-ranges', 'bytes'));
        expect(response.headers, contains('date'));
        expect(response.headers, contains('last-modified'));
        checker(response);
      });
    }

    doTest('no headers', {}, (response) {
      expect(response.headers, containsPair('content-length', '96'));
      expect(response.headers, isNot(contains('content-range')));
      expect(response.contentLength, 96);
      expect(response.bodyBytes, hasLength(96));
    });

    doTest('valid range', {'range': 'bytes=0-4'}, (response) {
      expect(response.headers, containsPair('content-length', '5'));
      expect(response.headers, containsPair('content-range', 'bytes 0-4/96'));
      expect(response.contentLength, 5);
      expect(response.bodyBytes, hasLength(5));
    });

    doTest('too long range', {'range': 'bytes=0-256'}, (response) {
      expect(response.headers, containsPair('content-length', '96'));
      expect(response.headers, containsPair('content-range', 'bytes 0-95/96'));
      expect(response.contentLength, 96);
      expect(response.bodyBytes, hasLength(96));
    });

    doTest('range too far out', {'range': 'bytes=256-512'}, (response) {
      expect(response.contentLength, 0);
      expect(response.bodyBytes, hasLength(0));
      // Google inconsistent!
      expect(
        response.headers,
        containsPair(
          'content-length',
          anyOf('0', '169'),
        ),
      );
      expect(
        response.headers,
        anyOf(
          isNot(contains('content-range')),
          containsPair('content-range', 'bytes */96'),
        ),
      );
    });

    doTest('junk range', {'range': 'bytes=4242'}, (response) {
      expect(response.contentLength, 96);
      expect(response.bodyBytes, hasLength(96));
      expect(
        response.headers,
        containsPair('content-length', '96'),
      );
      expect(response.headers, isNot(contains('content-range')));
    });
  });
}

void printResponse(Response response) {
  print(response.statusCode);
  print(
    (response.headers.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key.padRight(30)} ${e.value}')
        .join('\n'),
  );
}

const fileFun =
    'https://storage.googleapis.com/dart-archive/channels/stable/release/2.13.4/sdk/dartsdk-macos-x64-release.zip.sha256sum';
