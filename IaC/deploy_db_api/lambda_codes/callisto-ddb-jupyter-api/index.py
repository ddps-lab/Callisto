import datetime
from decimal import Decimal
import json
import boto3
from botocore.exceptions import ClientError
import os
import subprocess
from kubernetes import client, config, utils
from kubernetes.utils import FailToCreateError
from kubernetes.client.rest import ApiException
from jinja2 import Environment, FileSystemLoader
import tempfile
from iam_util import *

sts_client = boto3.client('sts')
cognito_client = boto3.client('cognito-idp')
response = sts_client.get_caller_identity()

ACCOUNT_ID = response['Account']
EKS_CLUSTER_NAME = os.getenv('EKS_CLUSTER_NAME')
REGION = os.getenv("REGION")
ECR_URI = os.getenv("ECR_URI")
DB_API_URL = os.getenv("DB_API_URL")
ROUTE53_DOMAIN = os.getenv("ROUTE53_DOMAIN")
OIDC_PROVIDER = os.getenv("OIDC_PROVIDER")
OIDC_PROVIDER_ARN = os.getenv("OIDC_PROVIDER_ARN")
TABLE_ARN = os.getenv("TABLE_ARN")

# update .kubeconfig file
subprocess.run([
    "aws", "eks", "update-kubeconfig",
    "--name", EKS_CLUSTER_NAME,
    "--region", REGION,
    "--kubeconfig", '/tmp/kubeconfig'
])
config.load_kube_config(config_file='/tmp/kubeconfig')
v1 = client.CoreV1Api()
apps_v1 = client.AppsV1Api()
netwokring_v1 = client.NetworkingV1Api()
rbac_v1 = client.RbacAuthorizationV1Api()
api_client = client.ApiClient()

TABLE_NAME = os.environ.get('TABLE_NAME', "callisto_jupyter")

CLIENT = boto3.client("dynamodb")
DDB = boto3.resource("dynamodb")
TABLE = DDB.Table(TABLE_NAME)

def get_item_count(table_name, partition_key, partition_value):
    table = DDB.Table(table_name)
    response = table.query(
        KeyConditionExpression=boto3.dynamodb.conditions.Key(partition_key).eq(partition_value)
    )
    item_count = response['Count']
    return item_count

def render_template(template_file, **kwargs):
    env = Environment(loader=FileSystemLoader("."))
    template = env.get_template(template_file)
    return template.render(**kwargs)


def create(auth_sub, payload):
    necessary_keys = ["name", "cpu", "memory", "disk"]
    if not all(key in payload for key in necessary_keys):
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": "Missing necessary keys. 4 keys(name, cpu, memory, disk) are required."
            })
        }
    # if payload["sub"] != auth_sub:
    #     return {
    #         "statusCode": 403,
    #         "body": json.dumps({
    #             "message": "Forbidden"
    #         })
    #     }
    created_at = int(datetime.datetime.now().timestamp() * 1000)
    uid = f"{auth_sub}@{created_at}"
    jupyter = {
        "sub": auth_sub,
        "created_at": created_at,
        "name": payload["name"],
        "cpu": payload["cpu"],
        "memory": payload["memory"],
        "endpoint_url": "-",
        "disk": payload["disk"],
        "status": "pending",
        "endpoint_url": None,
        "inactivity_time": 15,
    }
    try:
        try:
            policy_arn = create_iam_policy(f"callisto-{auth_sub}-{created_at}-pol", generate_dynamodb_entry_update_policy_document(TABLE_ARN, auth_sub))
            iam_role_arn, iam_role_name = create_iam_role(f"callisto-{auth_sub}-{created_at}-role", generate_oidc_assume_role_policy(OIDC_PROVIDER, OIDC_PROVIDER_ARN, auth_sub, f"{auth_sub}-{created_at}-sa"))
            attach_policy_to_role(iam_role_name, policy_arn)
        except ClientError as e:
            if e.response['Error']['Code'] == 'EntityAlreadyExists':
                iam_role_arn = f"arn:aws:iam::{ACCOUNT_ID}:role/callisto-{auth_sub}-{created_at}-role"
                iam_role_name = f"callisto-{auth_sub}-{created_at}-role"
            else:
                raise e
        variables = {
            'user_namespace': auth_sub,
            'endpoint_uid': f"{auth_sub}-{created_at}",
            'cpu_core': int(payload["cpu"]) * 1000,
            'memory': int(payload["memory"]) * 1024,
            'storage': payload["disk"],
            'ecr_uri': ECR_URI,
            'inactivity_time': 15,
            'iam_role_arn': iam_role_arn,
            "table_name": TABLE_NAME,
            "created_at": created_at,
            "region": REGION
        }
        rendered_yaml = render_template("jupyter_template.yaml", **variables)
        with tempfile.NamedTemporaryFile(delete=True, mode='w') as temp_yaml_file:
            temp_yaml_file.write(rendered_yaml)
            temp_yaml_file.flush()
            jupyter["endpoint_url"] = f"https://{ROUTE53_DOMAIN}/api/jupyter-access/{auth_sub}-{created_at}"
            try:
                utils.create_from_yaml(api_client, temp_yaml_file.name, namespace=auth_sub)
            except FailToCreateError as e:
                for cause in e.api_exceptions:
                    if isinstance(cause, ApiException) and cause.status == 409:
                        print("Namespace resource already exists: ", cause)
                    else:
                        raise e
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error (Kubernetes Error)",
                "error": str(e)
            })
        }
    try:
        TABLE.put_item(Item=jupyter)
        return {
            "statusCode": 201,
            "body": json.dumps({
                "message": "Jupyter created",
                "jupyter": jupyter
            })
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error",
                "error": str(e)
            })
        }


