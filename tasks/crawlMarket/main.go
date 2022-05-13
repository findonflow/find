package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/typesense/typesense-go/typesense"
)

type MarketEvents []MarketEvent
type GroupedEvents map[string]MarketEvents

func (groupedEvents GroupedEvents) Partition() (changed, removed, sold MarketEvents) {
	eventsToIndex := MarketEvents{}
	eventsSold := MarketEvents{}
	eventsToDelete := MarketEvents{}
	for _, events := range groupedEvents {

		sort.SliceStable(events, func(i, j int) bool {
			return events[i].EventDate.UnixMilli() > events[j].EventDate.UnixMilli()
		})

		status := events[0].BlockEventData.Status
		//Need to find delisted as well
		if status == "sold" {
			eventsToDelete = append(eventsToDelete, events[0])
			eventsSold = append(eventsSold, events[0])
		} else if status == "cancelled" || status == "failed" || status == "rejected" {
			eventsToDelete = append(eventsToDelete, events[0])
		} else if strings.HasPrefix(status, "cancel") {
			eventsToDelete = append(eventsToDelete, events[0])
		} else {
			for _, event := range events {
				if strings.Contains(event.FlowEventID, "DirectOffer") {
					continue
				}
				eventsToIndex = append(eventsToIndex, event)
				break
			}
		}
	}
	return eventsToIndex, eventsToDelete, eventsSold
}

func (me MarketEvents) GroupEvents() GroupedEvents {
	groupedEvents := GroupedEvents{}
	for _, event := range me {
		//TODO this needs to be <type>-uuid-tenant
		id := event.SearchId()
		var group MarketEvents
		group, ok := groupedEvents[id]
		if !ok {
			group = MarketEvents{}
		}

		group = append(group, event)
		groupedEvents[id] = group
	}
	return groupedEvents
}

func main() {
	address := "8fcce1d764ef88dd"
	forSaleEvents := fmt.Sprintf("A.%s.FindMarketSale.ForSale", address)
	forAuctionEvents := fmt.Sprintf("A.%s.FindMarketAuctionEscrow.ForAuction", address)
	directOfferEvents := fmt.Sprintf("A.%s.FindMarketDirectOfferEscrow.DirectOffer", address)

	marketEvents := []string{forSaleEvents, forAuctionEvents, directOfferEvents}

	sleepVar := os.Getenv("CRAWLER_SLEEP")
	sleep, err := time.ParseDuration(sleepVar)
	if err != nil {
		sleep = time.Second * 2
	}

	key := os.Getenv("TYPESENSE_FIND_ADMIN")
	url := os.Getenv("TYPESENSE_FIND_URL")
	progressFile := "market.progress"
	client := typesense.NewClient(
		typesense.WithServer(url),
		typesense.WithAPIKey(key),
		typesense.WithConnectionTimeout(5*time.Second),
		typesense.WithCircuitBreakerMaxRequests(50),
		typesense.WithCircuitBreakerInterval(2*time.Minute),
		typesense.WithCircuitBreakerTimeout(1*time.Minute),
	)

	urlTemplate := "https://prod-test-net-dashboard-api.azurewebsites.net/api/company/04bd44ea-0ff1-44be-a5a0-e502802c56d8/search?since=%d"
	for {
		lastIndex, err := readProgressFromFile(progressFile)
		now := time.Now().Unix()
		firstRun := true
		graffleUrl := "https://prod-test-net-dashboard-api.azurewebsites.net/api/company/04bd44ea-0ff1-44be-a5a0-e502802c56d8/search"
		if err == nil {
			graffleUrl = fmt.Sprintf(urlTemplate, lastIndex)
			firstRun = false
			fmt.Println("we are not first run")
		}

		events := getEventsFromGraffle(graffleUrl, marketEvents)
		groupedEvents := events.GroupEvents()

		//Ignore events sold for now
		eventsToIndex, eventsToDelete, _ := groupedEvents.Partition()
		if len(eventsToIndex) == 0 && len(eventsToDelete) == 0 {
			log.Println("No results found Writing progress to file")
			writeProgressToFile(progressFile, now)
			time.Sleep(sleep)
		}

		marketCollection := client.Collection("market")

		if firstRun {
			log.Printf("Ignore %d number of events to delete for now since we are running new dump\n", len(eventsToDelete))
		} else {
			for _, event := range eventsToDelete {
				res, err := marketCollection.Document(fmt.Sprintf("%d", event.BlockEventData.ID)).Delete()
				if err != nil {
					log.Fatalf("Could not delete document with id %d, %v", event.BlockEventData.ID, err)
				} else {
					log.Printf("Delete document with result %v\n", res)
				}

			}
		}

		market := marketCollection.Documents()
		for _, item := range eventsToIndex {
			searchElement := SearchResult{
				Id:                  item.SearchId(),
				UUID:                item.BlockEventData.ID,
				Tenant:              item.BlockEventData.Tenant,
				Seller:              item.BlockEventData.Seller,
				SellerName:          item.SellerName(),
				Buyer:               item.Buyer(),
				BuyerName:           item.BuyerName(),
				Amount:              item.BlockEventData.Amount,
				AmountType:          item.BlockEventData.VaultType,
				NFTID:               item.BlockEventData.Nft.ID,
				NFTName:             item.BlockEventData.Nft.Name,
				NFTType:             item.BlockEventData.Nft.Type,
				NFTThumbnail:        item.BlockEventData.Nft.Thumbnail,
				NFTGrouping:         item.Grouping(),
				NFTRarity:           item.Rarity(),
				AuctionEnds:         item.AuctionEnds(),
				AuctionReservePrice: item.AuctionReservePrice(),
				ListingType:         item.FlowEventID, //todo FIX?
				Status:              item.BlockEventData.Status,
				UpdatedAt:           time.Now().Unix(),
			}

			log.Printf("Inserted document %+v\n", searchElement)
			_, err := market.Upsert(searchElement)
			if err != nil {
				panic(err)
			}
		}

		log.Println("Writing progress to file")
		writeProgressToFile(progressFile, now)
	}
}

