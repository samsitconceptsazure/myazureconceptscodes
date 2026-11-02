#!/usr/bin/env bash
set -euo pipefail
REGION="${AWS_REGION:-us-east-1}"; STACK="${STACK_NAME:-bedrock-chatbot-lab}"
BUCKET=$(aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" --query "Stacks[0].Outputs[?OutputKey=='Bucket'].OutputValue" --output text)
aws s3 rm "s3://$BUCKET" --recursive --region "$REGION"
aws cloudformation delete-stack --region "$REGION" --stack-name "$STACK"
aws cloudformation wait stack-delete-complete --region "$REGION" --stack-name "$STACK"
echo 'Stack deleted.'
