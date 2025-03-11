FROM jupyter/base-notebook:x86_64-python-3.11

# 서버 확장 설치
COPY ./backend_idle_shutdown /opt/conda/lib/python3.11/site-packages/backend_idle_shutdown
USER root
RUN chown jovyan:users /opt/conda/lib/python3.11/site-packages/backend_idle_shutdown -R
USER jovyan
RUN pip install /opt/conda/lib/python3.11/site-packages/backend_idle_shutdown

# 서버 확장 활성화
RUN jupyter server extension enable --py backend_idle_shutdown

# boto3 설치
RUN pip install boto3 --no-cache-dir