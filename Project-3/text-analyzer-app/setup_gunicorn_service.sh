#!/bin/bash

# Config
APP_NAME="textanalyzer"
APP_DIR="/home/ubuntu/text-analyzer-app"
VENV_DIR="$APP_DIR/venv"
SOCK_PATH="$APP_DIR/${APP_NAME}.sock"
SERVICE_PATH="/etc/systemd/system/${APP_NAME}.service"
USER="ubuntu"
GROUP="www-data"
GUNICORN_EXEC="$VENV_DIR/bin/gunicorn"
WSGI_MODULE="wsgi:app"

echo "Creating systemd service for $APP_NAME..."

sudo tee $SERVICE_PATH > /dev/null <<EOF
[Unit]
Description=Gunicorn service for Flask $APP_NAME
After=network.target

[Service]
User=$USER
Group=$GROUP
WorkingDirectory=$APP_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$GUNICORN_EXEC --workers 3 --bind unix:$SOCK_PATH -m 007 $WSGI_MODULE

Restart=always
RestartSec=5
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd and enabling service..."

sudo systemctl daemon-reexec
sudo systemctl enable $APP_NAME
sudo systemctl start $APP_NAME

echo "Gunicorn service '$APP_NAME' setup complete."

sudo systemctl status $APP_NAME --no-pager
