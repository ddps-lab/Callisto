import datetime
from decimal import Decimal
import json
import boto3
import os

TABLE_NAME = os.environ.get('TABLE_NAME', "callisto_jupyter")

CLIENT = boto3.client("dynamodb")
DDB = boto3.resource("dynamodb")
TABLE = DDB.Table(TABLE_NAME)

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
        TABLE.put_item(Item=jupyter);
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
        response = TABLE.get_item(Key={"sub": sub, "created_at": int(created_at)})
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
        response = TABLE.query(KeyConditionExpression=boto3.dynamodb.conditions.Key("sub").eq(auth_sub))
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

def update(auth_sub, uid, payload):
    changeable_keys = ["name", "cpu", "memory", "disk", "status"]
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
        response = TABLE.get_item(Key={"sub": sub, "created_at": int(created_at)})
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
                "message": "Internal server error",
                "error": str(e)
            })
        }

def delete(auth_sub, uid):
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
        response = TABLE.get_item(Key={"sub": sub, "created_at": int(created_at)})
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
                "message": "Internal server error",
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
        auth_sub = event["requestContext"]["authorizer"]["claims"]["sub"];
        if method == "POST":
            res.update(create(auth_sub, req_body))
        elif method == "GET":
            if event.get("pathParameters"):
                res.update(read(auth_sub, event["pathParameters"].get("uid"))) # uid
            else:
                res.update(read_all(auth_sub))
        elif method == "PATCH":
            res.update(update(auth_sub, event["pathParameters"].get("uid"), req_body))
        elif method == "DELETE":
            res.update(delete(auth_sub, event["pathParameters"].get("uid"))) # uid
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
