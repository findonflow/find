package test_main

import (
	"fmt"
	"strconv"
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

type OverflowTestUtils struct {
	T *testing.T
	O *overflow.Overflow
}

func NewOverflowTest(t *testing.T) *OverflowTestUtils {
	return &OverflowTestUtils{T: t, O: overflow.NewTestingEmulator().Start()}
}

const leaseDurationFloat = 31536000.0
const lockDurationFloat = 7776000.0
const auctionDurationFloat = 86400.0

func (otu *OverflowTestUtils) assertLookupAddress(user, expected string) {
	value := otu.O.Script(`import FIND from "../contracts/FIND.cdc"
pub fun main(name: String) :  Address? {
    return FIND.lookupAddress(name)
}
		`).
		Args(otu.O.Arguments().String(user)).RunReturnsInterface()

	assert.Equal(otu.T, expected, value)
}

func (otu *OverflowTestUtils) setupFIND() *OverflowTestUtils {
	//first step create the adminClient as the fin user

	otu.O.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find").
		Test(otu.T).AssertSuccess().AssertNoEvents()

	//link in the server in the versus client
	otu.O.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().Account("find")).
		Test(otu.T).AssertSuccess().AssertNoEvents()

	//set up fin network as the fin user
	otu.O.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("find").
		Test(otu.T).AssertSuccess().AssertNoEvents()

	otu.O.TransactionFromFile("setup_find_market_1").
		SignProposeAndPayAsService().
		Test(otu.T).AssertSuccess().AssertNoEvents()

	//link in the server in the versus client
	otu.O.TransactionFromFile("setup_find_market_2").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().Account("account").Boolean(true).Boolean(true)).
		Test(otu.T).AssertSuccess().AssertNoEvents()

	otu.createUser(100.0, "account")

	return otu.tickClock(1.0)
}

func (otu *OverflowTestUtils) tickClock(time float64) *OverflowTestUtils {
	otu.O.TransactionFromFile("clock").SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			UFix64(time)).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) createUser(fusd float64, name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("createProfile").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().String(name)).
		Test(otu.T).
		AssertSuccess()

	otu.O.TransactionFromFile("mintFusd").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account(name).
			UFix64(fusd)).
		Test(otu.T).
		AssertSuccess().
		AssertEventCount(3)

	otu.O.TransactionFromFile("mintFlow").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account(name).
			UFix64(fusd)).
		Test(otu.T).
		AssertSuccess().
		AssertEventCount(3)

	return otu
}

func (otu *OverflowTestUtils) registerUser(name string) *OverflowTestUtils {
	otu.registerUserTransaction(name)
	return otu
}

func (otu *OverflowTestUtils) registerUserTransaction(name string) overflow.TransactionResult {
	nameAddress := otu.accountAddress(name)
	expireTime := otu.currentTime() + leaseDurationFloat
	expireTimeString := fmt.Sprintf("%f00", expireTime)

	lockedTime := otu.currentTime() + leaseDurationFloat + lockDurationFloat
	lockedTimeString := fmt.Sprintf("%f00", lockedTime)

	return otu.O.TransactionFromFile("register").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			String(name).
			UFix64(5.0)).
		Test(otu.T).
		AssertSuccess().
		AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Register", map[string]interface{}{
			"validUntil":  expireTimeString,
			"lockedUntil": lockedTimeString,
			"owner":       nameAddress,
			"name":        name,
		})).
		AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
			"amount": "5.00000000",
			"to":     "0x1cf0e2f2f715450",
		})).
		AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
			"amount": "5.00000000",
			"from":   nameAddress,
		}))

}

func (out *OverflowTestUtils) currentTime() float64 {
	value, err := out.O.Script(`import Clock from "../contracts/Clock.cdc"
pub fun main() :  UFix64 {
    return Clock.time()
}`).RunReturns()
	assert.NoErrorf(out.T, err, "Could not execute script")
	currentTime := value.String()
	res, err := strconv.ParseFloat(currentTime, 64)
	assert.NoErrorf(out.T, err, "Could not parse as float")
	return res
}

func (otu *OverflowTestUtils) accountAddress(name string) string {
	return fmt.Sprintf("0x%s", otu.O.Account(name).Address().String())
}

func (otu *OverflowTestUtils) listForSale(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("listForSale").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			String(name).
			UFix64(10.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
			"directSellPrice": "10.00000000",
			"active":          "true",
			"name":            name,
			"owner":           otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) directOffer(buyer, name string, amount float64) *OverflowTestUtils {
	otu.O.TransactionFromFile("bid").SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			String(name).
			UFix64(amount)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.DirectOffer", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", amount),
			"bidder": otu.accountAddress(buyer),
			"name":   name,
		}))

	return otu
}

func (otu *OverflowTestUtils) listForAuction(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("listForAuction").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			String(name).
			UFix64(5.0).  //startAuctionPrice
			UFix64(20.0). //reserve price
			UFix64(auctionDurationFloat).
			UFix64(300.0)). //extention on late bid
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForAuction", map[string]interface{}{
			"auctionStartPrice":   "5.00000000",
			"auctionReservePrice": "20.00000000",
			"active":              "true",
			"name":                name,
			"owner":               otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) bid(buyer, name string, amount float64) *OverflowTestUtils {

	endTime := otu.currentTime() + auctionDurationFloat
	endTimeSting := fmt.Sprintf("%f00", endTime)
	otu.O.TransactionFromFile("bid").SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			String(name).
			UFix64(amount)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
			"amount":       fmt.Sprintf("%.8f", amount),
			"auctionEndAt": endTimeSting,
			"bidder":       otu.accountAddress(buyer),
			"name":         name,
		}))
	return otu
}

