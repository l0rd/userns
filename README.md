# Leverage userns to build an image as an unprvileged OpenShift user

The goal is to start a Pod, clone a Git repository that contains a Dockerfile and run a command (`buildah`) that builds the image. All that as an unprivileged OpenShift user.

First some preparation work:

```bash
# Build and push an image that has both buildah and git
./0_1.build_image.sh quay.io/mloriedo/buildah:userns

# Create an OpenShift user (user1) and a new project (test) where the user has edit role
./0_2.create-user.sh
```

With that we can a pod, as the user1 unprivileged user, with the following annotations `io.kubernetes.cri-o.userns-mode: "auto"` and `io.openshift.builder: "true"`:

```bash
oc --as user1 create -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: buildah-userns
  namespace: test
  annotations:
    io.kubernetes.cri-o.userns-mode: "auto"
    io.openshift.builder: "true"
spec:
  containers:
    - name: userns
      image: quay.io/mloriedo/buildah:userns
      resources:
        limits:
          cpu: 100m
          memory: 1G
EOF
```

The creation of the Pod fails on OCP 4.10 and the following error is found in the events:

```log
Warning  Failed          91s               kubelet            Error: container create failed: time="2022-08-31T10:15:03Z" level=error msg="runc create failed: unable to start container process: unable to setup user: cannot set uid to unmapped user in user namespace"
```

If that had worked we could have tried to git clone the repo and build the container:

```bash
# Git clone
kubectl exec -ti buildah-userns -- \
	git clone https://github.com/l0rd/tilt-example-java /projects/tilt-example-java

# Build the image
kubectl exec -ti buildah-userns -- cd /projects/tilt-example-java/201-quarkus-live-update && \
   buildah --storage-driver vfs bud -t test \
     -f src/main/docker/Dockerfile.jvm .
```

## Articles about running Pods with userns on OCP and Kube

[User namespaces with Buildah and OpenShift Pipelines | Chmouel's blog](https://blog.chmouel.com/2022/01/25/user-namespaces-with-buildah-and-openshift-pipelines/)
[Building a Linux container by hand using namespaces | Enable Sysadmin](https://www.redhat.com/sysadmin/building-container-namespaces)
[How to use Podman inside of Kubernetes | Enable Sysadmin](https://www.redhat.com/sysadmin/podman-inside-kubernetes)
[Fraser's IdM Blog - Running Pods in user namespaces without privileged SCCs](https://frasertweedale.github.io/blog-redhat/posts/2022-02-02-openshift-user-ns-without-anyuid.html)
[[OCPNODE-540] Follow-through work for Run pods in user namespaces for builds - Red Hat Issue Tracker](https://issues.redhat.com/browse/OCPNODE-540)
[Improving Kubernetes and container security with user namespaces | Kinvolk](https://kinvolk.io/blog/2020/12/improving-kubernetes-and-container-security-with-user-namespaces/)
[127: Add KEP for user namespaces support by rata · Pull Request #3065 · kubernetes/enhancements](https://github.com/kubernetes/enhancements/pull/3065)
[containers/bubblewrap: Unprivileged sandboxing tool](https://github.com/containers/bubblewrap)