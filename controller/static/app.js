const state = { latestVerify: null };

async function getJson(url, options = {}) {
  const response = await fetch(url, options);
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`${response.status} ${response.statusText}: ${text}`);
  }
  return response.json();
}

function setText(id, value) {
  const el = document.getElementById(id);
  if (el) el.textContent = value;
}

function setPre(id, value) {
  const el = document.getElementById(id);
  if (el) el.textContent = typeof value === "string" ? value : JSON.stringify(value, null, 2);
}

function renderHistoryTable(bodyId, rows, mapper) {
  const body = document.getElementById(bodyId);
  body.innerHTML = "";
  if (!rows || rows.length === 0) {
    body.innerHTML = `<tr><td colspan="4">No records found</td></tr>`;
    return;
  }
  rows.forEach((row) => {
    const values = mapper(row);
    const tr = document.createElement("tr");
    tr.innerHTML = values.map(v => `<td>${v ?? "—"}</td>`).join("");
    body.appendChild(tr);
  });
}

async function loadHealth() {
  try {
    const data = await getJson("/health");
    setText("api-status", data.status || "ok");
  } catch (err) {
    setText("api-status", `error: ${err.message}`);
  }
}

async function loadLatestDeployment() {
  try {
    const data = await getJson("/deploy/latest");
    setText("latest-deploy-status", data.status || "—");
    setText("latest-deploy-instances", data?.spec?.deployment?.instances ?? "—");
    setText("latest-deploy-id", data.deployment_id || "—");
    setPre("latest-deploy-record", data);
  } catch (err) {
    setText("latest-deploy-status", "not found");
    setPre("latest-deploy-record", String(err));
  }
}

async function loadLatestRecovery() {
  try {
    const data = await getJson("/deploy/recover/latest");
    setText("latest-recover-status", data.status || "—");
    const targets = Array.isArray(data.instances) ? data.instances.join(", ") : "—";
    setText("latest-recover-targets", targets);
    setText("latest-recover-id", data.recovery_id || "—");
    setPre("latest-recover-record", data);
  } catch (err) {
    setText("latest-recover-status", "not found");
    setPre("latest-recover-record", String(err));
  }
}

async function loadDeployHistory() {
  try {
    const rows = await getJson("/deploy/history");
    renderHistoryTable("deploy-history-body", rows, (row) => [
      row.deployment_id || "—",
      row.status || "—",
      row?.spec?.deployment?.instances ?? "—",
      row.started_at || "—",
    ]);
  } catch {
    renderHistoryTable("deploy-history-body", [], () => []);
  }
}

async function loadRecoveryHistory() {
  try {
    const rows = await getJson("/deploy/recover/history");
    renderHistoryTable("recover-history-body", rows, (row) => [
      row.recovery_id || "—",
      row.status || "—",
      Array.isArray(row.instances) ? row.instances.join(", ") : "—",
      row.started_at || "—",
    ]);
  } catch {
    renderHistoryTable("recover-history-body", [], () => []);
  }
}

function updateVerifyWidgets(data) {
  state.latestVerify = data;
  setText("latest-verify-status", data.status || "—");
  setText("latest-verify-healthy", Array.isArray(data.healthy_instances) ? data.healthy_instances.length : 0);
  setText("latest-verify-unhealthy", Array.isArray(data.unhealthy_instances) ? data.unhealthy_instances.length : 0);
  setPre("latest-verify-record", data);
}

async function runVerify() {
  const payload = { expected_instances: 5, health_path: "/", timeout_seconds: 10 };
  const data = await getJson("/deploy/verify", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  updateVerifyWidgets(data);
  setPre("action-output", data);
}

async function runRecover(instanceName = "app3") {
  const payload = { instances: [instanceName], health_path: "/", timeout_seconds: 20 };
  const data = await getJson("/deploy/recover", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  setPre("action-output", data);
  await refreshAll();
}

async function runExecute(prompt, dryRun = false) {
  const payload = { prompt, dry_run: dryRun };
  const data = await getJson("/deploy/execute", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  setPre("action-output", data);
  await refreshAll();
}

async function runPlan(prompt) {
  const payload = { prompt };
  const data = await getJson("/deploy/plan", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  setPre("action-output", data);
}

async function refreshAll() {
  await Promise.all([
    loadHealth(),
    loadLatestDeployment(),
    loadLatestRecovery(),
    loadDeployHistory(),
    loadRecoveryHistory(),
  ]);
}

document.getElementById("refresh-all").addEventListener("click", async () => {
  await refreshAll();
});

document.querySelectorAll("button[data-action]").forEach((button) => {
  button.addEventListener("click", async () => {
    const action = button.dataset.action;
    const prompt = document.getElementById("custom-prompt").value;
    try {
      if (action === "deploy1") {
        await runExecute("Deploy a scalable Java app with 1 instance and auto-recovery", false);
      } else if (action === "deploy5") {
        await runExecute("Deploy a scalable Java app with 5 instances and auto-recovery", false);
      } else if (action === "verify") {
        await runVerify();
      } else if (action === "recover-app3") {
        await runRecover("app3");
      } else if (action === "plan") {
        await runPlan(prompt);
      } else if (action === "execute") {
        await runExecute(prompt, false);
      }
    } catch (err) {
      setPre("action-output", String(err));
    }
  });
});

refreshAll();
