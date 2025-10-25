import requests

def test_authentication_claims(oidc_token):
    assert oidc_token["iss"].startswith("https://login.microsoftonline.com/")
    assert "email" in oidc_token
    assert oidc_token["aud"] == "<GKE_CLIENT_ID>"

def test_dex_oidc_endpoint():
    """Simple check: Dex OIDC discovery endpoint is reachable."""
    resp = requests.get("http://dex:5556/dex/.well-known/openid-configuration")
    assert resp.status_code == 200
    assert "issuer" in resp.json()
