package main

import (
	"fmt"
	"io"
	"net/http"
	"time"
)

func main() {
	url := "http://54.168.16.27"

	// Send initial 1000 requests
	for i := 0; i < 1000; i++ {
		sendRequest(url)
	}

	// Send requests indefinitely
	for {
		sendRequest(url)
	}
}

func sendRequest(url string) {
	start := time.Now()
	resp, err := http.Get(url)
	if err != nil {
		fmt.Printf("Error sending request: %v\n", err)
		return
	}
	defer resp.Body.Close()

	elapsed := time.Since(start)
	fmt.Printf("Response code: %d, Response time: %s\n", resp.StatusCode, elapsed)

	body, err := io.ReadAll(resp.Body)

	if err != nil {
		fmt.Println(err)
	}

	fmt.Println(string(body))
	fmt.Println("--------------------------------------------------")
}