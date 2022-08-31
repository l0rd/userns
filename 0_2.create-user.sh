#!/bin/bash

set -eof

USER=user1
PASSWORD=user1
HTPASSWD_FILE="/tmp/crwhtpasswd"
htpasswd -cbB ${HTPASSWD_FILE} $USER $PASSWORD
htpwd_encoded="$(cat $HTPASSWD_FILE | gbase64 -w 0)"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  creationTimestamp: null
  name: htpass-secret
  namespace: openshift-config
data:
  htpasswd: ${htpwd_encoded}
EOF

kubectl patch oauths cluster --type merge -p '
spec:
  identityProviders:
    - name: htpasswd
      mappingMethod: claim
      type: HTPasswd
      htpasswd:
        fileData:
          name: htpass-secret
'

oc new-project test
oc adm policy add-role-to-user edit "htpasswd:user1"
