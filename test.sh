#!/bin/bash
terraform validate
if [ $? -eq 0 ]; then
    echo "Terraform validation succeeded"
fi