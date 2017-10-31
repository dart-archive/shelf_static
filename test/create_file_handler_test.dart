// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test/test.dart';

import 'package:shelf_static/shelf_static.dart';
import 'test_util.dart';

void main() {
  setUp(() async {
    await d.file('file.txt', 'contents').create();
    await d.file('random.unknown', 'no clue').create();
  });

  test('serves the file contents', () async {
    var handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
    var response = await makeRequest(handler, '/file.txt');
    expect(response.statusCode, equals(HttpStatus.OK));
    expect(response.contentLength, equals(8));
    expect(response.readAsString(), completion(equals('contents')));
  });

  test('serves a 404 for a non-matching URL', () async {
    var handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
    var response = await makeRequest(handler, '/foo/file.txt');
    expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
  });

  test('serves the file contents under a custom URL', () async {
    var handler =
        createFileHandler(p.join(d.sandbox, 'file.txt'), url: 'foo/bar');
    var response = await makeRequest(handler, '/foo/bar');
    expect(response.statusCode, equals(HttpStatus.OK));
    expect(response.contentLength, equals(8));
    expect(response.readAsString(), completion(equals('contents')));
  });

  test("serves a 404 if the custom URL isn't matched", () async {
    var handler =
        createFileHandler(p.join(d.sandbox, 'file.txt'), url: 'foo/bar');
    var response = await makeRequest(handler, '/file.txt');
    expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
  });

  group('the content type header', () {
    test('is inferred from the file path', () async {
      var handler = createFileHandler(p.join(d.sandbox, 'file.txt'));
      var response = await makeRequest(handler, '/file.txt');
      expect(response.statusCode, equals(HttpStatus.OK));
      expect(response.mimeType, equals('text/plain'));
    });

    test("is omitted if it can't be inferred", () async {
      var handler = createFileHandler(p.join(d.sandbox, 'random.unknown'));
      var response = await makeRequest(handler, '/random.unknown');
      expect(response.statusCode, equals(HttpStatus.OK));
      expect(response.mimeType, isNull);
    });

    test('comes from the contentType parameter', () async {
      var handler = createFileHandler(p.join(d.sandbox, 'file.txt'),
          contentType: 'something/weird');
      var response = await makeRequest(handler, '/file.txt');
      expect(response.statusCode, equals(HttpStatus.OK));
      expect(response.mimeType, equals('something/weird'));
    });
  });

  group('throws an ArgumentError for', () {
    test("a file that doesn't exist", () {
      expect(() => createFileHandler(p.join(d.sandbox, 'nothing.txt')),
          throwsArgumentError);
    });

    test("an absolute URL", () {
      expect(
          () => createFileHandler(p.join(d.sandbox, 'nothing.txt'),
              url: '/foo/bar'),
          throwsArgumentError);
    });
  });
}
