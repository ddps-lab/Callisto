import { JupyterFrontEnd, JupyterFrontEndPlugin } from '@jupyterlab/application';
import { ServerConnection } from '@jupyterlab/services'

// XSRF 토큰을 가져오는 함수
function getXsrfToken(): string | undefined {
  const matches = document.cookie.match('\\b_xsrf=([^;]*)\\b');
  return matches ? matches[1] : undefined;
}

let lastActivityTime = Date.now();

function updateLastActivity(baseUrl: string) {
  lastActivityTime = Date.now();

  // 서버에 활동 신호 보내기
  fetch(`${baseUrl}api/backend-idle-shutdown/activity`, {
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

function setupActivityListeners(baseUrl: string) {
  // 사용자 활동 감지
  window.addEventListener('click', () => updateLastActivity(baseUrl));
  window.addEventListener('keydown', () => updateLastActivity(baseUrl));
}

const plugin: JupyterFrontEndPlugin<void> = {
  id: 'frontend_idle_shutdown',
  autoStart: true,
  activate: (app: JupyterFrontEnd) => {
    const baseUrl = ServerConnection.makeSettings().baseUrl;
    // JupyterLab 활성화 시 초기 활동 신호 전송
    setupActivityListeners(baseUrl)
    updateLastActivity(baseUrl);
  },
};

export default plugin;
