import os
import sys
import json
import time
import zipfile
import subprocess

TABLE_NAME = "WealthData"
ROLE_NAME = "WealthAdvisorLambdaRole"
USER_POOL_NAME = "WealthAdvisorUserPool"
CLIENT_NAME = "WealthAdvisorAppClient"
API_NAME = "WealthAdvisorAPI"
REGION = "ap-south-1"

def run_cmd(args):
    print(f"Executing: {' '.join(args)}")
    res = subprocess.run(args, capture_output=True, text=True)
    if res.returncode != 0:
        raise Exception(f"Command failed:\nStdout: {res.stdout}\nStderr: {res.stderr}")
    return res.stdout.strip()

def run_cmd_json(args):
    out = run_cmd(args)
    return json.loads(out) if out else {}

def run_cmd_no_fail(args):
    res = subprocess.run(args, capture_output=True, text=True)
    return res.returncode, res.stdout.strip(), res.stderr.strip()

def zip_file(src_js, output_zip):
    print(f"Zipping {src_js} -> {output_zip}...")
    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as z:
        z.write(src_js, os.path.basename(src_js))

def main():
    # 0. Get account ID
    print("Fetching AWS account caller identity...")
    caller = run_cmd_json(["aws", "sts", "get-caller-identity"])
    account_id = caller["Account"]
    print(f"AWS Account ID: {account_id}")

    # 1. Create IAM Role for Lambda
    role_arn = None
    code, out, err = run_cmd_no_fail(["aws", "iam", "get-role", "--role-name", ROLE_NAME])
    if code != 0:
        print(f"Creating IAM Role '{ROLE_NAME}'...")
        trust_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "lambda.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
        role_info = run_cmd_json([
            "aws", "iam", "create-role",
            "--role-name", ROLE_NAME,
            "--assume-role-policy-document", json.dumps(trust_policy)
        ])
        role_arn = role_info["Role"]["Arn"]
        
        # Attach basic execution role
        run_cmd([
            "aws", "iam", "attach-role-policy",
            "--role-name", ROLE_NAME,
            "--policy-arn", "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        ])
        
        # Attach inline policy for DynamoDB and SES access
        inline_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "dynamodb:*"
                    ],
                    "Resource": [
                        f"arn:aws:dynamodb:{REGION}:{account_id}:table/{TABLE_NAME}",
                        f"arn:aws:dynamodb:{REGION}:{account_id}:table/{TABLE_NAME}/index/*"
                    ]
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "ses:SendEmail",
                        "ses:SendRawEmail"
                    ],
                    "Resource": "*"
                }
            ]
        }
        run_cmd([
            "aws", "iam", "put-role-policy",
            "--role-name", ROLE_NAME,
            "--policy-name", "WealthAdvisorLambdaPolicy",
            "--policy-document", json.dumps(inline_policy)
        ])
        print("IAM Role created and policies attached.")
        # Sleep to let IAM role propagate
        print("Waiting 10 seconds for IAM Role propagation...")
        time.sleep(10)
    else:
        print(f"IAM Role '{ROLE_NAME}' already exists.")
        role_info = json.loads(out)
        role_arn = role_info["Role"]["Arn"]

    # 2. Create DynamoDB Table
    code, out, err = run_cmd_no_fail(["aws", "dynamodb", "describe-table", "--table-name", TABLE_NAME])
    if code != 0:
        print(f"Creating DynamoDB table '{TABLE_NAME}'...")
        run_cmd([
            "aws", "dynamodb", "create-table",
            "--table-name", TABLE_NAME,
            "--attribute-definitions", "AttributeName=PK,AttributeType=S", "AttributeName=SK,AttributeType=S",
            "--key-schema", "AttributeName=PK,KeyType=HASH", "AttributeName=SK,KeyType=RANGE",
            "--billing-mode", "PAY_PER_REQUEST"
        ])
        print("Waiting for table to become ACTIVE...")
        run_cmd(["aws", "dynamodb", "wait", "table-exists", "--table-name", TABLE_NAME])
        print("DynamoDB Table is active.")
    else:
        print(f"DynamoDB table '{TABLE_NAME}' already exists.")

    # 3. Zip and deploy Lambda triggers
    os.makedirs("infra/lambda/dist", exist_ok=True)
    
    triggers = {
        "define_auth_challenge": "define_auth_challenge.js",
        "create_auth_challenge": "create_auth_challenge.js",
        "verify_auth_challenge_response": "verify_auth_challenge_response.js",
        "wealth_advisor_backend": "backend.js"
    }

    arns = {}
    for name, js_file in triggers.items():
        src_path = f"infra/lambda/{js_file}"
        zip_path = f"infra/lambda/dist/{name}.zip"
        zip_file(src_path, zip_path)
        
        handler_name = f"{name.replace('_', '-')}"
        handler_method = f"{name}.handler" if name != "wealth_advisor_backend" else "backend.handler"
        
        # Deploy lambda
        code, out, err = run_cmd_no_fail(["aws", "lambda", "get-function", "--function-name", handler_name])
        if code == 0:
            print(f"Updating Lambda function code for '{handler_name}'...")
            run_cmd([
                "aws", "lambda", "update-function-code",
                "--function-name", handler_name,
                "--zip-file", f"fileb://{zip_path}"
            ])
            time.sleep(3)
            info = run_cmd_json(["aws", "lambda", "get-function", "--function-name", handler_name])
            arns[name] = info["Configuration"]["FunctionArn"]
        else:
            print(f"Creating Lambda function '{handler_name}'...")
            info = run_cmd_json([
                "aws", "lambda", "create-function",
                "--function-name", handler_name,
                "--runtime", "nodejs20.x",
                "--role", role_arn,
                "--handler", handler_method,
                "--zip-file", f"fileb://{zip_path}",
                "--timeout", "15"
            ])
            arns[name] = info["FunctionArn"]
            time.sleep(3)

    # Configure backend environment variables
    print("Updating backend environment variables...")
    run_cmd([
        "aws", "lambda", "update-function-configuration",
        "--function-name", "wealth-advisor-backend",
        "--environment", f"Variables={{TABLE_NAME={TABLE_NAME}}}"
    ])

    # 4. Create Cognito User Pool
    pools = run_cmd_json(["aws", "cognito-idp", "list-user-pools", "--max-results", "60"])
    pool_id = None
    for p in pools.get("UserPools", []):
        if p["Name"] == USER_POOL_NAME:
            pool_id = p["Id"]
            break

    trigger_config = (
        f"DefineAuthChallenge={arns['define_auth_challenge']},"
        f"CreateAuthChallenge={arns['create_auth_challenge']},"
        f"VerifyAuthChallengeResponse={arns['verify_auth_challenge_response']}"
    )

    if not pool_id:
        print("Creating Cognito User Pool...")
        pool = run_cmd_json([
            "aws", "cognito-idp", "create-user-pool",
            "--pool-name", USER_POOL_NAME,
            "--lambda-config", trigger_config,
            "--auto-verified-attributes", "email",
            "--username-attributes", "email"
        ])
        pool_id = pool["UserPool"]["Id"]
        user_pool_arn = pool["UserPool"]["Arn"]
    else:
        print(f"Cognito User Pool '{USER_POOL_NAME}' already exists ({pool_id}). Updating triggers...")
        pool_desc = run_cmd_json(["aws", "cognito-idp", "describe-user-pool", "--user-pool-id", pool_id])
        user_pool_arn = pool_desc["UserPool"]["Arn"]
        run_cmd([
            "aws", "cognito-idp", "update-user-pool",
            "--user-pool-id", pool_id,
            "--lambda-config", trigger_config,
            "--auto-verified-attributes", "email"
        ])

    # 5. Authorize User Pool to invoke the triggers
    for trigger_name in ["define_auth_challenge", "create_auth_challenge", "verify_auth_challenge_response"]:
        func_name = trigger_name.replace("_", "-")
        print(f"Granting Cognito permission to invoke '{func_name}'...")
        run_cmd_no_fail([
            "aws", "lambda", "remove-permission",
            "--function-name", func_name,
            "--statement-id", "cognito-invoke"
        ])
        run_cmd([
            "aws", "lambda", "add-permission",
            "--function-name", func_name,
            "--statement-id", "cognito-invoke",
            "--action", "lambda:InvokeFunction",
            "--principal", "cognito-idp.amazonaws.com",
            "--source-arn", user_pool_arn
        ])

    # 6. Create User Pool Client
    clients = run_cmd_json(["aws", "cognito-idp", "list-user-pool-clients", "--user-pool-id", pool_id])
    client_id = None
    for c in clients.get("UserPoolClients", []):
        if c["ClientName"] == CLIENT_NAME:
            client_id = c["ClientId"]
            break

    if not client_id:
        print("Creating User Pool Client...")
        client_info = run_cmd_json([
            "aws", "cognito-idp", "create-user-pool-client",
            "--user-pool-id", pool_id,
            "--client-name", CLIENT_NAME,
            "--explicit-auth-flows", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH",
            "--no-generate-secret"
        ])
        client_id = client_info["UserPoolClient"]["ClientId"]
    else:
        print(f"User Pool Client '{CLIENT_NAME}' already exists ({client_id}).")

    # 7. Create API Gateway REST API
    apis = run_cmd_json(["aws", "apigateway", "get-rest-apis"])
    api_id = None
    for api in apis.get("items", []):
        if api["name"] == API_NAME:
            api_id = api["id"]
            break

    if not api_id:
        print("Creating API Gateway REST API...")
        api_info = run_cmd_json([
            "aws", "apigateway", "create-rest-api",
            "--name", API_NAME,
            "--description", "API Gateway for Wealth Advisor monolithic Lambda backend"
        ])
        api_id = api_info["id"]
    else:
        print(f"API Gateway '{API_NAME}' already exists ({api_id}).")

    # Get root resource ID
    resources = run_cmd_json(["aws", "apigateway", "get-resources", "--rest-api-id", api_id])
    root_id = None
    for r in resources.get("items", []):
        if r["path"] == "/":
            root_id = r["id"]
            break

    # Check if proxy resource already exists
    proxy_id = None
    for r in resources.get("items", []):
        if r.get("pathPart") == "{proxy+}":
            proxy_id = r["id"]
            break

    if not proxy_id:
        print("Creating proxy resource /{proxy+}...")
        res_info = run_cmd_json([
            "aws", "apigateway", "create-resource",
            "--rest-api-id", api_id,
            "--parent-id", root_id,
            "--path-part", "{proxy+}"
        ])
        proxy_id = res_info["id"]

    # Setup ANY method and Lambda integrations
    backend_arn = arns["wealth_advisor_backend"]
    integration_uri = f"arn:aws:lambda:ap-south-1:{account_id}:function:wealth-advisor-backend/invocations"
    apigateway_uri = f"arn:aws:apigateway:ap-south-1:lambda:path/2015-03-31/functions/{backend_arn}/invocations"

    for r_id in [root_id, proxy_id]:
        run_cmd_no_fail([
            "aws", "apigateway", "put-method",
            "--rest-api-id", api_id,
            "--resource-id", r_id,
            "--http-method", "ANY",
            "--authorization-type", "NONE"
        ])
        run_cmd([
            "aws", "apigateway", "put-integration",
            "--rest-api-id", api_id,
            "--resource-id", r_id,
            "--http-method", "ANY",
            "--type", "AWS_PROXY",
            "--integration-http-method", "POST",
            "--uri", apigateway_uri
        ])

    # Allow API Gateway to invoke backend Lambda
    print("Granting API Gateway permission to invoke backend Lambda...")
    run_cmd_no_fail([
        "aws", "lambda", "remove-permission",
        "--function-name", "wealth-advisor-backend",
        "--statement-id", "apigateway-invoke"
    ])
    run_cmd([
        "aws", "lambda", "add-permission",
        "--function-name", "wealth-advisor-backend",
        "--statement-id", "apigateway-invoke",
        "--action", "lambda:InvokeFunction",
        "--principal", "apigateway.amazonaws.com",
        "--source-arn", f"arn:aws:execute-api:{REGION}:{account_id}:{api_id}/*/*/*"
    ])

    # Deploy API Gateway stage
    print("Deploying API Gateway stage 'dev'...")
    run_cmd([
        "aws", "apigateway", "create-deployment",
        "--rest-api-id", api_id,
        "--stage-name", "dev"
    ])

    api_url = f"https://{api_id}.execute-api.{REGION}.amazonaws.com/dev"
    print("\n==========================================")
    print("AWS PROVISIONING COMPLETED SUCCESSFULLY!")
    print(f"Cognito User Pool ID: {pool_id}")
    print(f"Cognito Client ID:    {client_id}")
    print(f"API Base URL:         {api_url}")
    print("==========================================\n")

    # 8. Write/Update .env file
    print("Updating .env file with new credentials...")
    env_content = f"""# AWS Credentials & Config
AWS_COGNITO_USER_POOL_ID={pool_id}
AWS_COGNITO_CLIENT_ID={client_id}
AWS_API_BASE_URL={api_url}

# Direct Gemini Access (direct integration fallback)
# Add your Gemini Key below:
AI_API_KEY={os.getenv('AI_API_KEY', '')}
"""
    with open(".env", "w") as f:
        f.write(env_content)
    print(".env file updated.")

if __name__ == "__main__":
    main()