func (otu *OverflowTestUtils) auctionBid(buyer, name string, amount float64) *OverflowTestUtils {

	endTime := otu.currentTime() + auctionDurationFloat
	endTimeSting := fmt.Sprintf("%f00", endTime)
	otu.O.TransactionFromFile("bid").SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			String(name).
			UFix64(amount)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionBid", map[string]interface{}{
			"amount":       fmt.Sprintf("%.8f", amount),
			"auctionEndAt": endTimeSting,
			"bidder":       otu.accountAddress(buyer),
			"name":         name,
		}))
	return otu
}

func (otu *OverflowTestUtils) expireAuction() *OverflowTestUtils {
	return otu.tickClock(auctionDurationFloat)
}

func (otu *OverflowTestUtils) expireLease() *OverflowTestUtils {
	return otu.tickClock(leaseDurationFloat)
}

func (otu *OverflowTestUtils) expireLock() *OverflowTestUtils {
	return otu.tickClock(lockDurationFloat)
}

func (otu *OverflowTestUtils) setupCharity(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("createCharity").SignProposeAndPayAs(user).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) mintCharity(name, image, thumbnail, originUrl, description, user string) *OverflowTestUtils {

	otu.O.TransactionFromFile("mintCharity").SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			String(name).
			String(image).
			String(thumbnail).
			String(description).
			String(originUrl).
			Account(user)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.CharityNFT.Minted", map[string]interface{}{
			"to": otu.accountAddress(user),
		}))

	return otu
}

func (otu *OverflowTestUtils) mintThreeExampleDandies() []uint64 {
	result := otu.O.TransactionFromFile("mintDandy").
		SignProposeAndPayAs("user1").
		Args(otu.O.Arguments().
			String("user1").
			UInt64(3).
			String("Neo").
			String("Neo Motorcycle").
			String(`Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`).
			String("https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp")).
		Test(otu.T).
		AssertSuccess().AssertEventCount(6).
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.Dandy.Minted", map[string]interface{}{
			"description": "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
			"minter":      "user1",
			"name":        "Neo Motorcycle 3 of 3",
		}))
	dandyIds := []uint64{}
	for _, event := range result.Events {
		if event.Name == "A.f8d6e0586b0a20c7.Dandy.Deposit" {
			dandyIds = append(dandyIds, event.GetFieldAsUInt64("id"))
		}
	}

	return dandyIds
}

func (otu *OverflowTestUtils) buyForge(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("buyAddon").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().String(user).String("forge").UFix64(50.0)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AddonActivated", map[string]interface{}{
			"name":  user,
			"addon": "forge",
		}))

	return otu
}

func (otu *OverflowTestUtils) setupDandy(user string) *OverflowTestUtils {
	return otu.createUser(100.0, user).
		registerUser(user).
		buyForge(user)
}

func (otu *OverflowTestUtils) listDandyForSale(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("listDandyForSale").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.ForSale", map[string]interface{}{
			"active": "true",
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"owner":  otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) listDandyForAuction(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("listDandyForAuction").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.ForAuction", map[string]interface{}{
			"active":              "true",
			"amount":              fmt.Sprintf("%.8f", price),
			"auctionReservePrice": fmt.Sprintf("%.8f", price+5.0),
			"id":                  fmt.Sprintf("%d", id),
			"owner":               otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) checkRoyalty(name string, id uint64, royaltyName string, expectedPlatformRoyalty float64) *OverflowTestUtils {

	royalty := Royalty{}
	otu.O.ScriptFromFile("dandy").
		Args(otu.O.Arguments().
			String(name).
			UInt64(id).
			String("A.f8d6e0586b0a20c7.MetadataViews.Royalties")).
		RunMarshalAs(&royalty)

	for _, item := range royalty.Items {
		if item.Description == royaltyName {
			assert.Equal(otu.T, fmt.Sprintf("%.8f", expectedPlatformRoyalty), item.Cut)

			return otu
		}
	}

	assert.Equal(otu.T, expectedPlatformRoyalty, 0.0)
	return otu

}

func (otu *OverflowTestUtils) buyDandyForSale(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidMarket").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account(seller).
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.Sold", map[string]interface{}{
			"amount":        fmt.Sprintf("%.8f", price),
			"id":            fmt.Sprintf("%d", id),
			"previousOwner": otu.accountAddress(seller),
			"newOwner":      otu.accountAddress(name),
		}))
		//TODO: test better events
	return otu
}

func (otu *OverflowTestUtils) auctionBidMarket(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidMarket").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account(seller).
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.AuctionStarted", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"bidder": otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) directOfferMarket(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidMarket").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account(seller).
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.DirectOfferBid", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"bidder": otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferMarket(name string, id uint64, buyer string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketDirectOffer").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.Sold", map[string]interface{}{
			"id":            fmt.Sprintf("%d", id),
			"previousOwner": otu.accountAddress(name),
			"newOwner":      otu.accountAddress(buyer),
			"amount":        fmt.Sprintf("%.8f", price),
		}))
		//TODO: test better events
	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuction(name string, id uint64, buyer string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketAuction").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account(name).
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.Sold", map[string]interface{}{
			"id":            fmt.Sprintf("%d", id),
			"previousOwner": otu.accountAddress(name),
			"newOwner":      otu.accountAddress(buyer),
			"amount":        fmt.Sprintf("%.8f", price),
		}))
		//TODO: test better events
	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionCancelled(name string, id uint64, buyer string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketAuction").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account(name).
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.AuctionCancelled", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"bidder": otu.accountAddress(buyer),
			"amount": fmt.Sprintf("%.8f", price),
		}))
		//TODO: test better events
	return otu
}

type Royalty struct {
	Items []struct {
		Cut         string `json:"cut"`
		Description string `json:"description"`
		Receiver    string `json:"receiver"`
	} `json:"cutInfos"`
}
