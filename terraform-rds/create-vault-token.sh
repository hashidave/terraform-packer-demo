#!/bin/bash

echo "This is the token to give to terraform in the VAULT_TOKEN env var"
vault token create   -no-default-policy=true   -policy="general-token-policy" -policy="tf-create-token" -policy="terraform-demos" -orphan=true   -period=168h   -renewable=true   -field=token 
