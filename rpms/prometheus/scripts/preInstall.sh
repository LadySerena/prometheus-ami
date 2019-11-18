#!/bin/bash
getent group prometheus >/dev/null || groupadd -r prometheus
getent passwd prometheus >/dev/null || \
    useradd -r -g prometheus -d /prometheus_data -s /sbin/nologin \
    -c "service account for prometheus monitoring server" prometheus