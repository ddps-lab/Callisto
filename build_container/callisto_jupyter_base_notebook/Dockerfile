FROM jupyter/base-notebook:latest

USER root
RUN pip install --no-cache-dir requests

WORKDIR /home/jovyan/

COPY ./activity_logger /home/jovyan/activity_logger

RUN mkdir -p /home/jovyan/.jupyter/custom/
COPY jupyter_notebook_config.py /home/jovyan/.jupyter/custom/

RUN chown -R jovyan:users /home/jovyan/.jupyter/
USER jovyan