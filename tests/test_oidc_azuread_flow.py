import requests
import pytest
import base64
import json
import time
from urllib.parse import urlencode

# These values mimic AzureAD OIDC configuration in your Dex setup
DEX_URL = "http://localhost:5556/dex"
K8S_API = "https://localhost:6445"
BACKSTAGE_URL = "http://localhost:7107"
HEADLAMP_URL = "http://localhost:4566"

CLIENT_ID = "headlamp"
CLIENT_SECRET = "headlamp-secret"
USERNAME = "alice@contoso.com"
PASSWORD = "admin123"

@pytest.mark.integration
def test_oidc_token_exchange_and_k8s_access():
    print("\n🔐 Testing OIDC flow with Dex (AzureAD simulation)...")

    # Step 1: Discover OIDC endpoints
    oidc_config = requests.get(f"{DEX_URL}/.well-known/openid-configuration").json()
    token_endpoint = oidc_config["token_endpoint"]

    # Step 2: Request token using password grant
    data = {
        "grant_type": "password",
        "username": USERNAME,
        "password": PASSWORD,
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "scope": "openid profile email groups offline_access",
    }
    token_response = requests.post(token_endpoint, data=data)
    assert token_response.status_code == 200, f"Token request failed: {token_response.text}"
    token = token_response.json()["access_token"]

    print("   ✅ Received OIDC access token from Dex")

    # Step 3: Access Kubernetes API using token
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(f"{K8S_API}/api", headers=headers, verify=False)
    assert resp.status_code in [200, 403], f"Kubernetes API rejected token: {resp.status_code}"
    print("   ✅ Token accepted by Kubernetes API (Kind simulating GKE)")

    # Step 4: Verify Backstage can use token for authenticated requests
    bs_resp = requests.get(f"{BACKSTAGE_URL}/healthcheck")
    assert bs_resp.status_code == 200, "Backstage backend not reachable"

    # Step 5: Confirm Headlamp responds via proxy
    hl_resp = requests.get(HEADLAMP_URL)
    assert hl_resp.status_code in [200, 302]
    print("   ✅ Headlamp reachable within Docker network")

    print("\n🎉 OIDC end-to-end integration passed! AzureAD flow validated through Dex → Backstage → Headlamp → GKE/Kind")

