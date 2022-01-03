package main

import (
	"os"
	"time"

	"github.com/typesense/typesense-go/typesense"
	"github.com/typesense/typesense-go/typesense/api"
	"github.com/typesense/typesense-go/typesense/api/pointer"
)

func main() {

	key := os.Getenv("TYPESENSE_FIND_ADMIN")
	url := os.Getenv("TYPESENSE_FIND_URL")
	client := typesense.NewClient(
		typesense.WithServer(url),
		typesense.WithAPIKey(key),
		typesense.WithConnectionTimeout(5*time.Second),
		typesense.WithCircuitBreakerMaxRequests(50),
		typesense.WithCircuitBreakerInterval(2*time.Minute),
		typesense.WithCircuitBreakerTimeout(1*time.Minute),
	)

	schema := &api.CollectionSchema{
		Name: "names",
		Fields: []api.Field{
			{
				Name: "id",
				Type: "string",
			},
			{
				Name: "name",
				Type: "string",
			},
			{
				Name: "status",
				Type: "string",
			},

			{
				Name:  "address",
				Type:  "string",
				Facet: pointer.True(),
			},
			{
				Name: "locked_until",
				Type: "int64",
			},
			{
				Name: "valid_until",
				Type: "int64",
			},
			{
				Name:     "auction_ends",
				Type:     "int64",
				Optional: pointer.True(),
			},
			{
				Name:     "auction_reserve_price",
				Type:     "float",
				Optional: pointer.True(),
			},
			{
				Name:     "auction_start_price",
				Type:     "float",
				Optional: pointer.True(),
			},
			{
				Name:     "latest_bid_by",
				Type:     "string",
				Optional: pointer.True(),
				Facet:    pointer.True(),
			},
			{
				Name:     "latest_bid",
				Type:     "float",
				Optional: pointer.True(),
			},
			{
				Name:     "sale_price",
				Type:     "float",
				Optional: pointer.True(),
			},
			{
				Name:  "status",
				Type:  "string",
				Facet: pointer.True(),
			},
			{
				Name:     "auction_reserve_price",
				Type:     "float",
				Optional: pointer.True(),
			},
		},
		DefaultSortingField: pointer.String("valid_until"),
	}

	_, err := client.Collections().Create(schema)
	if err != nil {
		panic(err)
	}

}
