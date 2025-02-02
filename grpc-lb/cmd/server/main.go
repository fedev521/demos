package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"os"

	pb "github.com/fedev521/demos/grpc-lb/helloworld"
	"github.com/fedev521/demos/grpc-lb/metrics"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"google.golang.org/grpc"
)

var (
	port        = flag.Int("port", 50051, "The server port")
	metricsPort = flag.Int("metrics-port", 9090, "The metrics port to be scraped")
)

var (
	grpcCounter = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name:      "grpc_served_requests_total",
			Help:      "Number of requests gRPC invocations received by a server.",
			Namespace: "demo",
		},
		[]string{"service", "rpc", "client", "server"},
	)
)

// server is used to implement helloworld.GreeterServer.
type server struct {
	pb.UnimplementedGreeterServer
}

// SayHello implements helloworld.GreeterServer
func (s *server) SayHello(_ context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	clientName := in.GetName()
	myName := os.Getenv("HOSTNAME")

	log.Printf("Received '%v' from client", clientName)
	grpcCounter.WithLabelValues("Greeter", "SayHello", clientName, myName).Inc()

	return &pb.HelloReply{Message: myName}, nil
}

func main() {
	flag.Parse()

	go metrics.RunMetricsServer(*metricsPort)

	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	pb.RegisterGreeterServer(s, &server{})
	log.Printf("server listening at %v", lis.Addr())
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
