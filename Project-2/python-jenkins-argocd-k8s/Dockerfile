# FROM python:3
# RUN pip install django==3.2

# COPY . .

# RUN python /manage.py migrate
# EXPOSE 8000
# CMD ["python","/manage.py","runserver","0.0.0.0:8000"]


FROM python:3

# Install Django (or other dependencies)
RUN pip install django==3.2

# Copy the contents of the current directory (from the build context) into the container
COPY . /app/

# Run migrations (with the full path to manage.py)
RUN python /app/Project-2/python-jenkins-argocd-k8s/manage.py migrate

# Expose the port for Django
EXPOSE 8000

# Start the Django server with the full path to manage.py
CMD ["python", "/app/Project-2/python-jenkins-argocd-k8s/manage.py", "runserver", "0.0.0.0:8000"]
