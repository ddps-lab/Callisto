import time
import threading
from kubernetes import client, config
from jupyter_server.utils import url_path_join
import boto3
from .handlers import ActivityHandler
import os

REGION = os.getenv('REGION', "ap-northeast-2")

def update_dynamodb_status_item(table_name, partition_key, partition_value, range_key, range_value, update_status_value):
    dynamodb = boto3.resource('dynamodb', region_name=REGION)
    table = dynamodb.Table(table_name)
    response = table.update_item(
        Key={
            partition_key: partition_value,
            range_key: range_value
        },
        UpdateExpression=f"set #status = :new_val",
        ExpressionAttributeNames={
            '#status': 'status'
        },
        ExpressionAttributeValues={
            ':new_val': update_status_value,
        },
        ReturnValues="UPDATED_NEW"
    )
    return response

class ShutdownExtension:
    def __init__(self, serverapp):
        self.serverapp = serverapp
        self.last_activity_time = time.time()
        self.table_name = os.getenv("TABLE_NAME", "table_name")
        self.namespace = os.getenv("NAMESPACE", "default")
        self.inactivity_limit = int(os.getenv("INACTIVITY_TIME", "10")) * 60
        self.deployment_name = os.getenv("DEPLOYMENT_NAME", "deploymentname")
        self.created_at = int(os.getenv("CREATED_AT", "0"))
        self.timer_thread = threading.Thread(target=self.monitor_activity)
        self.timer_thread.start()
        update_dynamodb_status_item(self.table_name, "sub", self.namespace, "created_at", self.created_at, "running")
        config.load_incluster_config()
        self.k8s_apps_v1 = client.AppsV1Api()

    def update_last_activity_time(self, activity_time):
        self.last_activity_time = activity_time

    def scale_down_deployment(self):
        # Deployment의 replica를 0으로 설정
        body = {
            "spec": {
                "replicas": 0
            }
        }
        self.k8s_apps_v1.patch_namespaced_deployment_scale(
            name=self.deployment_name,
            namespace=self.namespace,
            body=body
        )
        self.serverapp.log.info(f"Scaled down deployment {self.deployment_name} in namespace {self.namespace} to 0 replicas.")


    def monitor_activity(self):
        while True:
            self.serverapp.log.info("Monitoring activity...")  # 로그 추가
            self.serverapp.log.info(f"Last Activity Time : {time.time() - self.last_activity_time}")  # 로그 추가
            self.serverapp.log.info(f"Inactivity Limit : {self.inactivity_limit}")
            if time.time() - self.last_activity_time > self.inactivity_limit:
                kernels = list(self.serverapp.kernel_manager.list_kernels())
                self.serverapp.log.info(f"Kernels: {kernels}")  # 로그 추가
                if all(kernel['execution_state'] == 'idle' for kernel in kernels):
                    self.is_running = False
                    self.serverapp.log.info("Inactivity detected, Scaling down the kubernetes deployment (JupyterLab).")
                    update_dynamodb_status_item(self.table_name, "sub", self.namespace, "created_at", self.created_at, "stopped")
                    self.scale_down_deployment()
            time.sleep(60)  # 1분마다 체크

def _load_jupyter_server_extension(serverapp):
    # ShutdownExtension 인스턴스 생성
    extension = ShutdownExtension(serverapp)

    # 핸들러 경로 패턴을 명확히 정의
    route_pattern = url_path_join(serverapp.base_url, "api", "backend-idle-shutdown", "activity")
    serverapp.log.info(f"Route Pattern = {route_pattern}")

    # 핸들러 등록
    serverapp.web_app.add_handlers(".*$", [(route_pattern, ActivityHandler, {"shutdown_extension": extension})])

    # 성공적으로 로드되었음을 알리는 로그 메시지 출력
    serverapp.log.info("Loaded backend_idle_shutdown extension successfully")
