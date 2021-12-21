package main

import (
	"time"

	"github.com/typesense/typesense-go/typesense"
	"github.com/typesense/typesense-go/typesense/api"
)

func main() {

	key := "xyz"
	client := typesense.NewClient(
		typesense.WithServer("http://localhost:8108"),
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
				Facet: BoolPointer(true),
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
				Optional: BoolPointer(true),
			},
			{
				Name:     "auction_reserve_price",
				Type:     "float",
				Optional: BoolPointer(true),
			},
			{
				Name:     "auction_start_price",
				Type:     "float",
				Optional: BoolPointer(true),
			},
			{
				Name:     "latest_bid_by",
				Type:     "string",
				Facet:    BoolPointer(true),
				Optional: BoolPointer(true),
			},
			{
				Name:     "latest_bid",
				Type:     "float",
				Optional: BoolPointer(true),
			},
			{
				Name:     "sale_price",
				Type:     "float",
				Optional: BoolPointer(true),
			},
			{
				Name:  "status",
				Type:  "string",
				Facet: BoolPointer(true),
			},
			{
				Name:     "auction_reserve_price",
				Type:     "float",
				Optional: BoolPointer(true),
			},
		},
		DefaultSortingField: StringPointer("name"),
	}

	_, err := client.Collections().Create(schema)
	if err != nil {
		panic(err)
	}

}

func StringPointer(s string) *string {
	return &s
}
func BoolPointer(b bool) *bool {
	return &b
}
