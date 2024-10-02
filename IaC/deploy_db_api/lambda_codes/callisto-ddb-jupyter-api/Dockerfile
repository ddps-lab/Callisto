FROM public.ecr.aws/lambda/python:3.12

RUN pip install awscli requests kubernetes jinja2 pyyaml --no-cache-dir

COPY jupyter_template.yaml ${LAMBDA_TASK_ROOT}

COPY index.py ${LAMBDA_TASK_ROOT}

RUN chmod +x /var/task

CMD ["index.lambda_handler"]