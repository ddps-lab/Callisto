from tornado.web import RequestHandler
import json

class ActivityHandler(RequestHandler):
    def initialize(self, shutdown_extension):
        self.shutdown_extension = shutdown_extension

    def post(self):
        try:
            # 요청 본문을 가져와 JSON으로 파싱
            data = json.loads(self.request.body)
            # 활동 시간 업데이트
            self.shutdown_extension.update_last_activity_time(data['lastActivityTime'] / 1000.0)
            self.finish(json.dumps({"status": "success"}))
        except json.JSONDecodeError:
            # JSON 파싱 오류 처리
            self.set_status(400)
            self.finish(json.dumps({"status": "error", "message": "Invalid JSON data"}))