def read(auth_sub, uid):
    sub, created_at = uid.split("@", 1) if "@" in uid else (uid, None)
    if not sub or not created_at:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": "Missing uid"
            })
        }
    if sub != auth_sub:
        return {
            "statusCode": 403,
            "body": json.dumps({
                "message": "Forbidden"
            })
        }
    try:
        response = TABLE.get_item(
            Key={"sub": sub, "created_at": int(created_at)})
        if "Item" not in response:
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "message": "Jupyter not found"
                })
            }

        return {
            "statusCode": 200,
            "body": json.dumps(response["Item"], default=lambda o: int(o) if isinstance(o, Decimal) and o % 1 == 0 else float(o))
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error",
                "error": str(e)
            })
        }


def read_all(auth_sub):
    try:
        response = TABLE.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key("sub").eq(auth_sub))
        return {
            "statusCode": 200,
            "body": json.dumps(response["Items"], default=lambda o: int(o) if isinstance(o, Decimal) and o % 1 == 0 else float(o))
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error",
                "error": str(e)
            })
        }

ATTRIBUTES_TO_INCLUDE = {"email", "family_name", "name", "nickname"}

def get_cognito_user_attributes(sub, user_pool_id):
    try:
        response = cognito_client.admin_get_user(
            UserPoolId=user_pool_id,
            Username=sub
        )
        attributes = {attr["Name"]: attr["Value"] for attr in response["UserAttributes"] if attr["Name"] in ATTRIBUTES_TO_INCLUDE}
        return attributes if attributes else None
    except Exception as e:
        print(f"Error fetching user {sub}: {e}")
        return None

def read_all_admin(profile, user_pool_id):
    if profile != "admin":
        return {
            "statusCode": 403,
            "body": json.dumps({
                "message": "Forbidden"
            })
        }
    try:
        response = TABLE.scan()

        for item in response["Items"]:
            user_attributes = get_cognito_user_attributes(item["sub"], user_pool_id)
            if user_attributes:
                item["username"] = f"{user_attributes['name']} {user_attributes['family_name']}"
                item["email"] = user_attributes["email"]
                item["nickname"] = user_attributes["nickname"]

        return {
            "statusCode": 200,
            "body": json.dumps(response["Items"], default=lambda o: int(o) if isinstance(o, Decimal) and o % 1 == 0 else float(o))
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error",
                "error": str(e)
            })
        }

def patch_deployment_resources(namespace, created_at, cpu=None, memory=None, disk=None):
    # 기존 Deployment 가져오기
    deployment = apps_v1.read_namespaced_deployment(name=f"deployment-{namespace}-{created_at}", namespace=namespace)

    # 현재 리소스 가져오기
    containers = deployment.spec.template.spec.containers
    if not containers:
        raise ValueError("Deployment does not have any containers defined.")

    container = containers[0]  # 첫 번째 컨테이너를 대상으로 변경

    # 변경할 리소스 설정
    new_resources = container.resources.to_dict()

    if cpu:
        new_resources["limits"]["cpu"] = f"{cpu}m"
        new_resources["requests"]["cpu"] = f"{cpu}m"
    if memory:
        new_resources["limits"]["memory"] = f"{memory}Mi"
        new_resources["requests"]["memory"] = f"{memory}Mi"
    if disk:
        pvc = v1.read_namespaced_persistent_volume_claim(name=f"{namespace}-{created_at}-pvc", namespace=namespace)

        current_size = pvc.spec.resources.requests["storage"]
        current_size_value = int(current_size.strip("Gi"))

        if disk < current_size_value:
            raise ValueError("Disk size cannot be decreased.")
        
        patch_body = {
            "spec": {
                "resources": {
                    "requests": {"storage": f"{disk}Gi"}
                }
            }
        }

        v1.patch_namespaced_persistent_volume_claim(
            name=f"{namespace}-{created_at}-pvc",
            namespace=namespace,
            body=patch_body
        )

    # 새로운 리소스 적용
    container.resources = client.V1ResourceRequirements(
        limits=new_resources["limits"],
        requests=new_resources["requests"]
    )

    # Deployment 업데이트
    apps_v1.patch_namespaced_deployment(
        name=f"deployment-{namespace}-{created_at}",
        namespace=namespace,
        body={"spec": {"template": {"spec": {"containers": [container]}}}}
    )
    print(f"Deployment {f"deployment-{namespace}-{created_at}"} updated with new resources.")

