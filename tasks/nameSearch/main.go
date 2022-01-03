package main

//TODO: send mail https://medium.com/vacatronics/how-to-use-gmail-with-go-c980295c23b8

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/bjartek/overflow/overflow"
	"github.com/meirf/gopart"
	"github.com/typesense/typesense-go/typesense"
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
	nameDocuments := client.Collection("names").Documents()
	of := overflow.NewOverflowMainnet().Start()

	names := readCsvFile("names.txt")
	fmt.Printf("Names is %d long", len(names))

	var fullResult []SearchResult
	size := 400
	for idxRange := range gopart.Partition(len(names), size) {
		//run transaction against flow
		fmt.Printf("Processing %d to %d\n", idxRange.Low, idxRange.High)
		var result []NameResult
		names := names[idxRange.Low:idxRange.High]
		err := of.ScriptFromFile("nameCrawler").
			Args(of.Arguments().StringArray(names...)).
			RunMarshalAs(&result)
		if err != nil {
			panic(err)
		}

		for _, item := range result {

			if *item.Address == "0x9a86f2493ce2e9d" {
				item.Status = "RESERVED"
			}

			if item.SalePrice != "" {
				item.Status = "FOR_SALE"
			}

			if item.AuctionStartPrice != "" {
				if item.LatestBid == "" {
					item.Status = "FOR_AUCTION"
				} else {
					item.Status = "ONGOING_AUCTION"
				}
			} else if item.LatestBid != "" {
				item.Status = "DIRECT_OFFER"
			}

			latestBidBy := &item.LatestBidBy
			if item.LatestBidBy == "" {
				latestBidBy = nil
			}
			result := SearchResult{
				AuctionEnds:         CadenceUFix64StringToInt64(item.AuctionEnds),
				AuctionReservePrice: CadenceUFixStringToFloat(item.AuctionReservePrice),
				AuctionStartPrice:   CadenceUFixStringToFloat(item.AuctionStartPrice),
				LatestBid:           CadenceUFixStringToFloat(item.LatestBid),
				LatestBidBy:         latestBidBy,
				LockedUntil:         *CadenceUFix64StringToInt64(item.LockedUntil),
				Name:                item.Name,
				Id:                  item.Name,
				SalePrice:           CadenceUFixStringToFloat(item.SalePrice),
				Status:              item.Status,
				ValidUntil:          *CadenceUFix64StringToInt64(item.ValidUntil),
			}

			if *item.Address != "" {
				result.Address = item.Address
			}
			nameDocuments.Upsert(result)
			fullResult = append(fullResult, result)
		}
	}

	file, _ := json.MarshalIndent(fullResult, "", "   ")
	_ = ioutil.WriteFile("list.json", file, 0644)

}

func CadenceUFix64StringToInt64(value string) *int64 {

	if value == "" {
		return nil
	}
	parts := strings.Split(value, ".")

	res, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		panic(err)
	}
	return &res
}

func CadenceUFixStringToFloat(value string) *float64 {
	if value == "" {
		return nil
	}

	s, err := strconv.ParseFloat(value, 32)
	if err != nil {
		panic(err)
	}
	return &s
}

type NameResult struct {
	Address             *string `json:"address"`
	AuctionEnds         string  `json:"auctionEnds"`
	AuctionReservePrice string  `json:"auctionReservePrice"`
	AuctionStartPrice   string  `json:"auctionStartPrice"`
	LatestBid           string  `json:"latestBid"`
	LatestBidBy         string  `json:"latestBidBy"`
	LockedUntil         string  `json:"lockedUntil"`
	Name                string  `json:"name"`
	SalePrice           string  `json:"salePrice"`
	Status              string  `json:"status"`
	ValidUntil          string  `json:"validUntil"`
}

type SearchResult struct {
	Id                  string   `json:"id"`
	Address             *string  `json:"address"`
	AuctionEnds         *int64   `json:"auction_ends,omitempty"`
	AuctionReservePrice *float64 `json:"auction_reserve_price,omitempty"`
	AuctionStartPrice   *float64 `json:"auction_start_price,omitempty"`
	LatestBid           *float64 `json:"latest_bid,omitempty"`
	LatestBidBy         *string  `json:"latest_bid_by,omitempty"`
	LockedUntil         int64    `json:"locked_until"`
	Name                string   `json:"name"`
	SalePrice           *float64 `json:"sale_price,omitempty"`
	Status              string   `json:"status"`
	ValidUntil          int64    `json:"valid_until"`
}

func writeProgressToFile(fileName string, blockHeight uint64) error {
	err := ioutil.WriteFile(fileName, []byte(fmt.Sprintf("%d", blockHeight)), 0644)
	if err != nil {
		return fmt.Errorf("Could not create initial progress file %v", err)
	}
	return nil
}

func readProgressFromFile(fileName string) (int64, error) {
	dat, err := ioutil.ReadFile(fileName)
	if err != nil {
		return 0, fmt.Errorf("ProgressFile is not valid %v", err)
	}

	stringValue := strings.TrimSpace(string(dat))

	return strconv.ParseInt(stringValue, 10, 64)

}
