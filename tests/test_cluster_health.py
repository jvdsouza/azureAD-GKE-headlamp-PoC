# spec/tests/test_cluster_health.py
import subprocess
import pytest

def test_kind_cluster_health():
    """Fail fast if Kind cluster is not healthy."""
    try:
        result = subprocess.run(
            ["kubectl", "get", "nodes", "--no-headers"],
            capture_output=True, text=True, timeout=15
        )
        assert result.returncode == 0, f"Kubectl failed: {result.stderr}"
        assert "Ready" in result.stdout, "Cluster node not ready"
    except FileNotFoundError:
        pytest.fail("kubectl not found in container PATH")
    except subprocess.TimeoutExpired:
        pytest.fail("kubectl command timed out — cluster likely not responding")
