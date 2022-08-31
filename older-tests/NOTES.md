

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
 name: podman-userns
 annotations:
   io.kubernetes.cri-o.userns-mode: "auto:size=65536;keep-id=true"
spec:
 containers:
   - name: userns
     image: quay.io/podman/stable
     command: ["sleep", "10000"]
     securityContext:
       capabilities:
         add:
           - "SYS_ADMIN"
           - "MKNOD"
           - "SYS_CHROOT"
           - "SETFCAP"
EOF
```

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
 name: buildah-userns
 annotations:
   io.kubernetes.cri-o.userns-mode: "auto:size=65536;keep-id=true"
spec:
 containers:
   - name: userns
     image: quay.io/buildah/stable
     command: ["sleep", "10000"]
EOF
```

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
 name: udi-userns
 annotations:
   io.kubernetes.cri-o.userns-mode: "auto"
spec:
 containers:
   - name: userns
     image: quay.io/devfile/universal-developer-image:ubi8-latest
     securityContext:
       runAsUser: 0
EOF
```

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
 name: buildah-userns
 annotations:
   io.kubernetes.cri-o.userns-mode: "auto:size=65536;keep-id=true"
spec:
  containers:
  - name: userns
    image: quay.io/buildah/stable
    command: ["sleep", "10000"]
    volumeMounts:
    - mountPath: /var/lib/containers
      name: container-storage
  volumes:
  - name: container-storage
    emptyDir:
      medium: Memory
EOF
```


Test Dockerfile

```bash
cat > test-script.sh <<EOF
#/bin/bash
echo "Args \$*"
ls -l /
EOF
chmod +x test-script.sh && \
cat > Containerfile.test <<EOF
FROM fedora:33
RUN ls -l /test-script.sh
RUN /test-script.sh "Hello world"
RUN dnf update -y | tee /output/update-output.txt
RUN dnf install -y gcc
EOF

buildah -v /buildah-out:/output:rw \
        -v /root/test-script.sh:/test-script.sh:ro \
        build-using-dockerfile --storage-driver vfs \
        -t myimage -f Containerfile.test
```

