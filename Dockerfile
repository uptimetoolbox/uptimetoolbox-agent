FROM docker:19.03

RUN apk add dbus curl bash util-linux

COPY docker_entrypoint.sh agent.sh /opt/uptimetoolbox/

CMD /bin/bash -c "/opt/uptimetoolbox/docker_entrypoint.sh"
