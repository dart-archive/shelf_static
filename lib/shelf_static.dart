library shelf_static;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

// directory listing
// default document
// sym links
// mime type handling
// hidden files

Handler getHandler(String fileSystemPath, {bool restrictSymbolicLinks: true}) {
  var rootDir = new Directory(fileSystemPath);
  fileSystemPath = rootDir.resolveSymbolicLinksSync();

  return (Request request) {
    // TODO: expand these checks and/or follow updates to Uri class to be more
    //       strict. https://code.google.com/p/dart/issues/detail?id=16081
    if (request.requestedUri.path.contains(' ')) {
      return new Response.forbidden('The requested path is invalid.');
    }

    var segs = [fileSystemPath]..addAll(request.url.pathSegments);

    var requestedPath = p.joinAll(segs);
    var file = new File(requestedPath);

    if (!file.existsSync()) {
      return new Response.notFound('Not Found');
    }

    var resolvedPath = file.path;
    if(restrictSymbolicLinks) {
      resolvedPath = file.resolveSymbolicLinksSync();
    }

    // Do not serve a file outside of the original fileSystemPath
    if (!p.isWithin(fileSystemPath, resolvedPath)) {
      // TODO(kevmoo) throw a real error here. Perhaps a new error type?
      throw 'Requested path ${request.url.path} resolved to $resolvedPath '
          'is not under $fileSystemPath.';
    }

    var stats = file.statSync();

    var headers = <String, String>{
      HttpHeaders.CONTENT_LENGTH: stats.size.toString()
    };

    return new Response.ok(file.openRead(), headers: headers);
  };
}
