package main

import (
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"
	"os/signal"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
	"github.com/schollz/progressbar/v3"
)

type Metrics struct {
	totalConnections   int64
	activeConnections int64
	messagesSent      int64
	messagesReceived  int64
	errors            int64
	totalLatency      int64
}

func (m *Metrics) recordLatency(start time.Time) {
	atomic.AddInt64(&m.totalLatency, time.Since(start).Milliseconds())
}

var metrics Metrics

func main() {
	concurrent := flag.Int("c", 100, "number of concurrent connections")
	totalConns := flag.Int("n", 1000, "total number of connections to make")
	host := flag.String("h", "localhost:4000", "host:port of the websocket server")
	messageRate := flag.Int("r", 10, "messages per second per connection")
	duration := flag.Int("d", 60, "test duration in seconds")
	flag.Parse()

	u := url.URL{Scheme: "ws", Host: *host, Path: "/socket/websocket"}
	log.Printf("Connecting to %s", u.String())

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	var wg sync.WaitGroup
	connections := make(chan bool, *concurrent)
	
	// Progress bar for connections
	bar := progressbar.Default(int64(*totalConns))

	startTime := time.Now()
	deadline := startTime.Add(time.Duration(*duration) * time.Second)

	// Start connection loop
	for i := 0; i < *totalConns; i++ {
		connections <- true
		wg.Add(1)
		
		go func(id int) {
			defer func() {
				<-connections
				wg.Done()
				bar.Add(1)
			}()

			// Connect to websocket
			c, _, err := websocket.DefaultDialer.Dial(u.String(), nil)
			if err != nil {
				atomic.AddInt64(&metrics.errors, 1)
				log.Printf("Connection error: %v", err)
				return
			}
			defer c.Close()

			atomic.AddInt64(&metrics.totalConnections, 1)
			atomic.AddInt64(&metrics.activeConnections, 1)
			defer atomic.AddInt64(&metrics.activeConnections, -1)

			// Message sending loop
			messageTicker := time.NewTicker(time.Second / time.Duration(*messageRate))
			defer messageTicker.Stop()

			for {
				select {
				case <-messageTicker.C:
					if time.Now().After(deadline) {
						return
					}

					start := time.Now()
					err := c.WriteJSON(map[string]interface{}{
						"topic":   fmt.Sprintf("room:%d", id%100),
						"event":   "ping",
						"payload": map[string]interface{}{"time": time.Now().UnixNano()},
					})

					if err != nil {
						atomic.AddInt64(&metrics.errors, 1)
						return
					}

					atomic.AddInt64(&metrics.messagesSent, 1)
					metrics.recordLatency(start)

					// Read response
					_, message, err := c.ReadMessage()
					fmt.Println("Received message:", string(message))
					if err != nil {
						atomic.AddInt64(&metrics.errors, 1)
						return
					}
					atomic.AddInt64(&metrics.messagesReceived, 1)
				}
			}
		}(i)
	}

	// Wait for interrupt or completion
	select {
	case <-interrupt:
		log.Println("Interrupted, shutting down...")
	case <-time.After(time.Duration(*duration) * time.Second):
		log.Println("Test duration completed")
	}

	wg.Wait()

	// Print results
	elapsed := time.Since(startTime)
	fmt.Printf("\n=== Results ===\n")
	fmt.Printf("Test Duration: %v\n", elapsed.Round(time.Second))
	fmt.Printf("Total Connections: %d\n", metrics.totalConnections)
	fmt.Printf("Peak Active Connections: %d\n", metrics.activeConnections)
	fmt.Printf("Messages Sent: %d\n", metrics.messagesSent)
	fmt.Printf("Messages Received: %d\n", metrics.messagesReceived)
	fmt.Printf("Errors: %d\n", metrics.errors)
	
	if metrics.messagesSent > 0 {
		avgLatency := float64(metrics.totalLatency) / float64(metrics.messagesSent)
		fmt.Printf("Average Latency: %.2fms\n", avgLatency)
		fmt.Printf("Messages/sec: %.2f\n", float64(metrics.messagesSent)/elapsed.Seconds())
	}
}