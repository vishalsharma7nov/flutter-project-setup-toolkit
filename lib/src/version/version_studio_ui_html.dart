/// Version Studio page HTML.
String versionStudioHtml() => r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Version Studio</title>
  <style>
    :root {
      --bg: #0c1018; --surface: rgba(255,255,255,0.06); --border: rgba(255,255,255,0.1);
      --text: #f2f5ff; --muted: #8d98b3; --accent: #fdcb6e; --teal: #4ecdc4; --danger: #ff6b6b;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg); color: var(--text); min-height: 100vh;
      background-image: radial-gradient(ellipse 50% 40% at 10% 0%, rgba(253,203,110,0.15), transparent);
    }
    .wrap { max-width: 900px; margin: 0 auto; padding: 1.5rem; }
    h1 { font-size: 1.75rem; margin-bottom: 0.35rem; }
    .subtitle { color: var(--muted); margin-bottom: 1.25rem; }
    .panel { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; padding: 1.25rem; margin-bottom: 1rem; }
    label { display: block; font-size: 0.78rem; color: var(--muted); margin-bottom: 0.35rem; }
    input, select {
      width: 100%; background: rgba(0,0,0,0.35); border: 1px solid var(--border);
      color: var(--text); padding: 0.7rem; border-radius: 10px; margin-bottom: 0.85rem;
    }
    .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    button {
      font-weight: 600; border: none; border-radius: 10px; padding: 0.75rem 1.25rem; cursor: pointer;
      background: linear-gradient(135deg, var(--accent), #e17055); color: #1a1208;
    }
    button.secondary { background: transparent; border: 1px solid var(--border); color: var(--muted); }
    button:disabled { opacity: 0.45; cursor: not-allowed; }
    .preview { font-family: Menlo, monospace; font-size: 0.78rem; background: #050810; border: 1px solid var(--border);
      border-radius: 10px; padding: 1rem; min-height: 180px; white-space: pre-wrap; color: #b8c4e8; }
    .badge { display: inline-block; padding: 0.25rem 0.65rem; border-radius: 999px; font-size: 0.75rem; font-weight: 700;
      background: rgba(253,203,110,0.2); color: var(--accent); border: 1px solid rgba(253,203,110,0.35); }
    .toggle { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem; font-size: 0.9rem; }
    .toggle input { width: auto; margin: 0; }
    .alert { background: rgba(255,107,107,0.12); border: 1px solid rgba(255,107,107,0.35); color: #ffc9c9;
      padding: 0.75rem; border-radius: 10px; margin-bottom: 1rem; display: none; }
    .alert.visible { display: block; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Version Studio</h1>
    <p class="subtitle">Classify the latest commit and update version keys in your env files.</p>
    <div id="alert" class="alert"></div>
    <div class="panel">
      <label>Project path</label>
      <input id="projectPath" type="text" placeholder="/path/to/flutter/app" />
      <div class="grid2">
        <div>
          <label>Git commit</label>
          <input id="commit" value="HEAD" />
        </div>
        <div>
          <label>Environment</label>
          <select id="envSelect"><option value="">Load project…</option></select>
        </div>
      </div>
      <div style="display:flex;gap:0.75rem;flex-wrap:wrap;margin-bottom:1rem">
        <button type="button" id="previewBtn">Preview bump</button>
        <button type="button" id="applyBtn" class="secondary">Apply to env files</button>
      </div>
      <label class="toggle"><input type="checkbox" id="dryRun" /> Dry run (show changes without writing)</label>
      <div id="bumpBadge" style="margin-bottom:0.75rem"></div>
      <div class="preview" id="preview">Click Preview to analyze the latest commit…</div>
    </div>
  </div>
  <script>
    const $ = (id) => document.getElementById(id);

    async function api(path, opts) {
      const res = await fetch(path, opts);
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || res.statusText);
      return data;
    }

    function showAlert(msg) {
      $("alert").textContent = msg;
      $("alert").classList.add("visible");
    }

    async function loadEnvironments() {
      const path = $("projectPath").value.trim();
      if (!path) return;
      const data = await api("/api/version/environments?path=" + encodeURIComponent(path));
      $("envSelect").innerHTML = "";
      Object.keys(data.environments || {}).forEach((name) => {
        const opt = document.createElement("option");
        opt.value = name;
        opt.textContent = name + " → " + data.environments[name];
        if (name === data.default_environment) opt.selected = true;
        $("envSelect").appendChild(opt);
      });
    }

    function renderPreview(data) {
      $("bumpBadge").innerHTML = '<span class="badge">' + data.bump + '</span> ' +
        '<span style="color:var(--muted);font-size:0.85rem">' + data.commit + ' — ' + (data.subject || "") + '</span>';
      let text = "Reasons:\n" + (data.reasons || []).map((r) => "  • " + r).join("\n") + "\n\n";
      for (const [env, info] of Object.entries(data.preview || {})) {
        text += "Environment: " + env + "\n  " + (info.env_file || "") + "\n";
        if (info.error) { text += "  ERROR: " + info.error + "\n\n"; continue; }
        if (info.android) text += "  android: " + info.android.current + " → " + info.android.suggested + "\n";
        if (info.ios) text += "  ios: " + info.ios.current + " → " + info.ios.suggested + "\n";
        text += "\n";
      }
      $("preview").textContent = text;
    }

    async function preview() {
      const path = $("projectPath").value.trim();
      if (!path) return showAlert("Enter project path");
      $("alert").classList.remove("visible");
      const data = await api("/api/version/preview", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          project: path,
          commit: $("commit").value.trim() || "HEAD",
          env: $("envSelect").value,
        }),
      });
      renderPreview(data);
    }

    async function apply() {
      const path = $("projectPath").value.trim();
      if (!path) return showAlert("Enter project path");
      if (!$("dryRun").checked && !confirm("Update version keys in env files?")) return;
      $("alert").classList.remove("visible");
      const data = await api("/api/version/apply", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          project: path,
          commit: $("commit").value.trim() || "HEAD",
          env: $("envSelect").value,
          dry_run: $("dryRun").checked,
        }),
      });
      renderPreview(data);
      let text = $("preview").textContent + "\n";
      for (const [env, info] of Object.entries(data.results || {})) {
        text += (data.applied ? "Applied" : "Dry run") + " (" + env + "):\n";
        for (const [key, ch] of Object.entries(info.changes || {})) {
          text += "  " + key + ": " + (ch.from || "(missing)") + " → " + ch.to + "\n";
        }
      }
      $("preview").textContent = text;
    }

    $("previewBtn").addEventListener("click", () => preview().catch((e) => showAlert(e.message)));
    $("applyBtn").addEventListener("click", () => apply().catch((e) => showAlert(e.message)));
    $("projectPath").addEventListener("change", () => loadEnvironments().catch(() => {}));

    (async () => {
      const boot = await api("/api/bootstrap");
      if (boot.project_path) {
        $("projectPath").value = boot.project_path;
        await loadEnvironments();
      }
    })().catch(() => {});
  </script>
</body>
</html>
''';
