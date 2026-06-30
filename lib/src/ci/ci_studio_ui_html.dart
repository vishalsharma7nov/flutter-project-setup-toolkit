/// CI Studio single-page wizard UI.
String ciStudioHtml() => r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>CI Studio</title>
  <style>
    :root {
      --bg: #0b0f1a; --surface: rgba(255,255,255,0.06); --border: rgba(255,255,255,0.12);
      --text: #f0f4ff; --muted: #8b95b0; --accent: #6c5ce7; --teal: #4ecdc4;
      --success: #2ecc71; --danger: #ff6b6b; --warn: #ffb26b;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg); color: var(--text); min-height: 100vh;
      background-image: radial-gradient(ellipse 70% 50% at 10% -5%, rgba(108,92,231,0.35), transparent);
    }
    .wrap { max-width: 980px; margin: 0 auto; padding: 2rem 1.25rem 3rem; }
    h1 { font-size: 1.85rem; margin-bottom: 0.35rem; }
    .subtitle { color: var(--muted); margin-bottom: 1.5rem; }
    .steps { display: flex; gap: 0.5rem; margin-bottom: 1.25rem; flex-wrap: wrap; }
    .step-pill {
      padding: 0.4rem 0.85rem; border-radius: 999px; font-size: 0.82rem;
      border: 1px solid var(--border); color: var(--muted);
    }
    .step-pill.active { border-color: var(--accent); color: #fff; background: rgba(108,92,231,0.25); }
    .step-pill.done { border-color: var(--success); color: var(--success); }
    .panel {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: 14px; padding: 1.25rem; margin-bottom: 1rem;
    }
    .panel h2 { font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted); margin-bottom: 0.75rem; }
    label { display: block; font-size: 0.8rem; color: var(--muted); margin-bottom: 0.35rem; }
    input, select, textarea {
      width: 100%; background: rgba(0,0,0,0.35); border: 1px solid var(--border);
      color: var(--text); padding: 0.65rem 0.85rem; border-radius: 10px; font-size: 0.92rem;
    }
    textarea { font-family: ui-monospace, monospace; font-size: 0.78rem; min-height: 220px; }
    .toggle-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 0.5rem; }
    .toggle { display: flex; align-items: center; gap: 0.5rem; font-size: 0.88rem; color: var(--text); }
    button {
      font-family: inherit; font-weight: 600; border: none; border-radius: 10px;
      padding: 0.7rem 1.1rem; cursor: pointer; background: linear-gradient(135deg, var(--accent), #a29bfe); color: #fff;
    }
    button.secondary { background: rgba(255,255,255,0.08); border: 1px solid var(--border); color: var(--text); }
    button:disabled { opacity: 0.4; cursor: not-allowed; }
    .row { display: flex; gap: 0.75rem; flex-wrap: wrap; align-items: center; margin-top: 0.75rem; }
    .hidden { display: none !important; }
    .alert {
      padding: 0.75rem 1rem; border-radius: 10px; margin-bottom: 1rem; font-size: 0.88rem;
      background: rgba(255,107,107,0.12); border: 1px solid rgba(255,107,107,0.35); color: #ffd0d0;
    }
    .success-banner {
      padding: 0.85rem 1rem; border-radius: 10px; margin-bottom: 1rem;
      background: rgba(46,204,113,0.12); border: 1px solid rgba(46,204,113,0.35); color: #c8f7dc;
    }
    .checks { list-style: none; font-size: 0.88rem; }
    .checks li { padding: 0.35rem 0; }
    .checks li.ok { color: var(--success); }
    .checks li.warn { color: var(--warn); }
    .checks li.optional { color: var(--muted); }
    .tier-label {
      font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.08em;
      color: var(--muted); margin: 0.85rem 0 0.35rem;
    }
    .tier-label:first-child { margin-top: 0; }
    .devops-status {
      font-size: 0.88rem; margin-bottom: 0.75rem; padding: 0.65rem 0.85rem;
      border-radius: 8px; border: 1px solid var(--border); background: rgba(0,0,0,0.2);
    }
    .devops-status.ready { border-color: rgba(46,204,113,0.4); color: #c8f7dc; }
    .devops-status.pending { border-color: rgba(255,178,107,0.35); color: #ffe0c0; }
    .warn-box {
      padding: 0.75rem 1rem; border-radius: 10px; margin-bottom: 1rem; font-size: 0.85rem;
      background: rgba(255,178,107,0.12); border: 1px solid rgba(255,178,107,0.35); color: #ffe0c0;
    }
    .terminal {
      background: #050810; border: 1px solid var(--border); border-radius: 10px;
      padding: 0.85rem; font-family: ui-monospace, monospace; font-size: 0.78rem;
      max-height: 280px; overflow: auto; white-space: pre-wrap;
    }
    .status { font-size: 0.85rem; color: var(--muted); }
    a { color: var(--teal); }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>CI Studio</h1>
    <p class="subtitle">Generate GitHub Actions workflows, test locally, then publish via pull request.</p>

    <div class="steps">
      <span class="step-pill active" id="pill1">1 Configure</span>
      <span class="step-pill" id="pill2">2 Write &amp; test</span>
      <span class="step-pill" id="pill3">3 Publish</span>
    </div>

    <div id="alertBox" class="alert hidden"></div>
    <div id="successBox" class="success-banner hidden"></div>

    <section id="step1">
      <div class="panel">
        <h2>DevOps setup</h2>
        <p class="status" style="margin-bottom:0.75rem">
          Minimal tools to generate, test, and publish CI for this Flutter project.
        </p>
        <div id="devopsStatus" class="devops-status pending">Checking…</div>
        <div id="devopsRequirements"></div>
        <div id="costWarnings" class="warn-box hidden"></div>
        <p id="actHint" class="status hidden" style="margin-top:0.5rem"></p>
      </div>
      <div class="panel">
        <h2>Preset</h2>
        <label for="preset">Workflow preset</label>
        <select id="preset">
          <option value="full">Full (split CI + release)</option>
          <option value="prChecks">PR checks only</option>
          <option value="release">Release builds</option>
          <option value="costConsciousWeeklyShip">Cost-conscious weekly ship</option>
        </select>
        <div class="row" style="margin-top:0.75rem">
          <label class="toggle"><input type="radio" name="pipeline" value="split" checked /> Split CI + release</label>
          <label class="toggle"><input type="radio" name="pipeline" value="single" /> Single workflow file</label>
        </div>
      </div>
      <div class="panel">
        <h2>Jobs</h2>
        <div class="toggle-grid">
          <label class="toggle"><input type="checkbox" id="jobAnalyze" checked /> Analyze + test</label>
          <label class="toggle"><input type="checkbox" id="jobFormat" checked /> Format check</label>
          <label class="toggle"><input type="checkbox" id="jobAudit" checked /> Architecture audit</label>
          <label class="toggle"><input type="checkbox" id="jobAndroid" checked /> Android AAB</label>
          <label class="toggle"><input type="checkbox" id="jobIos" checked /> iOS IPA</label>
          <label class="toggle"><input type="checkbox" id="jobArtifacts" checked /> Upload artifacts</label>
          <label class="toggle"><input type="checkbox" id="jobCoverage" /> Coverage upload</label>
          <label class="toggle"><input type="checkbox" id="jobPathFilters" /> Path filters (skip docs-only)</label>
          <label class="toggle"><input type="checkbox" id="jobFirebase" /> Firebase App Distribution stub</label>
          <label class="toggle"><input type="checkbox" id="jobToolkitScripts" /> Use scripts/build-*.sh</label>
        </div>
      </div>
      <div class="panel">
        <h2>YAML preview</h2>
        <div class="row" style="margin-bottom:0.5rem">
          <label class="toggle"><input type="radio" name="previewMode" value="yaml" checked /> Full YAML</label>
          <label class="toggle"><input type="radio" name="previewMode" value="diff" /> Diff (if overwriting)</label>
        </div>
        <textarea id="yamlPreview" readonly placeholder="Click Preview to generate YAML…"></textarea>
        <p id="overwriteWarn" class="status hidden" style="margin-top:0.5rem;color:var(--warn)"></p>
        <div class="row">
          <button type="button" class="secondary" id="previewBtn">Preview YAML</button>
          <button type="button" id="next1Btn">Continue to test →</button>
        </div>
      </div>
    </section>

    <section id="step2" class="hidden">
      <div class="panel">
        <h2>Write locally</h2>
        <p style="font-size:0.88rem;color:var(--muted);margin-bottom:0.75rem">
          Saves workflow files under <code>.github/workflows/</code> — nothing is pushed until step 3.
        </p>
        <button type="button" id="writeBtn">Save workflow locally</button>
        <p id="writeResult" class="status" style="margin-top:0.75rem"></p>
      </div>
      <div class="panel">
        <h2>Local test</h2>
        <p class="status" id="testStatus">Test not run yet</p>
        <div class="row">
          <button type="button" id="nativeTestBtn">Run native smoke test</button>
          <button type="button" class="secondary hidden" id="actTestBtn">Run with act (ubuntu)</button>
        </div>
        <div class="terminal" id="terminal" style="margin-top:0.75rem"></div>
        <div class="row">
          <button type="button" class="secondary" id="back2Btn">← Back</button>
          <button type="button" id="next2Btn" disabled>Continue to publish →</button>
        </div>
      </div>
    </section>

    <section id="step3" class="hidden">
      <div class="panel">
        <h2>Secrets checklist</h2>
        <ul id="secretsList" style="font-size:0.88rem;line-height:1.6"></ul>
      </div>
      <div class="panel">
        <h2>Publish to GitHub</h2>
        <p style="font-size:0.88rem;color:var(--muted);margin-bottom:0.75rem">
          Requires a passing local test. Opens a pull request with the workflow — never auto-pushes without your click.
        </p>
        <button type="button" id="publishBtn" disabled>Publish to GitHub</button>
        <p id="publishResult" class="status" style="margin-top:0.75rem"></p>
        <div id="publishSuccess" class="success-banner hidden" style="margin-top:0.75rem"></div>
        <div class="row" style="margin-top:0.75rem">
          <button type="button" class="secondary" id="back3Btn">← Back</button>
        </div>
      </div>
    </section>
  </div>

  <script>
    let detectData = {};
    let lastTestPassed = false;
    let logOffset = 0;
    let pollTimer = null;
    let lastPreview = { files: {}, diffs: {} };

    function $(id) { return document.getElementById(id); }
    function showAlert(msg) { $("alertBox").textContent = msg; $("alertBox").classList.remove("hidden"); }
    function hideAlert() { $("alertBox").classList.add("hidden"); }

    function goStep(n) {
      [1,2,3].forEach((i) => {
        $("step" + i).classList.toggle("hidden", i !== n);
        const pill = $("pill" + i);
        pill.classList.toggle("active", i === n);
        pill.classList.toggle("done", i < n || (i === 2 && lastTestPassed));
      });
    }

    function collectSpec() {
      return {
        preset: $("preset").value,
        pipeline_mode: document.querySelector('input[name="pipeline"]:checked').value,
        analyze: $("jobAnalyze").checked,
        format_check: $("jobFormat").checked,
        architecture_audit: $("jobAudit").checked,
        android_aab: $("jobAndroid").checked,
        ios_ipa: $("jobIos").checked,
        upload_artifacts: $("jobArtifacts").checked,
        coverage: $("jobCoverage").checked,
        path_filters: $("jobPathFilters").checked,
        firebase_app_distribution: $("jobFirebase").checked,
        use_toolkit_scripts: $("jobToolkitScripts").checked,
        flutter_version: detectData.flutter_version || undefined,
        act_compat_flutter_x64: !!detectData.default_spec?.act_compat_flutter_x64,
        on_push: true,
        on_pull_request: true,
        workflow_dispatch: true,
      };
    }

    async function api(path, opts) {
      const res = await fetch(path, opts);
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error || res.statusText);
      return data;
    }

    async function projectPath() {
      const path = await rtkRequireProject();
      if (!path) throw new Error("No project loaded");
      return path;
    }

    function renderDevOpsTier(title, items, cssClass) {
      if (!items?.length) return "";
      const rows = items.map((r) => {
        const icon = r.ok ? "✓" : (cssClass === "optional" ? "○" : "✗");
        const hint = r.setup_hint ? `<br><span style="color:var(--muted);font-size:0.82rem">${r.setup_hint}</span>` : "";
        return `<li class="${r.ok ? "ok" : cssClass}">${icon} <strong>${r.label}</strong> — ${r.message}${hint}</li>`;
      }).join("");
      return `<div class="tier-label">${title}</div><ul class="checks">${rows}</ul>`;
    }

    function renderDevOpsSetup(setup) {
      if (!setup) return;
      const status = $("devopsStatus");
      if (setup.minimal_ready) {
        status.textContent = setup.publish_ready
          ? "Ready — minimal DevOps setup complete; publish to GitHub is available."
          : "Minimal setup OK — configure GitHub origin + gh auth to publish.";
        status.className = "devops-status ready";
      } else {
        status.textContent = "Complete required items below before generating CI workflows.";
        status.className = "devops-status pending";
      }
      const s = setup.summary || {};
      $("devopsRequirements").innerHTML =
        renderDevOpsTier("Required (minimal)", s.required, "bad") +
        renderDevOpsTier("Required to publish", s.publish, "bad") +
        renderDevOpsTier("Recommended for selected jobs", s.recommended, "warn") +
        renderDevOpsTier("Optional", s.optional, "optional");
    }

    async function loadDetect() {
      const path = await projectPath();
      detectData = await api("/api/ci/detect?path=" + encodeURIComponent(path));
      renderDevOpsSetup(detectData.devops_setup);
      syncActUi(detectData.features?.act === true);
      if (detectData.default_spec) {
        const s = detectData.default_spec;
        $("preset").value = s.preset || "full";
        if (s.pipeline_mode) {
          document.querySelector(`input[name="pipeline"][value="${s.pipeline_mode}"]`).checked = true;
        }
      }
      renderSecrets(detectData.secrets_checklist || []);
      const warnings = detectData.cost_warnings || [];
      const warnBox = $("costWarnings");
      if (warnings.length) {
        warnBox.innerHTML = warnings.map((w) => `<div>⚠ ${w}</div>`).join("");
        warnBox.classList.remove("hidden");
      } else {
        warnBox.classList.add("hidden");
      }
      $("actHint").textContent = detectData.tooling?.act?.on_demand
        ? (detectData.tooling.act.docker_available
            ? "act: installed temporarily when you run Test with act (requires Docker). Command: "
              + (detectData.act_command || "")
            : "act tests require Docker — start Docker Desktop first")
        : (detectData.act_command ? "act command: " + detectData.act_command : "");
    }

    function syncActUi(enabled) {
      $("actTestBtn").classList.toggle("hidden", !enabled);
      $("actHint").classList.toggle("hidden", !enabled);
    }

    function renderPreviewPane() {
      const mode = document.querySelector('input[name="previewMode"]:checked')?.value || "yaml";
      if (mode === "diff") {
        const diffs = Object.entries(lastPreview.diffs || {});
        $("yamlPreview").value = diffs.length
          ? diffs.map(([k,v]) => `# diff: ${k}\n${v}`).join("\n\n")
          : "No existing workflow files — nothing to diff.";
      } else {
        const files = lastPreview.files || {};
        $("yamlPreview").value = Object.entries(files).map(([k,v]) => `# ${k}\n${v}`).join("\n\n");
      }
    }

    document.querySelectorAll('input[name="previewMode"]').forEach((el) => {
      el.addEventListener("change", renderPreviewPane);
    });

    function renderSecrets(items) {
      $("secretsList").innerHTML = items.map((s) =>
        `<li><code>${s.name}</code> ${s.required ? "(required)" : "(optional)"} — ${s.description}</li>`
      ).join("");
    }

    async function previewYaml() {
      hideAlert();
      const path = await projectPath();
      const data = await api("/api/ci/preview", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ path, spec: collectSpec() }),
      });
      lastPreview = { files: data.files || {}, diffs: data.diffs || {} };
      renderPreviewPane();
      if (data.secrets_checklist) renderSecrets(data.secrets_checklist);
      const ow = $("overwriteWarn");
      if (data.overwrite_warning) {
        ow.textContent = data.overwrite_warning;
        ow.classList.remove("hidden");
      } else {
        ow.classList.add("hidden");
      }
      const warnings = data.cost_warnings || [];
      const warnBox = $("costWarnings");
      if (warnings.length) {
        warnBox.innerHTML = warnings.map((w) => `<div>⚠ ${w}</div>`).join("");
        warnBox.classList.remove("hidden");
      }
    }

    function startPolling() {
      if (pollTimer) clearInterval(pollTimer);
      pollTimer = setInterval(pollTestStatus, 800);
    }

    async function pollTestStatus() {
      try {
        const data = await api("/api/ci/test/status?offset=" + logOffset);
        if (data.logs?.length) {
          $("terminal").textContent += data.logs.join("\n") + "\n";
          logOffset = data.log_total;
          $("terminal").scrollTop = $("terminal").scrollHeight;
        }
        if (data.status === "running") {
          $("testStatus").textContent = "Test running…";
        } else if (data.status === "passed") {
          lastTestPassed = true;
          $("testStatus").textContent = "Test passed ✓";
          $("next2Btn").disabled = false;
          $("publishBtn").disabled = false;
          clearInterval(pollTimer);
        } else if (data.status === "failed" || data.status === "skipped") {
          $("testStatus").textContent = "Test " + data.status + (data.error ? ": " + data.error : "");
          lastTestPassed = false;
          clearInterval(pollTimer);
        }
      } catch (_) {}
    }

    $("previewBtn").addEventListener("click", () => previewYaml().catch((e) => showAlert(e.message)));
    $("next1Btn").addEventListener("click", async () => {
      try { await previewYaml(); goStep(2); } catch (e) { showAlert(e.message); }
    });
    $("back2Btn").addEventListener("click", () => goStep(1));
    $("back3Btn").addEventListener("click", () => goStep(2));

    $("writeBtn").addEventListener("click", async () => {
      hideAlert();
      try {
        const path = await projectPath();
        const data = await api("/api/ci/write", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ path, spec: collectSpec() }),
        });
        $("writeResult").textContent = "Wrote: " + (data.written || []).join(", ");
        lastTestPassed = false;
        $("next2Btn").disabled = true;
        $("publishBtn").disabled = true;
      } catch (e) { showAlert(e.message); }
    });

    async function runTest(endpoint) {
      hideAlert();
      logOffset = 0;
      $("terminal").textContent = "";
      lastTestPassed = false;
      $("next2Btn").disabled = true;
      $("publishBtn").disabled = true;
      try {
        const path = await projectPath();
        await api(endpoint, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ path, spec: collectSpec() }),
        });
        startPolling();
      } catch (e) { showAlert(e.message); }
    }

    $("nativeTestBtn").addEventListener("click", () => runTest("/api/ci/test/native"));
    $("actTestBtn").addEventListener("click", () => runTest("/api/ci/test/act"));

    $("next2Btn").addEventListener("click", () => {
      if (!lastTestPassed) return showAlert("Run and pass a local test first");
      goStep(3);
    });

    $("publishBtn").addEventListener("click", async () => {
      hideAlert();
      if (!lastTestPassed) return showAlert("Local test must pass before publish");
      $("publishBtn").disabled = true;
      try {
        const path = await projectPath();
        const data = await api("/api/ci/publish", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ path, spec: collectSpec() }),
        });
        $("publishResult").innerHTML = data.pr_url
          ? `Pull request: <a href="${data.pr_url}" target="_blank">${data.pr_url}</a>`
          : "Published";
        const success = $("publishSuccess");
        let html = "Workflow published. Add GitHub secrets before enabling store upload.";
        if (data.readme_badge) {
          html += `<br><br><strong>README badge</strong><pre style="margin-top:0.35rem;background:#050810;padding:0.5rem;border-radius:6px">${data.readme_badge}</pre>`;
        }
        if (data.branch_protection_hint) {
          html += `<br><strong>Branch protection</strong><p style="margin-top:0.35rem">${data.branch_protection_hint}</p>`;
        }
        if (data.ci_setup_path) {
          html += `<br>Teammate guide written to <code>${data.ci_setup_path}</code>`;
        }
        success.innerHTML = html;
        success.classList.remove("hidden");
        $("successBox").textContent = "Publish complete — configure secrets in GitHub Settings.";
        $("successBox").classList.remove("hidden");
      } catch (e) {
        showAlert(e.message);
        $("publishBtn").disabled = false;
      }
    });

    (async () => {
      await rtkSyncProjectInput();
      await loadDetect().catch((e) => showAlert(e.message));
    })();
  </script>
</body>
</html>
''';
