package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/typesense/typesense-go/typesense"
	"github.com/typesense/typesense-go/typesense/api"
)

const address = "8fcce1d764ef88dd"

func main() {
	forSaleEvents := fmt.Sprintf("A.%s.FindMarketSale.ForSale", address)
	forAuctionEvents := fmt.Sprintf("A.%s.FindMarketAuctionEscrow.ForAuction", address)
	directOfferEvents := fmt.Sprintf("A.%s.FindMarketDirectOfferEscrow.DirectOffer", address)

	forSaleName := fmt.Sprintf("A.%s.FIND.ForSale", address)
	forAuctionName := fmt.Sprintf("A.%s.FIND.ForAuction", address)
	directOfferName := fmt.Sprintf("A.%s.FIND.DirectOffer", address)
	marketEvents := []string{forSaleEvents, forAuctionEvents, directOfferEvents}

	nameEvents := []string{forSaleName, forAuctionName, directOfferName}

	sleepVar := os.Getenv("CRAWLER_SLEEP")
	sleep, err := time.ParseDuration(sleepVar)
	if err != nil {
		sleep = time.Second * 2
	}

	progressFile := "market.progress"
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

	marketCollection := client.Collection("market")
	soldCollection := client.Collection("sold")
	graffleUrl := "https://prod-test-net-dashboard-api.azurewebsites.net/api/company/04bd44ea-0ff1-44be-a5a0-e502802c56d8/search"
	urlTemplate := graffleUrl + "?since=%d"

	for {
		lastIndex, err := readProgressFromFile(progressFile)
		now := time.Now().Unix()
		if err == nil {
			graffleUrl = fmt.Sprintf(urlTemplate, lastIndex)
			fmt.Println("we are not first run")
		}

		fmt.Println(graffleUrl)
		events := getEventsFromGraffle(graffleUrl, marketEvents, nameEvents)

		latestEventsForIdentity := events.DedupOldItems()

		if len(latestEventsForIdentity) == 0 {
			log.Println("No results found")
			time.Sleep(sleep)
			continue
		}

		//we need to apply the items in the reverse order
		workQueue := latestEventsForIdentity.Reverse()
		for _, item := range workQueue {
			if item.IsSold() {
				count, err := marketCollection.Documents().Delete(&api.DeleteDocumentsParams{
					FilterBy: item.CreateDeleteQuery(),
				})
				if err != nil {
					panic(err)
				}
				fmt.Printf("removed %d number of items after sold item\n", count)
				item, err := soldCollection.Documents().Upsert(item.ToSoldItem())
				fmt.Printf("Insert  SOLD item %+v\n", item)
				if err != nil {
					panic(err)
				}

			} else if item.IsRemoved() {
				item, err := marketCollection.Document(item.SearchId()).Delete()
				fmt.Printf("Removing item %+v\n", item)
				if err != nil {
					fmt.Printf("removed document that can already be gone %v\n", err)
				}
			} else {
				//we insert or update the item
				item, err := marketCollection.Documents().Upsert(item.ToMarketItem())
				fmt.Printf("Insert item %+v\n", item)
				if err != nil {
					panic(err)
				}
			}
		}
		log.Println("Writing progress to file")
		writeProgressToFile(progressFile, now)
	}
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

func getEventsFromGraffle(url string, marketEvents []string, nameMarketEvents []string) MarketEvents {
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

	events := []FindEvent{}
	for _, field := range results {

		for _, candicate := range nameMarketEvents {
			if candicate == field.FlowEventID {
				var result NameEvent
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
		Amount              float64 `json:"amount"`
		AuctionReservePrice float64 `json:"auctionReservePrice,omitempty"`
		Buyer               string  `json:"buyer,omitempty"`
		BuyerName           string  `json:"buyerName,omitempty"`
		EndsAt              int64   `json:"endsAt,omitempty"`
		ID                  uint64  `json:"id"`
		Nft                 struct {
			ID                    uint64             `json:"id"`
			Name                  string             `json:"name"`
			Rarity                string             `json:"rarity,omitempty"`
			Thumbnail             string             `json:"thumbnail"`
			Type                  string             `json:"type"`
			Edition               string             `json:"editionNumber"`
			MaxEdition            string             `json:"totalInEdition,omitempty"`
			Scalars               map[string]float64 `json:"scalars,omnitempty"`
			Tags                  map[string]string  `json:"tags,omnitempty"`
			CollectionName        string             `json:"collectionName,omnitempty"`
			CollectionDescription string             `json:"collectionDescription,omitempty"`
		} `json:"nft"`
		Seller     string `json:"seller"`
		SellerName string `json:"sellerName,omitempty"`
		Status     string `json:"status"`
		Tenant     string `json:"tenant"`
		VaultType  string `json:"vaultType"`
	} `json:"blockEventData"`
}

type NameEvent struct {
	EventDate         time.Time `json:"eventDate"`
	FlowEventID       string    `json:"flowEventId"`
	FlowTransactionID string    `json:"flowTransactionId"`
	ID                string    `json:"id"`
	BlockEventData    struct {
		Name                string  `json:"name"`
		UUID                uint64  `json:"uuid"`
		Seller              string  `json:"seller"`
		SellerName          string  `json:"sellerName,omitempty"`
		Amount              float64 `json:"amount"`
		VaultType           string  `json:"vaultType"`
		Buyer               string  `json:"buyer,omitempty"`
		BuyerName           string  `json:"buyerName,omitempty"`
		ValidUntil          float64 `json:"validUntil,omitempty"`
		LockedUntil         float64 `json:"lockedUntil,omitempty"`
		AuctionReservePrice float64 `json:"auctionReservePrice,omitempty"`
		EndsAt              int64   `json:"endsAt,omitempty"`
		Status              string  `json:"status"`
	} `json:"blockEventData"`
}

func (event NameEvent) SearchId() string {
	return fmt.Sprintf("%s-%d", event.FlowEventID, event.BlockEventData.UUID)
}

func (me NameEvent) IsSold() bool {
	return me.BlockEventData.Status == "sold"
}

func (me NameEvent) Rarity() string {

	nameLength := len(me.BlockEventData.Name)

	var rarity string = "common"
	if nameLength == 3 {
		rarity = "epic"
	} else if nameLength == 4 {
		rarity = "rare"
	}
	return rarity
}

func (me NameEvent) IsRemoved() bool {
	status := me.BlockEventData.Status
	if status == "cancelled" || status == "failed" || status == "rejected" {
		return true
	}
	if strings.HasPrefix(status, "cancel") {
		return true
	}
	return false
}

func IntPointer(value int64) *int64 {
	if value == 0 {
		return nil
	}
	return &value
}
func StringPointer(value string) *string {
	if value == "" {
		return nil
	}
	return &value
}

func FloatPoitner(value float64) *float64 {
	if value == 0 {
		return nil
	}
	return &value
}

func (item NameEvent) ToSoldItem() map[string]interface{} {

	market := item.ToMarketItem()
	market["id"] = fmt.Sprintf("%s-%s", item.FlowEventID, item.BlockEventData.Name)
	return market
}

func (item NameEvent) ToMarketItem() map[string]interface{} {

	amountParts := strings.Split(".", item.BlockEventData.VaultType)
	amountAlias := amountParts[len(amountParts)-1]

	nameType := fmt.Sprintf("A.%s.FIND.Lease", address)
	listingParts := strings.Split(".", item.FlowEventID)
	listingAlias := listingParts[len(listingParts)]

	return map[string]interface{}{
		"id":                    item.SearchId(),
		"uuid":                  item.BlockEventData.UUID,
		"tenant":                "find",
		"seller":                item.BlockEventData.Seller,
		"seller_name":           StringPointer(item.BlockEventData.SellerName),
		"buyer":                 StringPointer(item.BlockEventData.Buyer),
		"buyer_name":            StringPointer(item.BlockEventData.BuyerName),
		"amount":                item.BlockEventData.Amount,
		"amount_type":           item.BlockEventData.VaultType,
		"amount_alias":          amountAlias,
		"nft_id":                item.BlockEventData.UUID,
		"collection_name":       "FIND",
		"collection_alias":      "FIND",
		"nft_rarity":            item.Rarity(),
		"nft_name":              item.BlockEventData.Name,
		"nft_type":              nameType,
		"nft_alias":             "Lease",
		"ends_at":               IntPointer(item.BlockEventData.EndsAt),
		"auction_reserve_price": FloatPoitner(item.BlockEventData.AuctionReservePrice),
		"listing_type":          item.FlowEventID, //todo FIX?
		"listing_alias":         listingAlias,     //todo FIX?
		"status":                item.BlockEventData.Status,
		"number_valid_until":    item.BlockEventData.ValidUntil,
		"number_locked_until":   item.BlockEventData.LockedUntil,
		"transaction_hash":      item.FlowTransactionID,
		"updated_at":            time.Now().Unix(),
	}
}

func (me NameEvent) CreateDeleteQuery() *string {
	value := fmt.Sprintf("uuid:=%d", me.BlockEventData.UUID)
	return &value
}

func (event MarketEvent) SearchId() string {
	return fmt.Sprintf("%s-%d-%s", event.FlowEventID, event.BlockEventData.ID, event.BlockEventData.Tenant)
}

func (me MarketEvent) IsSold() bool {
	return me.BlockEventData.Status == "sold"
}

func (me MarketEvent) IsRemoved() bool {
	status := me.BlockEventData.Status
	if status == "cancelled" || status == "failed" || status == "rejected" {
		return true
	}
	if strings.HasPrefix(status, "cancel") {
		return true
	}
	return false
}

func (item MarketEvent) ToSoldItem() map[string]interface{} {
	market := item.ToMarketItem()
	market["id"] = fmt.Sprintf("%s-%d", item.FlowEventID, item.BlockEventData.ID)
	return market
}

func (item MarketEvent) ToMarketItem() map[string]interface{} {

	amountParts := strings.Split(".", item.BlockEventData.VaultType)
	amountAlias := amountParts[len(amountParts)-1]

	nameParts := strings.Split(".", item.BlockEventData.Nft.Type)
	nameAlias := amountParts[len(nameParts)-1]

	listingParts := strings.Split(".", item.FlowEventID)
	listingAlias := listingParts[len(listingParts)]
	collection := StringPointer(item.BlockEventData.Nft.CollectionName)

	var collectionAlias = StringPointer(item.BlockEventData.Nft.CollectionDescription)

	if collection == nil {
		collection = &nameAlias
	}

	if collectionAlias == nil {
		collectionAlias = &nameAlias
	}

	standard := map[string]interface{}{
		"id":                    item.SearchId(),
		"uuid":                  item.BlockEventData.ID,
		"tenant":                item.BlockEventData.Tenant,
		"seller":                item.BlockEventData.Seller,
		"seller_name":           StringPointer(item.BlockEventData.SellerName),
		"buyer":                 StringPointer(item.BlockEventData.Buyer),
		"buyer_name":            StringPointer(item.BlockEventData.BuyerName),
		"amount":                item.BlockEventData.Amount,
		"amount_type":           item.BlockEventData.VaultType,
		"amount_alias":          amountAlias,
		"nft_id":                item.BlockEventData.Nft.ID,
		"nft_name":              item.BlockEventData.Nft.Name,
		"nft_type":              item.BlockEventData.Nft.Type,
		"nft_alias":             nameAlias,
		"collection_name":       *collection,
		"collection_alias":      *collectionAlias,
		"nft_thumbnail":         StringPointer(item.BlockEventData.Nft.Thumbnail),
		"nft_rarity":            StringPointer(item.BlockEventData.Nft.Rarity),
		"nft_edition":           StringPointer(item.BlockEventData.Nft.Edition),
		"nft_max_edition":       StringPointer(item.BlockEventData.Nft.MaxEdition),
		"ends_at":               IntPointer(item.BlockEventData.EndsAt),
		"auction_reserve_price": FloatPoitner(item.BlockEventData.AuctionReservePrice),
		"listing_type":          item.FlowEventID,
		"listing_alias":         listingAlias,
		"transaction_hash":      item.FlowTransactionID,
		"status":                item.BlockEventData.Status,
		"updated_at":            item.EventDate,
	}

	for key, value := range item.BlockEventData.Nft.Scalars {
		standard[fmt.Sprintf("number_%s", key)] = value
	}

	for key, value := range item.BlockEventData.Nft.Tags {
		standard[fmt.Sprintf("string_%s", key)] = value
	}

	return standard
}

func (me MarketEvent) CreateDeleteQuery() *string {
	value := fmt.Sprintf("uuid:=%d", me.BlockEventData.ID)
	return &value
}

type FindEvent interface {
	CreateDeleteQuery() *string
	IsRemoved() bool
	IsSold() bool
	SearchId() string
	ToMarketItem() map[string]interface{}
	ToSoldItem() map[string]interface{}
}

type MarketEvents []FindEvent

func (me MarketEvents) Reverse() MarketEvents {
	for i, j := 0, len(me)-1; i < j; i, j = i+1, j-1 {
		me[i], me[j] = me[j], me[i]
	}
	return me
}

func (me MarketEvents) DedupOldItems() MarketEvents {
	dedupedEvents := MarketEvents{}
	seen := map[string]bool{}
	for _, event := range me {
		id := event.SearchId()
		_, ok := seen[id]
		if !ok {
			seen[id] = true
			dedupedEvents = append(dedupedEvents, event)
		}
	}
	return dedupedEvents
}
