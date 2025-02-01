// Package main implements a client for Greeter service.
package main

import (
	"context"
	"flag"
	"log"
	"os"
	"time"

	pb "github.com/fedev521/demos/grpc-lb/helloworld"
	"github.com/fedev521/demos/grpc-lb/metrics"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

var (
	addr         = flag.String("addr", "localhost:50051", "the address to connect to")
	metricsPort  = flag.Int("metrics-port", 2110, "The metrics port to be scraped")
	sleepSeconds = flag.Int("sleep-seconds", 3, "Idle interval between requests")
)

var (
	grpcCounter = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "grpc_sent_requests_total",
			Help: "Number of requests gRPC calls sent by a client",
		},
		[]string{"service", "rpc", "client", "server"},
	)
)

func main() {
	flag.Parse()

	go metrics.RunMetricsServer(*metricsPort)

	// Set up a connection to the server.
	conn, err := grpc.NewClient(*addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("could not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewGreeterClient(conn)

	myName := os.Getenv("HOSTNAME")

	// infinite loop: send request, log, increment Prometheus counter
	for {
		ctx, cancel := context.WithTimeout(context.Background(), time.Second)
		r, err := c.SayHello(ctx, &pb.HelloRequest{Name: myName})
		if err != nil {
			log.Fatalf("could not greet: %v", err)
		}

		serverName := r.GetMessage()
		cancel()
		log.Printf("Received: '%v' from server", serverName)
		grpcCounter.WithLabelValues("Greeter", "SayHello", myName, serverName).Inc()

		time.Sleep(time.Duration(*sleepSeconds) * time.Second)
	}
}
