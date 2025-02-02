# gRPC LB Demo

Apply with:

```bash
kubectl apply -k k8s-manifests/
```

Run PromQL queries:

```promql
count(demo_grpc_sent_requests_total) by (client)
```

```promql
count(demo_grpc_served_requests_total) by (server)
```
