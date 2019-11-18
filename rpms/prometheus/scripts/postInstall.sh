#!/bin/bash
systemctl enable prometheus.service
mkdir -p /prometheus_data
chown prometheus:prometheus /prometheus_data
chmod 0751 /prometheus_data