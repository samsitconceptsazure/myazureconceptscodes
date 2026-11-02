# AWS Bedrock Website Chatbot Lab

## Requirements
AWS CLI v2 configured, AWS permissions to create CloudFormation, IAM, Lambda, API Gateway and S3, `zip`, AWS Bedrock model access/entitlement and regional availability. Choose a supported region and model. Default: us-east-1 / amazon.nova-lite-v1:0. Costs apply. CloudFormation provisions a publicly readable S3 bucket and unauthenticated HTTP API; **training only**, not production.

## Deploy (AWS CloudShell)
1. Upload this ZIP to AWS CloudShell and extract it: `unzip aws-bedrock-chatbot.zip && cd aws-bedrock-chatbot`
2. Check account: `aws sts get-caller-identity`
3. Check available Bedrock models in the selected region and that your account can invoke the selected model. If necessary set `MODEL_ID` to an eligible Converse-compatible model (including an inference profile ID when required). Check quotas, model terms and access in the Bedrock console.
4. Run: `export AWS_REGION=us-east-1; bash scripts/deploy.sh`
5. Open the Website URL printed by the script. Browser sends requests to the API URL.

## Test API
`API=$(aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name bedrock-chatbot-lab --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text)`

`curl -i -X POST "$API" -H 'content-type: application/json' -d '{"message":"Explain EC2 versus Lambda","history":[]}'`

Expected: HTTP 200 with JSON containing `answer`. Check a second question in the browser for contextual conversation.

## AWS Console verification
1. CloudFormation > Stacks > bedrock-chatbot-lab: status CREATE_COMPLETE / UPDATE_COMPLETE and outputs.
2. S3 > bucket in stack outputs > Objects: `index.html`, `style.css`, `app.js`, `config.js`. Properties > Static website hosting: enabled.
3. API Gateway > APIs > HTTP API: POST /chat route, Lambda integration and CORS.
4. Lambda > function in outputs: Python 3.12, 30 second timeout, MODEL_ID environment variable, CloudWatch logging.
5. Bedrock > Model catalog: selected model and region availability/entitlements. Invoke test through website or curl.
6. CloudWatch > Log groups > /aws/lambda/<function-name>: inspect logs and errors after invoking API.
7. IAM > Roles: Lambda execution role includes CloudWatch logs and Bedrock invocation permission.
8. Browser developer tools > Network: POST /chat should return HTTP 200; inspect JSON answer. Check browser console for errors.

## Negative tests
- Empty message: expect HTTP 400.
- Very long message (over 2000 chars): expect HTTP 400.
- Incorrect model ID or denied model access: expect HTTP 502 and a CloudWatch error.
- Open browser DevTools and confirm no API keys or AWS secrets are in the frontend.

## Troubleshooting
- 502: inspect CloudWatch logs; model may not be available, accessible or supported in this region. Some models require an inference profile rather than a direct model ID. If using inference profiles, adjust IAM resource scope as needed.
- CORS: verify API Gateway CORS settings and config.js API URL.
- 403 on website: check S3 Block Public Access account settings and bucket policy. Do not disable account-wide security for a lab; use CloudFront with private S3 instead if public bucket access is blocked.
- S3 website is HTTP only: use CloudFront + OAC + HTTPS for production.
- 429/throttling: check Bedrock quotas and retry later.

## Security and costs
This deliberately simplified lab has an unauthenticated public API that can incur charges from anyone using it. Delete immediately after practice, monitor AWS Budgets, and avoid sharing the endpoint. For real deployment add Cognito/JWT authorization, AWS WAF, throttling/quotas, restrictive CORS, CloudFront HTTPS with private S3, least-privilege model permissions, input safeguards and usage monitoring. CloudWatch, Bedrock, Lambda, API Gateway, and optional hosting charges may apply.

## Cleanup
`bash scripts/destroy.sh`

Verify CloudFormation stack deletion, empty/deleted S3 bucket and removed Lambda/API. CloudWatch log groups can remain; delete the lab's log group manually if no longer required.
