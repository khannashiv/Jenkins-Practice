FROM python:3
RUN pip install django==3.2

COPY . .

# Debugging step to list files in /app
RUN ls -al /app

RUN python manage.py migrate
EXPOSE 8000
CMD ["python","manage.py","runserver","0.0.0.0:8000"]


