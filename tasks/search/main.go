package main

import (
	"fmt"
	"time"

	"github.com/davecgh/go-spew/spew"
	"github.com/typesense/typesense-go/typesense"
	"github.com/typesense/typesense-go/typesense/api"
)

func main() {
	fmt.Println("vim-go")
	key := "xyz"
	client := typesense.NewClient(
		typesense.WithServer("http://localhost:8108"),
		typesense.WithAPIKey(key),
		typesense.WithConnectionTimeout(5*time.Second),
		typesense.WithCircuitBreakerMaxRequests(50),
		typesense.WithCircuitBreakerInterval(2*time.Minute),
		typesense.WithCircuitBreakerTimeout(1*time.Minute),
	)
	searchParameters := &api.SearchCollectionParams{
		Q:       "FOR_SALE",
		QueryBy: "status",
	}

	result, err := client.Collection("names").Documents().Search(searchParameters)

	if err != nil {
		panic(err)
	}

	spew.Dump(result)
}
