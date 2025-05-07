FROM python:3.11

RUN pip install django==3.2

COPY . /app/

RUN python /app/Project-2/python-jenkins-argocd-k8s/manage.py migrate

EXPOSE 8000

CMD ["python", "/app/Project-2/python-jenkins-argocd-k8s/manage.py", "runserver", "0.0.0.0:8000"]

