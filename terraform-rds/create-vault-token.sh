#!/bin/bash
echo "This is the token to hand off to boundary in the BOUNDARY_VAULT_TOKEN var"
vault token create   -no-default-policy=true   -policy="boundary-controller"  -orphan=true   -period=168h   -renewable=true   -field=token

echo "This is the token to give to terraform in the VAULT_TOKEN env var"
vault token create   -no-default-policy=true   -policy="boundary-controller" -policy="create-db-mount" -orphan=true   -period=168h   -renewable=true   -field=token
