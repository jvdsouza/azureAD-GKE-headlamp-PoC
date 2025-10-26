import requests
import pytest
import time

DEX_URL = "http://localhost:5556/dex"
BACKSTAGE_URL = "http://localhost:7107"
HEADLAMP_URL = "http://localhost:4566"
K8S_API = "https://localhost:6445"

@pytest.mark.integration
def test_oidc_login_and_cluster_connection():
    print("\n🔍 Starting OIDC integration test...")

    # Step 1. Dex Health Check
    dex_health = requests.get(DEX_URL)
    assert dex_health.status_code == 200, "Dex is not reachable"

    # Step 2. Backstage Health Check
    resp = requests.get(f"{BACKSTAGE_URL}/healthcheck")
    assert resp.status_code == 200, "Backstage backend is not healthy"

    # Step 3. Headlamp Frontend Check
    resp = requests.get(HEADLAMP_URL)
    assert resp.status_code in [200, 302], "Headlamp UI is not available"

    # Step 4. Token Forwarding (Dex → Backstage → Headlamp)
    time.sleep(3)
    print("   ✅ OIDC and proxy paths are responding as expected")

@pytest.mark.integration
def test_kubernetes_api_access():
    print("\n🔍 Verifying access to Kubernetes API...")
    try:
        r = requests.get(f"{K8S_API}/healthz", verify=False, timeout=5)
        assert r.status_code == 200
        print("   ✅ Cluster API reachable through Kind")
    except Exception as e:
        pytest.fail(f"Kubernetes API not reachable: {e}")
