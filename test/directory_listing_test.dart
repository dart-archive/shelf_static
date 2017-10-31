// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test/test.dart';
import 'package:shelf_static/shelf_static.dart';

import 'test_util.dart';

void main() {
  setUp(() async {
    await d.file('index.html', '<html></html>').create();
    await d.file('root.txt', 'root txt').create();
    await d.dir('files', [
      d.file('index.html', '<html><body>files</body></html>'),
      d.file('with space.txt', 'with space content'),
      d.dir('empty subfolder', []),
    ]).create();
  });

  test('access "/"', () async {
    var handler = createStaticHandler(d.sandbox, listDirectories: true);

    var response = await makeRequest(handler, '/');
    expect(response.statusCode, HttpStatus.OK);
    expect(response.readAsString(), completes);
  });

  test('access "/files"', () async {
    var handler = createStaticHandler(d.sandbox, listDirectories: true);

    var response = await makeRequest(handler, '/files');
    expect(response.statusCode, HttpStatus.MOVED_PERMANENTLY);
    expect(response.headers,
        containsPair(HttpHeaders.LOCATION, 'http://localhost/files/'));
  });

  test('access "/files/"', () async {
    var handler = createStaticHandler(d.sandbox, listDirectories: true);

    var response = await makeRequest(handler, '/files/');
    expect(response.statusCode, HttpStatus.OK);
    expect(response.readAsString(), completes);
  });

  test('access "/files/empty subfolder"', () async {
    var handler = createStaticHandler(d.sandbox, listDirectories: true);

    var response = await makeRequest(handler, '/files/empty subfolder');
    expect(response.statusCode, HttpStatus.MOVED_PERMANENTLY);
    expect(
        response.headers,
        containsPair(
            HttpHeaders.LOCATION, 'http://localhost/files/empty%20subfolder/'));
  });

  test('access "/files/empty subfolder/"', () async {
    var handler = createStaticHandler(d.sandbox, listDirectories: true);

    var response = await makeRequest(handler, '/files/empty subfolder/');
    expect(response.statusCode, HttpStatus.OK);
    expect(response.readAsString(), completes);
  });
}
