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

	//pub event ForSale(tenant: String, id: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, nft: FindMarket.NFTInfo, buyer:Address?, buyerName:String?)
	//nft: name, thumbnail, type
	//auctions:

	schema := &api.CollectionSchema{
		Name: "market",
		Fields: []api.Field{
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
				Type:     "String",
				Optional: pointer.True(),
				Facet:    pointer.True(),
			},
			{
				Name:     "buyer",
				Type:     "String",
				Optional: pointer.True(),
				Facet:    pointer.True(),
			},
			{
				Name:     "buyer_name",
				Type:     "String",
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
				Type:     "String",
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
				Name:  "listingType",
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
		},
		DefaultSortingField: pointer.String("updated_at"),
	}

	_, err := client.Collections().Create(schema)
	if err != nil {
		panic(err)
	}

}