type SearchResult struct {
	Id                  string   `json:"id"`
	UUID                uint64   `json:"uuid"`
	Tenant              string   `json:"tenant"`
	Seller              string   `json:"seller"`
	SellerName          *string  `json:"seller_name,omitempty"`
	Buyer               *string  `json:"buyer,omitempty"`
	BuyerName           *string  `json:"buyer_name,omitempty"`
	Amount              float64  `json:"amount"`
	AmountType          string   `json:"amount_type"`
	NFTID               uint64   `json:"nft_id"`
	NFTType             string   `json:"nft_type"`
	NFTName             string   `json:"nft_name"`
	NFTThumbnail        string   `json:"nft_thumbnail"`
	NFTGrouping         *string  `json:"nft_grouping"`
	NFTRarity           *string  `json:"nft_rarity"`
	AuctionEnds         *int64   `json:"auction_ends,omitempty"`
	AuctionReservePrice *float64 `json:"auction_reserve_price,omitempty"`
	ListingType         string   `json:"listing_type"`
	Status              string   `json:"status"`
	UpdatedAt           int64    `json:"updated_at"`
}

func writeProgressToFile(fileName string, blockHeight int64) error {
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

func getEventsFromGraffle(url string, marketEvents []string) MarketEvents {
	graffleClient := http.Client{
		Timeout: time.Second * 2, // Timeout after 2 seconds
	}

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		log.Fatal(err)
	}

	req.Header.Set("User-Agent", ".find market crawler")

	res, getErr := graffleClient.Do(req)
	if getErr != nil {
		log.Fatal(getErr)
	}

	if res.Body != nil {
		defer res.Body.Close()
	}

	body, readErr := ioutil.ReadAll(res.Body)
	if readErr != nil {
		log.Fatal(readErr)
	}

	var results []Event
	jsonErr := json.Unmarshal(body, &results)
	if jsonErr != nil {
		log.Fatal(jsonErr)
	}

	events := []MarketEvent{}
	for _, field := range results {

		for _, candicate := range marketEvents {
			if candicate == field.FlowEventID {
				var result MarketEvent
				obj, err := json.Marshal(field)
				if err != nil {
					panic(err)
				}
				jsonErr := json.Unmarshal(obj, &result)
				if jsonErr != nil {
					log.Fatal(jsonErr)
				}
				events = append(events, result)
			}
		}
	}
	return events

}

type Event struct {
	BlockEventData    interface{}
	EventDate         time.Time `json:"eventDate"`
	FlowEventID       string    `json:"flowEventId"`
	FlowTransactionID string    `json:"flowTransactionId"`
	ID                string    `json:"id"`
}

type MarketEvent struct {
	EventDate         time.Time `json:"eventDate"`
	FlowEventID       string    `json:"flowEventId"`
	FlowTransactionID string    `json:"flowTransactionId"`
	ID                string    `json:"id"`
	BlockEventData    struct {
		Amount              float64   `json:"amount"`
		AuctionReservePrice float64   `json:"auctionReservePrice,omitempty"`
		Buyer               string    `json:"buyer,omitempty"`
		BuyerName           string    `json:"buyerName,omitempty"`
		EndsAt              time.Time `json:"endsAt,omitempty"`
		ID                  uint64    `json:"id"`
		Nft                 struct {
			Grouping  string `json:"grouping,omitempty"`
			ID        uint64 `json:"id"`
			Name      string `json:"name"`
			Rarity    string `json:"rarity,omitempty"`
			Thumbnail string `json:"thumbnail"`
			Type      string `json:"type"`
		} `json:"nft"`
		Seller     string `json:"seller"`
		SellerName string `json:"sellerName,omitempty"`
		Status     string `json:"status"`
		Tenant     string `json:"tenant"`
		VaultType  string `json:"vaultType"`
	} `json:"blockEventData"`
}

func (event MarketEvent) SearchId() string {
	return fmt.Sprintf("%s-%d-%s", event.FlowEventID, event.BlockEventData.ID, event.BlockEventData.Tenant) //this is uuid of item
}

func (me MarketEvent) SellerName() *string {
	if me.BlockEventData.SellerName == "" {
		return nil
	}
	return &me.BlockEventData.SellerName
}

func (me MarketEvent) BuyerName() *string {
	if me.BlockEventData.BuyerName == "" {
		return nil
	}
	return &me.BlockEventData.BuyerName
}

func (me MarketEvent) Buyer() *string {
	if me.BlockEventData.Buyer == "" {
		return nil
	}
	return &me.BlockEventData.Buyer
}

func (me MarketEvent) Grouping() *string {
	if me.BlockEventData.Nft.Grouping == "" {
		return nil
	}
	return &me.BlockEventData.Nft.Grouping
}

func (me MarketEvent) Rarity() *string {
	if me.BlockEventData.Nft.Rarity == "" {
		return nil
	}
	return &me.BlockEventData.Nft.Rarity
}

func (me MarketEvent) AuctionEnds() *int64 {
	if me.BlockEventData.EndsAt.IsZero() {
		return nil
	}
	unix := me.BlockEventData.EndsAt.Unix()
	return &unix
}

func (me MarketEvent) AuctionReservePrice() *float64 {
	if me.BlockEventData.AuctionReservePrice == 0 {
		return nil
	}
	return &me.BlockEventData.AuctionReservePrice
}
