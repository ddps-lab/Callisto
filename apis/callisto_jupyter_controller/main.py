import subprocess
import requests
import os
import json
import time
import uuid

kubectl = '/var/task/kubectl'
kubeconfig = '/tmp/kubeconfig'

eks_cluster_name = os.getenv('EKS_CLUSTER_NAME')
region = os.getenv("REGION")
ecr_uri = os.getenv("ECR_URI")
db_api_url = os.getenv("DB_API_URL")

# get eks cluster kubernetes configuration by aws cli
result_get_kubeconfig = subprocess.run([
    "aws", "eks", "update-kubeconfig",
    "--name", eks_cluster_name,
    "--region", region,
    "--kubeconfig", kubeconfig
])

def generate_yaml(user_namespace, endpoint_uid, cpu_core, memory, storage):
    content = f"""---
apiVersion: v1
kind: Namespace
metadata:
  name: {user_namespace}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {endpoint_uid}-pvc
  namespace: {user_namespace}
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: {storage}Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: {user_namespace}
  name: deployment-{endpoint_uid}
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: app-{endpoint_uid}
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app-{endpoint_uid}
    spec:
      securityContext:
        fsGroup: 1000
      containers:
      - image: {ecr_uri}/callisto-jupyter-base-notebook:latest
        imagePullPolicy: Always
        name: app-{endpoint_uid}
        command: ["start-notebook.sh", "--NotebookApp.token=''", "--NotebookApp.password=''", "--NotebookApp.base_url=/{endpoint_uid}"]
        ports:
        - containerPort: 8888
        env:
        resources:
            requests:
                cpu: {int(cpu_core)*1000}m
                memory: {memory}M
            limits:
                cpu: {int(cpu_core)*1000}m
                memory: {memory}M
        volumeMounts:
        - mountPath: /home/jovyan/work
          name: {endpoint_uid}-storage
      volumes:
      - name: {endpoint_uid}-storage
        persistentVolumeClaim:
          claimName: {endpoint_uid}-pvc
      nodeSelector:
        karpenter.sh/nodepool: jupyter-nodepool
---
apiVersion: v1
kind: Service
metadata:
  namespace: {user_namespace}
  name: service-{endpoint_uid}
spec:
  ports:
    - port: 8888
      targetPort: 8888
      protocol: TCP
  type: ClusterIP
  selector:
    app.kubernetes.io/name: app-{endpoint_uid}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: {user_namespace}
  name: ingress-{endpoint_uid}
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
        - path: /{endpoint_uid}
          pathType: Prefix
          backend:
            service:
              name: service-{endpoint_uid}
              port:
                number: 8888
"""

    filepath = f"/tmp/{endpoint_uid}.yaml"
    with open(filepath, 'w') as f:
        f.write(content)

    return filepath

def apply_yaml(user_uid, endpoint_uid, cpu_core, memory, storage):
    filename = generate_yaml(user_uid, endpoint_uid, cpu_core, memory, storage)
    result = subprocess.run([
        kubectl, "apply", "-f", filename, "--kubeconfig", kubeconfig
    ])
    if result.returncode != 0: print("create resource returncode != 0")
    return result.returncode

def delete_resource(user_namespace, endpoint_uid):
    deployment_name = f"deployment-{endpoint_uid}"
    service_name = f"service-{endpoint_uid}"
    ingress_name = f"ingress-{endpoint_uid}"
    storage_name = f"{endpoint_uid}-pvc"
    ingress_result = subprocess.run([
        kubectl, "-n", user_namespace, "delete",  "ingress", ingress_name, "--kubeconfig", kubeconfig
    ])
    service_result = subprocess.run([
        kubectl, "-n", user_namespace, "delete",  "service", service_name, "--kubeconfig", kubeconfig
    ])
    deployment_result = subprocess.run([
        kubectl, "-n", user_namespace, "delete",  "deployment", deployment_name, "--kubeconfig", kubeconfig
    ])
    pvc_result = subprocess.run([
        kubectl, "-n", user_namespace, "delete", "pvc", storage_name, "--kubeconfig", kubeconfig
    ])
    result = 0
    if ingress_result.returncode != 0 or service_result.returncode != 0 or deployment_result.returncode != 0 or pvc_result.returncode != 0:
        result = 1
        print("delete resource returncode != 0")
    return result

def handler(event, context):
    body = json.loads(event.get("body", "{}"))
    user_uid = body.get("user").lower()
    endpoint_name = body.get("endpoint_name").lower()
    action = body.get("action")

    if action == "create":
        cpu_core = body.get("cpu_core").lower()
        memory = body.get("memory")
        endpoint_uid = str(uuid.uuid4())
        storage = body.get("storage").lower()
        result = apply_yaml(user_uid, endpoint_uid, cpu_core, memory, storage)

        cmd = "{} get svc -A --kubeconfig {} | grep ingress-nginx | grep LoadBalancer".format(kubectl, kubeconfig)
        endpoint_url = subprocess.run(cmd, capture_output=True, shell=True).stdout.decode('utf-8').strip().split()[4]
        print(f"endpoint_url: {endpoint_url}")
        post_data = {
            "uid": endpoint_uid,
            "user": user_uid,
            "name": endpoint_name,
            "cpu_core": cpu_core,
            "memory": memory,
            "storage": storage,
            "endpoint": f"http://{endpoint_url}/{endpoint_uid}"
        }
        response = requests.post(url=f"{db_api_url}/jupyter", json=post_data)
        if result == 0:
            return {
                'statusCode': 200,
                'body': json.dumps({
                          "message": "complete create jupyter endpoint",
                          "data": post_data
                        })
            }  
        else:
            return {
                'statusCode': 500,
                'body': "error with create jupyter endpoint"
            }
    elif action == "delete":
        endpoint_uid = body.get("uid").lower()        
        result = delete_resource(user_uid, endpoint_uid)
        if result == 0:
            requests.delete(url=f"{db_api_url}/jupyter/{endpoint_uid}")
            return {
                'statusCode': 200,
                'body': "complete delete jupyter deployment"
            }
        else:
            return {
                'statusCode': 500,
                'body': "error with delete jupyter endpoint"
            }
    else:
        return {
            'statusCode': 500,
            'body': "invalid action"
        }