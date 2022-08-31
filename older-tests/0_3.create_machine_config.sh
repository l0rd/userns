#!/bin/bash

kubectl apply -f - << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: idm-4-10
spec:
  kernelArguments:
    - systemd.unified_cgroup_hierarchy=1
    - cgroup_no_v1="all"
    - psi=1
  config:
    ignition:
      version: 3.1.0
    systemd:
      units:
      - name: "override-runc.service"
        enabled: true
        contents: |
          [Unit]
          Description=Install runc override
          After=network-online.target rpm-ostreed.service
          [Service]
          ExecStart=/bin/sh -c 'rpm -q runc-1.0.3-992.rhaos4.10.el8.x86_64 || rpm-ostree override replace --reboot https://ftweedal.fedorapeople.org/runc-1.0.3-992.rhaos4.10.el8.x86_64.rpm'
          Restart=on-failure
          [Install]
          WantedBy=multi-user.target
    storage:
      files:
      - path: /etc/subuid
        overwrite: true
        contents:
          source: data:text/plain;charset=utf-8;base64,Y29yZToxMDAwMDA6NjU1MzYKY29udGFpbmVyczoyMDAwMDA6MjY4NDM1NDU2Cg==
      - path: /etc/subgid
        overwrite: true
        contents:
          source: data:text/plain;charset=utf-8;base64,Y29yZToxMDAwMDA6NjU1MzYKY29udGFpbmVyczoyMDAwMDA6MjY4NDM1NDU2Cg==
      - path: /etc/crio/crio.conf.d/99-crio-userns.conf
        overwrite: true
        contents:
          source: data:text/plain;charset=utf-8;base64,W2NyaW8ucnVudGltZS53b3JrbG9hZHMub3BlbnNoaWZ0LXVzZXJuc10KYWN0aXZhdGlvbl9hbm5vdGF0aW9uID0gImlvLm9wZW5zaGlmdC51c2VybnMiCmFsbG93ZWRfYW5ub3RhdGlvbnMgPSBbCiAgImlvLmt1YmVybmV0ZXMuY3JpLW8udXNlcm5zLW1vZGUiLAogICJpby5rdWJlcm5ldGVzLmNyaS1vLmNncm91cDItbW91bnQtaGllcmFyY2h5LXJ3IiwKICAiaW8ua3ViZXJuZXRlcy5jcmktby5EZXZpY2VzIgpdCg==
EOF

echo "Waiting for Machine Config Operator to finish updating the worker nodes"

kubectl wait mcp/worker \
    --for condition=updated --timeout=-1s