def update(auth_sub, uid, payload, profile):
    changeable_keys = ["name", "cpu", "memory", "disk", "status"]
    sub, created_at = uid.split("@", 1) if "@" in uid else (uid, None)
    if not sub or not created_at:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": "Missing uid"
            })
        }
    if sub != auth_sub and profile != "admin":
        return {
            "statusCode": 403,
            "body": json.dumps({
                "message": "Forbidden"
            })
        }

    try:
        if "status" in payload:
            if payload["status"] == "start":
                apps_v1.patch_namespaced_deployment_scale(
                    name=f"deployment-{sub}-{created_at}", namespace=sub, body={"spec": {"replicas": 1}})
                payload["status"] = "pending"
        elif "cpu" in payload and "memory" in payload and "disk" in payload:
            patch_deployment_resources(sub, created_at, payload["cpu"] * 1000, payload["memory"] * 1024, payload["disk"])
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error (Kubernetes Error)",
                "error": str(e)
            })
        }
    try:
        response = TABLE.get_item(
            Key={"sub": sub, "created_at": int(created_at)})
        if "Item" not in response:
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "message": "Jupyter not found"
                })
            }

        jupyter = response["Item"]
        for key in changeable_keys:
            if key in payload and payload[key]:
                # if status, cpu, memory, disk is changed
                jupyter[key] = payload[key]
        TABLE.put_item(Item=jupyter)
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Jupyter updated",
                "jupyter": json.dumps(jupyter, default=lambda o: int(o) if isinstance(o, Decimal) and o % 1 == 0 else float(o))
            })
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error (DB Error)",
                "error": str(e)
            })
        }


def delete(auth_sub, uid, profile):
    sub, created_at = uid.split("@", 1) if "@" in uid else (uid, None)
    if not sub or not created_at:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": "Missing uid"
            })
        }
    if sub != auth_sub and profile != "admin":
        return {
            "statusCode": 403,
            "body": json.dumps({
                "message": "Forbidden"
            })
        }
    try:
        if get_item_count(TABLE_NAME, "sub", sub) == 1:
            detach_policy_from_role(f"callisto-{sub}-{created_at}-role", f"arn:aws:iam::{ACCOUNT_ID}:policy/callisto-{sub}-{created_at}-pol")
            delete_iam_role(f"callisto-{sub}-{created_at}-role")
            delete_iam_policy(f"arn:aws:iam::{ACCOUNT_ID}:policy/callisto-{sub}-{created_at}-pol")
        v1.delete_namespaced_service(f"service-{sub}-{created_at}", sub)
        apps_v1.delete_namespaced_deployment(
            f"deployment-{sub}-{created_at}", sub)
        v1.delete_namespaced_persistent_volume_claim(
            f"{sub}-{created_at}-pvc", sub)
        netwokring_v1.delete_namespaced_ingress(
            f"ingress-{sub}-{created_at}", sub)
        v1.delete_namespaced_service_account(f"{sub}-{created_at}-sa", sub)
        rbac_v1.delete_namespaced_role(
            f"{sub}-{created_at}-scale-deployment-permission", sub)
        rbac_v1.delete_namespaced_role_binding(
            f"{sub}-{created_at}-scale-deployment-permission-binding", sub)
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error (Kubernetes Error)",
                "error": str(e)
            })
        }
    try:
        response = TABLE.get_item(
            Key={"sub": sub, "created_at": int(created_at)})
        if "Item" not in response:
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "message": "Jupyter not found"
                })
            }

        jupyter = response["Item"]
        TABLE.delete_item(Key={"sub": sub, "created_at": int(created_at)})
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Jupyter deleted",
                "jupyter": json.dumps(jupyter, default=lambda o: int(o) if isinstance(o, Decimal) and o % 1 == 0 else float(o))
            })
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error (DB Error)",
                "error": str(e)
            })
        }


def lambda_handler(event, context):
    method = event.get("httpMethod")
    req_body = json.loads(event.get("body")) if event.get("body") else {}
    res = {
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "statusCode": 500,
        "body": json.dumps({
            "message": "Internal server error",
            "error": "Route not found"
        }),
    }
    try:
        auth_sub = event["requestContext"]["authorizer"]["claims"]["sub"]
        if method == "POST":
            res.update(create(auth_sub, req_body))
        elif method == "GET":
            if event.get("pathParameters"):
                res.update(
                    read(auth_sub, event["pathParameters"].get("uid")))  # uid
            else:
                if event.get("resource") == "/api/jupyter/admin":
                    res.update(read_all_admin(event["requestContext"]["authorizer"]["claims"]["profile"], event["requestContext"]["authorizer"]["claims"]["iss"].split("/")[3]))
                else:
                    res.update(read_all(auth_sub))
        elif method == "PATCH":
            res.update(
                update(auth_sub, event["pathParameters"].get("uid"), req_body, event["requestContext"]["authorizer"]["claims"]["profile"]))
        elif method == "DELETE":
            res.update(
                delete(auth_sub, event["pathParameters"].get("uid"), event["requestContext"]["authorizer"]["claims"]["profile"]))
        else:
            res.update({
                "statusCode": 405,
                "body": json.dumps({
                    "message": "Method not allowed"
                })
            })
    except KeyError:
        pass

    return res
