import 'dart:io';

import '../doctor/project_doctor.dart';
import 'studio_http.dart';

Future<bool> handleDoctorRoutes(HttpRequest request) async {
  final path = request.uri.path;

  if (request.method == 'GET' && path == '/doctor') {
    StudioHttp.respondHtml(
      request.response,
      _doctorHtml(),
    );
    await request.response.close();
    return true;
  }

  if (request.method == 'GET' && path == '/api/doctor') {
    final project = request.uri.queryParameters['path'];
    if (project == null || project.trim().isEmpty) {
      StudioHttp.respondJson(request.response, 400, {
        'error': 'Query parameter path is required',
      });
      await request.response.close();
      return true;
    }
    final report = runProjectDoctor(Directory(project.trim()));
    StudioHttp.respondJson(request.response, 200, report.toJson());
    await request.response.close();
    return true;
  }

  return false;
}

String _doctorHtml() => '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Project Doctor</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #0d1117; color: #e6edf3; padding: 2rem; }
    pre { background: #161b22; padding: 1rem; border-radius: 8px; overflow: auto; }
    a { color: #58a6ff; }
  </style>
</head>
<body>
  <p><a href="/">← Hub</a></p>
  <h1>Project Doctor</h1>
  <p>Load a project on the hub first, then open this page with <code>?path=</code> or use the API.</p>
  <pre id="out">Loading…</pre>
  <script>
    (async () => {
      const boot = await fetch("/api/bootstrap").then(r => r.json()).catch(() => ({}));
      const path = new URLSearchParams(location.search).get("path") || boot.project_path;
      if (!path) {
        document.getElementById("out").textContent = "No project path — load a project on the hub.";
        return;
      }
      const res = await fetch("/api/doctor?path=" + encodeURIComponent(path));
      const data = await res.json();
      document.getElementById("out").textContent = JSON.stringify(data, null, 2);
    })();
  </script>
</body>
</html>
''';
