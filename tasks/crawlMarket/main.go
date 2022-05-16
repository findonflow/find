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

func main() {
	address := "8fcce1d764ef88dd"
	forSaleEvents := fmt.Sprintf("A.%s.FindMarketSale.ForSale", address)
	forAuctionEvents := fmt.Sprintf("A.%s.FindMarketAuctionEscrow.ForAuction", address)
	directOfferEvents := fmt.Sprintf("A.%s.FindMarketDirectOfferEscrow.DirectOffer", address)

	forSaleName := fmt.Sprintf("A.%s.FINF.ForSale", address)
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
				item, err := soldCollection.Documents().Upsert(item.ToMarketItem())
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

type MarketItem struct {
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
	EndsAt              *int64   `json:"ends_at,omitempty"`
	AuctionReservePrice *float64 `json:"auction_reserve_price,omitempty"`
	ListingType         string   `json:"listing_type"`
	Status              string   `json:"status"`
	UpdatedAt           int64    `json:"updated_at"`
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

type NameEvent struct {
	EventDate         time.Time `json:"eventDate"`
	FlowEventID       string    `json:"flowEventId"`
	FlowTransactionID string    `json:"flowTransactionId"`
	ID                string    `json:"id"`
	BlockEventData    struct {
		Name                string    `json:"name"`
		UUID                uint64    `json:"uuid"`
		Seller              string    `json:"seller"`
		SellerName          string    `json:"sellerName,omitempty"`
		Amount              float64   `json:"amount"`
		VaultType           string    `json:"vaultType"`
		Buyer               string    `json:"buyer,omitempty"`
		BuyerName           string    `json:"buyerName,omitempty"`
		ValidUntil          float64   `json:"validUntil,omitempty"`
		LockedUntil         float64   `json:"lockedUntil,omitempty"`
		AuctionReservePrice float64   `json:"auctionReservePrice,omitempty"`
		EndsAt              time.Time `json:"endsAt,omitempty"`
		Status              string    `json:"status"`
	} `json:"blockEventData"`
}

func (event NameEvent) SearchId() string {
	return fmt.Sprintf("%s-%d", event.FlowEventID, event.BlockEventData.UUID)
}

func (me NameEvent) SellerName() *string {
	if me.BlockEventData.SellerName == "" {
		return nil
	}
	return &me.BlockEventData.SellerName
}

func (me NameEvent) BuyerName() *string {
	if me.BlockEventData.BuyerName == "" {
		return nil
	}
	return &me.BlockEventData.BuyerName
}

func (me NameEvent) Buyer() *string {
	if me.BlockEventData.Buyer == "" {
		return nil
	}
	return &me.BlockEventData.Buyer
}

func (me NameEvent) AuctionEnds() *int64 {
	if me.BlockEventData.EndsAt.IsZero() {
		return nil
	}
	unix := me.BlockEventData.EndsAt.Unix()
	return &unix
}

func (me NameEvent) AuctionReservePrice() *float64 {
	if me.BlockEventData.AuctionReservePrice == 0 {
		return nil
	}
	return &me.BlockEventData.AuctionReservePrice
}

func (me NameEvent) IsSold() bool {
	return me.BlockEventData.Status == "sold"
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

func (item NameEvent) ToMarketItem() interface{} {
	return MarketItem{
		Id:                  item.SearchId(),
		UUID:                item.BlockEventData.UUID,
		Tenant:              "find",
		Seller:              item.BlockEventData.Seller,
		SellerName:          item.SellerName(),
		Buyer:               item.Buyer(),
		BuyerName:           item.BuyerName(),
		Amount:              item.BlockEventData.Amount,
		AmountType:          item.BlockEventData.VaultType,
		NFTID:               item.BlockEventData.UUID,
		NFTName:             item.BlockEventData.Name,
		NFTType:             "FindName",
		NFTThumbnail:        "",
		NFTGrouping:         nil,
		NFTRarity:           nil,
		EndsAt:              item.AuctionEnds(),
		AuctionReservePrice: item.AuctionReservePrice(),
		ListingType:         item.FlowEventID, //todo FIX?
		Status:              item.BlockEventData.Status,
		UpdatedAt:           time.Now().Unix(),
	}
}

func (me NameEvent) CreateDeleteQuery() *string {
	value := fmt.Sprintf("uuid:=%d", me.BlockEventData.UUID)
	return &value
}

func (event MarketEvent) SearchId() string {
	return fmt.Sprintf("%s-%d-%s", event.FlowEventID, event.BlockEventData.ID, event.BlockEventData.Tenant)
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

func (item MarketEvent) ToMarketItem() interface{} {
	return MarketItem{
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
		EndsAt:              item.AuctionEnds(),
		AuctionReservePrice: item.AuctionReservePrice(),
		ListingType:         item.FlowEventID, //todo FIX?
		Status:              item.BlockEventData.Status,
		UpdatedAt:           time.Now().Unix(),
	}
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
	ToMarketItem() interface{}
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
