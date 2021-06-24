#!/bin/bash

amazon-linux-extras install epel
curl --proto "https" -o "/tmp/ecs-anywhere-install.sh" "https://amazon-ecs-agent.s3.amazonaws.com/ecs-anywhere-install-latest.sh" && bash /tmp/ecs-anywhere-install.sh --region "eu-central-1" --cluster "${TF_CLUSTER_NAME}" --activation-id "${TF_ACT_ID}" --activation-code "${TF_ACT_CODE}"