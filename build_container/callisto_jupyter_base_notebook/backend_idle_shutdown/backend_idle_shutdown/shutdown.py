import atexit
import os
from kubernetes import client, config
import boto3
from jupyter_server.serverapp import ServerApp
import signal

REGION = os.getenv('REGION', "ap-northeast-2")


def update_dynamodb_status_item(table_name, partition_key, partition_value, range_key, range_value, update_status_value):
    """DynamoDB 테이블의 상태 업데이트"""
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


class ShutdownHook:
    def __init__(self, serverapp: ServerApp):
        """Jupyter 서버 종료 시 실행할 훅을 초기화"""
        self.serverapp = serverapp
        self.table_name = os.getenv("TABLE_NAME", "table_name")
        self.namespace = os.getenv("NAMESPACE", "default")
        self.deployment_name = os.getenv("DEPLOYMENT_NAME", "deploymentname")
        self.created_at = int(os.getenv("CREATED_AT", "0"))
        update_dynamodb_status_item(self.table_name, "sub", self.namespace, "created_at", self.created_at, "running")

        self.shutdown_timeout = serverapp.shutdown_no_activity_timeout
        self.received_sigterm = False

        # SIGTERM = signal 15
        signal.signal(signal.SIGTERM, self.handle_sigterm)

        # Kubernetes API 클라이언트 로드
        config.load_incluster_config()
        self.k8s_apps_v1 = client.AppsV1Api()

        # atexit을 이용하여 Jupyter 종료 감지
        atexit.register(self.on_shutdown)

    def scale_down_deployment(self):
        """Kubernetes Deployment를 Scale Down"""
        body = {"spec": {"replicas": 0}}
        self.k8s_apps_v1.patch_namespaced_deployment_scale(
            name=self.deployment_name,
            namespace=self.namespace,
            body=body
        )
        self.serverapp.log.info(
            f"Scaled down deployment {self.deployment_name} in namespace {self.namespace} to 0 replicas."
        )

    def handle_sigterm(self, signum, frame):
        self.serverapp.log.info("Received SIGTERM signal. Assuming shutdown due to kubectl scale or pod termination.")
        self.received_sigterm = True

    def is_jupyter_auto_shutting_down(self):
        kernel_list = self.serverapp.kernel_manager.list_kernels()
        if not kernel_list:
            self.serverapp.log.info("All kernels are idle: Possible idle shutdown.")
            return True

        all_idle = all(kernel["execution_state"] == "idle" for kernel in kernel_list)
        if all_idle:
            self.serverapp.log.info("All kernels are idle: Possible idle shutdown.")
            return True

        active_sessions = self.serverapp.session_manager.list_sessions()
        if active_sessions:
            self.serverapp.log.info("Active sessions exist: Not an idle shutdown.")
            return False

        return False

    def on_shutdown(self):
        """Jupyter 종료 시 실행되는 코드"""
        self.serverapp.log.info("Jupyter is shutting down. Checking reasons for shutdown.")

        if self.received_sigterm:
            self.serverapp.log.info("Shutdown triggered due to kubectl scale or pod termination. Hook will not execute.")
            return
        
        if self.is_jupyter_auto_shutting_down():
            self.serverapp.log.info("Jupyter is shutting down due to idle shutdown. Updating DynamoDB & Scaling down deployment.")
            update_dynamodb_status_item(
                self.table_name, "sub", self.namespace, "created_at", self.created_at, "stopped"
            )
            # Kubernetes Deployment Scale Down
            self.scale_down_deployment()
        else:
            self.serverapp.log.info("Shutdown triggered due to manual shutdown. Hook will not execute.")
