FROM jupyter/base-notebook:latest
RUN pip3 install --no-cache-dir kubernetes

# 클라이언트 확장 빌드 및 설치
WORKDIR /opt/extension/frontend_idle_shutdown
COPY frontend_idle_shutdown /opt/extension/frontend_idle_shutdown
USER root
RUN chown jovyan:users /opt/extension/frontend_idle_shutdown -R
USER jovyan
RUN pip install --no-cache-dir -e .

# 클라이언트 확장 빌드
RUN jlpm install && jlpm run build && jupyter labextension install /opt/extension/frontend_idle_shutdown && jlpm cache clean
USER root
RUN rm -rf /opt/extension/frontend_idle_shutdown
USER jovyan

# 서버 확장 설치
COPY ./backend_idle_shutdown /opt/conda/lib/python3.11/site-packages/backend_idle_shutdown
USER root
RUN chown jovyan:users /opt/conda/lib/python3.11/site-packages/backend_idle_shutdown -R
USER jovyan
RUN pip install /opt/conda/lib/python3.11/site-packages/backend_idle_shutdown

# 서버 확장 활성화
RUN jupyter server extension enable --py backend_idle_shutdown

WORKDIR /home/jovyan/work

