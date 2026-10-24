#!/usr/bin/env python3
import os

from kubernetes import client, config


config.load_kube_config(os.environ["KUBECONFIG"])
request = client.AuthenticationV1TokenRequest(
    spec=client.V1TokenRequestSpec(expiration_seconds=3600)
)
response = client.CoreV1Api().create_namespaced_service_account_token(
    name="headlamp-viewer",
    namespace="headlamp",
    body=request,
)
print(response.status.token)
