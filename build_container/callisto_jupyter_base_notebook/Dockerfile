FROM jupyter/base-notebook:lab-4.0.7

# 서버 확장 설치
USER root
COPY ./backend_idle_shutdown /tmp/backend_idle_shutdown
WORKDIR /tmp/backend_idle_shutdown
RUN pip install .  # setup.py 기반 설치

# 서버 확장 활성화
RUN jupyter server extension enable --py backend_idle_shutdown
WORKDIR /home/jovyan
RUN rm -rf /tmp/backend_idle_shutdown

USER jovyan