# Enterprise-Grade WebSocket Scaling Infrastructure

This directory contains the Kubernetes configuration for deploying a highly scalable, resilient, and observable WebSocket application built with Phoenix Framework and Elixir.

## Architecture Overview

This infrastructure is designed with the following principles:
- **High Availability**: Multiple replicas across availability zones
- **Scalability**: Horizontal autoscaling based on demand
- **Observability**: Comprehensive metrics, logs, and distributed tracing
- **Resilience**: Connection draining, liveness/readiness probes, and proper resource management

## Components

### Core Services
1. **WebSocket Application**: Phoenix/Elixir application that handles WebSocket connections
2. **PostgreSQL**: Database for persistence
3. **Redis Cluster**: For distributed session management and PubSub across nodes

### Scaling & Orchestration
1. **Kubernetes HPA**: For automatic scaling based on CPU/memory metrics
2. **Network Policies**: For secure inter-service communication
3. **Ingress Controller**: Configured for WebSocket proxying with long timeout values
4. **StatefulSets**: For stateful components like Redis and PostgreSQL

### Monitoring & Observability
1. **Prometheus**: For metrics collection
2. **Grafana**: For metrics visualization
3. **Jaeger**: For distributed tracing
4. **Structured Logging**: JSON logging for easier aggregation and searching

## Deployment Instructions

### Prerequisites
- Kubernetes cluster (EKS, GKE, AKS, or any other Kubernetes distribution)
- `kubectl` configured to access your cluster
- Docker registry access (for storing your application image)

### Building the Docker Image

```bash
# From the repository root
docker build -t your-registry/websocket-app:latest .
docker push your-registry/websocket-app:latest

# Update image reference in k8s/04-websocket-app.yaml
```

### Setting up Secrets

Before deploying, create the necessary secrets:

```bash
# Create a secure secret key base for Phoenix
SECRET_KEY_BASE=$(mix phx.gen.secret)
RELEASE_COOKIE=$(mix phx.gen.secret)

# Update the secrets in k8s/03-secrets.yaml
```

### Deploying the Infrastructure

Apply the Kubernetes manifests in order:

```bash
# Create namespace
kubectl apply -f k8s/00-namespace.yaml

# Deploy configuration and secrets
kubectl apply -f k8s/01-configmap.yaml
kubectl apply -f k8s/03-secrets.yaml

# Deploy databases and stateful components
kubectl apply -f k8s/02-postgres.yaml
kubectl apply -f k8s/10-redis.yaml

# Deploy monitoring
kubectl apply -f k8s/07-monitoring.yaml
kubectl apply -f k8s/11-jaeger.yaml

# Deploy the application 
kubectl apply -f k8s/04-websocket-app.yaml

# Apply network policies
kubectl apply -f k8s/09-network-policies.yaml

# Set up autoscaling
kubectl apply -f k8s/06-hpa.yaml

# Configure ingress
kubectl apply -f k8s/05-ingress.yaml
```

## Monitoring & Observability

### Prometheus Metrics

The WebSocket application exposes metrics at the `/metrics` endpoint in Prometheus format. Key metrics include:

- WebSocket connection count
- Message throughput
- Response times
- Error rates
- VM/Runtime metrics

### Distributed Tracing

Jaeger collects distributed traces across the application. Access the Jaeger UI:

```bash
kubectl port-forward svc/jaeger 16686:16686 -n websocket-app
# Then navigate to http://localhost:16686
```

### Grafana Dashboards

Pre-configured dashboards are available for:
- WebSocket connections and throughput
- Database performance
- System resources
- Error rates

## Load Testing

Execute the load testing deployment to simulate thousands of concurrent WebSocket connections:

```bash
kubectl apply -f k8s/08-load-testing.yaml
```

The load test creates 5 worker pods, each simulating 500 concurrent connections for 5 minutes.

## Scaling Guidance

### Vertical Scaling

- **CPU-Bound**: Increase CPU limits/requests in the `WebsocketApp` deployment
- **Memory-Bound**: Increase memory limits/requests based on connection count

### Horizontal Scaling

The HPA is configured to scale based on:
- 70% average CPU utilization
- 80% average memory utilization

To adjust scaling parameters:
```bash
kubectl edit hpa websocket-app-hpa -n websocket-app
```

## Troubleshooting

### Connectivity Issues
- Check network policies: `kubectl get networkpolicies -n websocket-app`
- Verify ingress controller logs: `kubectl logs -n ingress-nginx deployment/ingress-nginx-controller`

### Performance Issues
- Check Prometheus metrics for bottlenecks
- Use Jaeger to trace slow requests
- Monitor Redis and PostgreSQL performance

### Common Error Scenarios
- **503 Service Unavailable**: Check readiness probe failures
- **WebSocket Connection Drops**: Check for timeout configurations and network stability
- **High Latency**: Look at database query performance and Redis operations