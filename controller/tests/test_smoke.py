from fastapi.testclient import TestClient

from infrapilot.main import app


client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_parse():
    response = client.post("/intent/parse", json={"prompt": "Deploy a scalable Java app with 2 instances and auto-recovery"})
    assert response.status_code == 200
    body = response.json()
    assert body["parsed_spec"]["deployment"]["instances"] == 2


def test_validate():
    spec = {
        "application": {"type": "java", "artifact_source": "sample-war"},
        "runtime": {"platform": "tomcat", "port": 8080},
        "deployment": {"instances": 2, "auto_recovery": True, "target_group": "tomcat"},
        "health_check": {"path": "/", "interval_seconds": 30},
    }
    response = client.post("/spec/validate", json={"spec": spec})
    assert response.status_code == 200
    assert response.json()["valid"] is True
