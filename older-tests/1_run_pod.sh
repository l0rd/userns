#!/bin/bash

oc --as user1 create -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: buildah-userns
  annotations:
    # io.openshift.userns: "true"
    # io.kubernetes.cri-o.userns-mode: "auto:size=65536;map-to-root=true"
    io.kubernetes.cri-o.userns-mode: "auto"
    io.kubernetes.cri-o.Devices: "/dev/fuse"
    io.openshift.builder: "true"
spec:
  # securityContext:
  #   runAsUser: 1000650000
  containers:
    - name: userns
      image: quay.io/mloriedo/buildah:userns
      volumeMounts:
        #- mountPath: /var/lib/containers
        #  name: container-storage
        - mountPath: /projects
          name: projects
      resources:
        limits:
          cpu: 100m
          memory: 1G
      # env:
      #   - name: _CONTAINERS_USERNS_CONFIGURED
      #     value: "0"
  volumes:
   - name: container-storage
     emptyDir:
       medium: Memory
   - name: projects
     emptyDir: {}
      #resources:
      # limits:
      #   github.com/fuse: 1
EOF
