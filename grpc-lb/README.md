# gRPC LB Demo

1. select a patch in kustomization.yaml
2. apply manifests
3. wait for Prometheus to scrape metrics
4. run PromQL queries to check which servers are reached by which clients

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

Useful resources:

- https://grpc.io/blog/grpc-load-balancing/
- https://github.com/grpc/grpc/blob/master/doc/load-balancing.md
- https://github.com/jtattermusch/grpc-loadbalancing-kubernetes-examples
- https://svkrclg.medium.com/grpc-load-balancing-using-envoy-e8972214da2c
