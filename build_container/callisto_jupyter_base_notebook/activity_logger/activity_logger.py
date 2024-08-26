import json
import datetime
import requests
from notebook.base.handlers import APIHandler
from notebook.utils import url_path_join
from jupyter_server.base.handlers import JupyterHandler
from jupyter_server.services.kernels.kernelmanager import MappingKernelManager
import tornado.web

class ActivityLogger:
    """Activity Logger to store Jupyter activities"""
    def __init__(self, log_file):
        self.log_file = log_file

    def log_activity(self, activity_data):
        with open(self.log_file, "a") as f:
            f.write(json.dumps(activity_data) + "\n")

class ActivityHandler(APIHandler):
    def initialize(self, logger):
        self.logger = logger

    @tornado.web.authenticated
    def post(self):
        data = self.get_json_body()
        activity_data = {
            "timestamp": datetime.datetime.now().isoformat(),
            "event": data.get("event"),
            "status": data.get("status"),
            "content": data.get("content")
        }
        self.logger.log_activity(activity_data)
        self.finish(json.dumps({"status": "logged"}))

def setup_handlers(web_app, logger):
    host_pattern = ".*$"
    base_url = web_app.settings["base_url"]
    route_pattern = url_path_join(base_url, "/log-activity")
    handlers = [(route_pattern, ActivityHandler, dict(logger=logger))]
    web_app.add_handlers(host_pattern, handlers)

def _record_activity(kernel_manager, msg, *args, **kwargs):
    """Record kernel activity"""
    msg_type = msg['header']['msg_type']
    activity_data = {}

    if msg_type == 'execute_input':
        activity_data = {
            "event": "cell_execution_started",
            "content": msg['content']['code']
        }
    elif msg_type == 'execute_reply':
        activity_data = {
            "event": "cell_execution_completed",
            "status": msg['content']['status'],
            "content": msg['content']
        }
    elif msg_type == 'status':
        activity_data = {
            "event": f"kernel_{msg['content']['execution_state']}",
            "content": msg['content']['execution_state']
        }
    elif msg_type == 'error':
        activity_data = {
            "event": "cell_execution_error",
            "content": msg['content']
        }

    # 로그를 파일에 기록하거나 외부 서비스로 전송
    if activity_data:
        requests.post("http://localhost:8888/log-activity", json=activity_data)

def load_jupyter_server_extension(nbapp):
    """Jupyter 서버 확장 로드 시 설정"""
    log_file = "/home/jovyan/activity_log.txt"
    logger = ActivityLogger(log_file)
    setup_handlers(nbapp.web_app, logger)

    kernel_manager = nbapp.kernel_manager
    if hasattr(kernel_manager, "register_hook"):
        kernel_manager.register_hook(_record_activity)
