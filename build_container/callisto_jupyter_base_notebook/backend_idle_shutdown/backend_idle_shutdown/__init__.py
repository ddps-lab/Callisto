from .shutdown import ShutdownHook

def load_jupyter_server_extension(serverapp):
    """Jupyter 서버 확장을 로드하는 함수"""
    ShutdownHook(serverapp)
    serverapp.log.info("Loaded backend_idle_shutdown extension successfully")
