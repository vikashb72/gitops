cat > kafka-cluster-ca.json <<EOF
{
  "ca.crt": "$(awk '{printf "%s\\n", $0}' kafka-cluster-ca.crt)",
  "ca.key": "$(awk '{printf "%s\\n", $0}' kafka-cluster-ca.key)",
  "ca.password": "$(awk '{printf "%s\\n", $0}' kafka-cluster-ca.password)",
  "ca.p12": "$(base64 -w 0 kafka-cluster-ca.p12)"
}
EOF

vault kv put kv/minikube/kafka/cluster-ca @kafka-cluster-ca.json
cat > kafka-client-ca.json <<EOF
{
  "ca.crt": "$(awk '{printf "%s\\n", $0}' kafka-client-ca.crt)",
  "ca.key": "$(awk '{printf "%s\\n", $0}' kafka-client-ca.key)",
  "ca.password": "$(awk '{printf "%s\\n", $0}' kafka-client-ca.password)",
  "ca.p12": "$(base64 -w 0 kafka-client-ca.p12)"
}
EOF
vault kv put kv/minikube/kafka/client-ca @kafka-client-ca.json
