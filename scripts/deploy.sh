#!/usr/bin/env bash
set -euo pipefail
REGION="${AWS_REGION:-us-east-1}"
STACK="${STACK_NAME:-bedrock-chatbot-lab}"
MODEL="${MODEL_ID:-amazon.nova-lite-v1:0}"
cd "$(dirname "$0")/.."
aws cloudformation deploy --region "$REGION" --stack-name "$STACK" --template-file template.yaml --capabilities CAPABILITY_IAM --parameter-overrides "ModelId=$MODEL"
get_output(){ aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text; }
BUCKET="$(get_output Bucket)"
FUNCTION="$(get_output FunctionName)"
API="$(get_output ApiUrl)"
ZIP="$(mktemp --suffix=.zip)"
(cd lambda && zip -q "$ZIP" app.py)
aws lambda update-function-code --region "$REGION" --function-name "$FUNCTION" --zip-file "fileb://$ZIP" >/dev/null
aws lambda wait function-updated --region "$REGION" --function-name "$FUNCTION"
rm -f "$ZIP"
printf 'window.CHAT_API_URL = "%s";\n' "$API" > frontend/config.js
aws s3 sync frontend/ "s3://$BUCKET/" --region "$REGION"
aws s3 website "s3://$BUCKET" --index-document index.html --region "$REGION"
echo "API: $API"
echo "Website: $(get_output WebsiteUrl)"
echo 'WARNING: Public S3 HTTP demo, public unauthenticated API. Not for production.'
