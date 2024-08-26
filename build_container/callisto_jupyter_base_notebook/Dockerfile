FROM jupyter/base-notebook:latest

USER root
RUN pip install --no-cache-dir requests

WORKDIR /home/jovyan/

COPY ./activity_logger /home/jovyarn/activity_logger

RUN kmdir -p /home/jovyan/.jupyter/custom/
COPY jupyter_notebook_config.py /home/jovyan/.jupyter/custom/

RUN chown -R jovyarn:users /home/jovyan/.jupyter/
USER jovyan