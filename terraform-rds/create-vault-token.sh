#!/bin/bash

vault token create   -no-default-policy=true   -policy="boundary-controller"  -orphan=true   -period=168h   -renewable=true   -field=token
