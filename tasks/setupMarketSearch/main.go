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

	client.Collection("market").Delete()
	//	client.Collection("sold").Delete()
	client.Collection("names").Delete()

	fields := []api.Field{
		{
			Name: "id",
			Type: "string",
		},
		{
			Name: "uuid",
			Type: "int64",
		},

		{
			Name: "tenant",
			Type: "string",
		},
		{
			Name:  "seller",
			Type:  "string",
			Facet: pointer.True(),
		},
		{
			Name:     "seller_name",
			Type:     "string",
			Optional: pointer.True(),
			Facet:    pointer.True(),
		},
		{
			Name:     "buyer",
			Type:     "string",
			Optional: pointer.True(),
			Facet:    pointer.True(),
		},
		{
			Name:     "buyer_name",
			Type:     "string",
			Optional: pointer.True(),
			Facet:    pointer.True(),
		},
		{
			Name:     "amount",
			Type:     "float",
			Optional: pointer.True(),
		},
		{
			Name:     "amount_type",
			Type:     "string",
			Optional: pointer.True(),
		},
		{
			Name: "nft_id",
			Type: "int64",
		},
		{
			Name:  "nft_type",
			Type:  "string",
			Facet: pointer.True(),
		},
		{
			Name:     "nft_grouping",
			Type:     "string",
			Facet:    pointer.True(),
			Optional: pointer.True(),
		},
		{
			Name: "nft_name",
			Type: "string",
		},
		{
			Name: "nft_thumbnail",
			Type: "string",
		},
		{
			Name:     "nft_rarity",
			Type:     "string",
			Facet:    pointer.True(),
			Optional: pointer.True(),
		},
		{
			Name:     "ends_at",
			Type:     "int64",
			Optional: pointer.True(),
		},
		{
			Name:     "auction_reserve_price",
			Type:     "float",
			Optional: pointer.True(),
		},
		{
			Name:  "listing_type",
			Type:  "string",
			Facet: pointer.True(),
		},
		{
			Name:  "status",
			Type:  "string",
			Facet: pointer.True(),
		},
		{
			Name: "updated_at",
			Type: "float",
		},
	}

	schema := &api.CollectionSchema{
		Name:                "market",
		Fields:              fields,
		DefaultSortingField: pointer.String("updated_at"),
	}

	_, err := client.Collections().Create(schema)
	if err != nil {
		panic(err)
	}

	schema2 := &api.CollectionSchema{
		Name:                "sold",
		Fields:              fields,
		DefaultSortingField: pointer.String("updated_at"),
	}

	_, err = client.Collections().Create(schema2)
	if err != nil {
		panic(err)
	}

}
