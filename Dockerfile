FROM quay.io/buildah/stable

RUN dnf update -y && dnf install -y git

# USER 0

CMD sleep 10000
 
