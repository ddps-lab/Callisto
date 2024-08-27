import { JupyterFrontEnd, JupyterFrontEndPlugin } from '@jupyterlab/application';

// XSRF 토큰을 가져오는 함수
function getXsrfToken(): string | undefined {
  const matches = document.cookie.match('\\b_xsrf=([^;]*)\\b');
  return matches ? matches[1] : undefined;
}

let lastActivityTime = Date.now();

function updateLastActivity() {
  lastActivityTime = Date.now();

  // 서버에 활동 신호 보내기
  fetch('/api/backend-idle-shutdown/activity', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-XSRFToken': getXsrfToken() || '' // XSRF 토큰을 헤더에 포함
    },
    body: JSON.stringify({ lastActivityTime }),
  })
  .then(response => {
    console.log(response)
    if (!response.ok) {
      throw new Error('Network response was not ok');
    }
    return response.json();
  })
  .then(data => {
    console.log('Activity update successful:', data);
  })
  .catch(error => {
    console.error('Error updating activity:', error);
  });
}

// 사용자 활동 감지
window.addEventListener('click', updateLastActivity);
window.addEventListener('keydown', updateLastActivity);

const plugin: JupyterFrontEndPlugin<void> = {
  id: 'frontend_idle_shutdown',
  autoStart: true,
  activate: (app: JupyterFrontEnd) => {
    // JupyterLab 활성화 시 초기 활동 신호 전송
    updateLastActivity();
  },
};

export default plugin;
