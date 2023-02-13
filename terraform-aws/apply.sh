#!/bin/bash
# If you don't taint the worker resource before you apply you'll
# end up with a dead worker. This is because the boundary_worker 
# has a bug in the tf provider that re-deploys it every time
# and this creates a new key which currently isn't being
# updated on the worker ec2.  I do need to fix this logic but
# I have bigger fish to fry right now.
terraform taint aws_instance.boundary-worker
terraform apply -auto-approve
