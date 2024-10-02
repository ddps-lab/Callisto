import boto3
import json
iam_client = boto3.client('iam')

def create_iam_role(role_name, policy_document):
    response = iam_client.create_role(
        RoleName=role_name,
        AssumeRolePolicyDocument=json.dumps(policy_document)
    )
    return response['Role']['Arn'], response['Role']['RoleName']

def delete_iam_role(role_name):
    iam_client.delete_role(
        RoleName=role_name
    )

def attach_policy_to_role(role_name, policy_arn):
    iam_client.attach_role_policy(
        RoleName=role_name,
        PolicyArn=policy_arn
    )

def detach_policy_from_role(role_name, policy_arn):
    iam_client.detach_role_policy(
        RoleName=role_name,
        PolicyArn=policy_arn
    )

def generate_oidc_assume_role_policy(oidc_provider, oidc_provider_arn, namespace, service_account_name):
    return {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Federated": oidc_provider_arn
                },
                "Action": "sts:AssumeRoleWithWebIdentity",
                "Condition": {
                    "StringEquals": {
                        f"{oidc_provider}:sub": f"system:serviceaccount:{namespace}:{service_account_name}",
                        f"{oidc_provider}:aud": "sts.amazonaws.com"
                    }
                }
            }
        ]
    }

def create_iam_policy(policy_name, policy_document):
    response = iam_client.create_policy(
        PolicyName=policy_name,
        PolicyDocument=json.dumps(policy_document)
    )
    return response['Policy']['Arn']

def delete_iam_policy(policy_arn):
    iam_client.delete_policy(
        PolicyArn=policy_arn
    )

def generate_dynamodb_entry_update_policy_document(table_arn, uid):
    return {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "dynamodb:GetItem",
                    "dynamodb:UpdateItem",
                ],
                "Resource": table_arn,
                "Condition": {
                    "ForAllValues:StringEquals": {
                        "dynamodb:LeadingKeys": f"{uid}"
                    }
                }
            }
        ]
    }
