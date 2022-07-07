package test_main

import (
	"fmt"
	"strconv"
	"strings"
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/hexops/autogold"
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

func (otu *OverflowTestUtils) AutoGold(classifier string, value interface{}) *OverflowTestUtils {
	autogold.Equal(otu.T, value, autogold.Name(otu.T.Name()+"_"+classifier))
	return otu
}

func (otu *OverflowTestUtils) AutoGoldRename(fullname string, value interface{}) *OverflowTestUtils {
	fullname = strings.Replace(fullname, " ", "_", -1)
	autogold.Equal(otu.T, value, autogold.Name(otu.T.Name()+"/"+fullname))
	return otu
}

func (otu *OverflowTestUtils) setupMarketAndDandy() uint64 {
	otu.setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		createUser(100.0, "user3").
		registerUser("user2").
		registerUser("user3")

	id := otu.mintThreeExampleDandies()[0]
	return id
}

func (otu *OverflowTestUtils) setupMarketAndMintDandys() []uint64 {
	otu.setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		createUser(100.0, "user3").
		registerUser("user2").
		registerUser("user3")

	ids := otu.mintThreeExampleDandies()
	return ids
}

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
		Args(otu.O.Arguments().Account("account")).
		Test(otu.T).AssertSuccess()

	// Setup Lease Market
	otu.O.TransactionFromFile("setup_find_market_1").
		SignProposeAndPayAs("user4").
		Test(otu.T).AssertSuccess().AssertNoEvents()

	//link in the server in the client
	otu.O.TransactionFromFile("setup_find_lease_market_2").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().Account("user4")).
		Test(otu.T).AssertSuccess()
	otu.createUser(100.0, "account")
	otu.createUser(100.0, "user4")

	//link in the server in the versus client
	otu.O.TransactionFromFile("testSetResidualAddress").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().Account("find")).
		Test(otu.T).AssertSuccess()

	otu.O.TransactionFromFile("adminInitDUC").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().Account("account")).
		Test(otu.T).AssertSuccess()

	return otu.tickClock(1.0)
}

func (otu *OverflowTestUtils) tickClock(time float64) *OverflowTestUtils {
	otu.O.TransactionFromFile("testClock").SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			UFix64(time)).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) createUser(fusd float64, name string) *OverflowTestUtils {

	nameAddress := otu.accountAddress(name)

	otu.O.TransactionFromFile("createProfile").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().String(name)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.Profile.Created", map[string]interface{}{
			"account":   nameAddress,
			"userName":  name,
			"findName":  "",
			"createdAt": "find",
		}))

	otu.O.TransactionFromFile("testMintFusd").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account(name).
			UFix64(fusd)).
		Test(otu.T).
		AssertSuccess().
		AssertEventCount(3)

	otu.O.TransactionFromFile("testMintFlow").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account(name).
			UFix64(fusd)).
		Test(otu.T).
		AssertSuccess().
		AssertEventCount(3)

	otu.O.TransactionFromFile("testMintUsdc").
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
			"to":     "0x01cf0e2f2f715450",
		})).
		AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
			"amount": "5.00000000",
			"from":   nameAddress,
		}))

}

func (otu *OverflowTestUtils) registerUserWithName(buyer, name string) *OverflowTestUtils {
	otu.registerUserWithNameTransaction(buyer, name)
	return otu
}

func (otu *OverflowTestUtils) registerUserWithNameAndForge(buyer, name string) *OverflowTestUtils {
	otu.registerUserWithNameTransaction(buyer, name)
	otu.buyForgeForName(buyer, name)
	return otu
}

func (otu *OverflowTestUtils) registerUserWithNameTransaction(buyer, name string) overflow.TransactionResult {
	nameAddress := otu.accountAddress(buyer)
	expireTime := otu.currentTime() + leaseDurationFloat
	expireTimeString := fmt.Sprintf("%f00", expireTime)

	lockedTime := otu.currentTime() + leaseDurationFloat + lockDurationFloat
	lockedTimeString := fmt.Sprintf("%f00", lockedTime)

	return otu.O.TransactionFromFile("register").
		SignProposeAndPayAs(buyer).
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
			"to":     "0x01cf0e2f2f715450",
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
	address := otu.O.Account(name).Address().String()
	return fmt.Sprintf("0x%s", address)
}

func (otu *OverflowTestUtils) listForSale(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("listNameForSale").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			String(name).
			UFix64(10.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sale", map[string]interface{}{
			"amount": "10.00000000",
			"status": "active_listed",
			"name":   name,
			"seller": otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) listNameForSale(seller, name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("listNameForSale").
		SignProposeAndPayAs(seller).
		Args(otu.O.Arguments().
			String(name).
			UFix64(10.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sale", map[string]interface{}{
			"amount":     "10.00000000",
			"status":     "active_listed",
			"name":       name,
			"seller":     otu.accountAddress(seller),
			"sellerName": seller,
		}))
	return otu
}

func (otu *OverflowTestUtils) directOffer(buyer, name string, amount float64) *OverflowTestUtils {
	otu.O.TransactionFromFile("bidName").SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			String(name).
			UFix64(amount)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.DirectOffer", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", amount),
			"buyer":  otu.accountAddress(buyer),
			"name":   name,
			"status": "active_offered",
		}))

	return otu
}

func (otu *OverflowTestUtils) listForAuction(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("listNameForAuction").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			String(name).
			UFix64(5.0).  //startAuctionPrice
			UFix64(20.0). //reserve price
			UFix64(auctionDurationFloat).
			UFix64(300.0)). //extention on late bid
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
			"amount":              "5.00000000",
			"auctionReservePrice": "20.00000000",
			"status":              "active_listed",
			"name":                name,
			"seller":              otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) bid(buyer, name string, amount float64) *OverflowTestUtils {

	endTime := otu.currentTime() + auctionDurationFloat
	endTimeSting := fmt.Sprintf("%f00", endTime)
	otu.O.TransactionFromFile("bidName").SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			String(name).
			UFix64(amount)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
			"amount":    fmt.Sprintf("%.8f", amount),
			"endsAt":    endTimeSting,
			"buyer":     otu.accountAddress(buyer),
			"buyerName": buyer,
			"name":      name,
			"status":    "active_ongoing",
		}))
	return otu
}

func (otu *OverflowTestUtils) auctionBid(buyer, name string, amount float64) *OverflowTestUtils {

	endTime := otu.currentTime() + auctionDurationFloat
	endTimeSting := fmt.Sprintf("%f00", endTime)
	otu.O.TransactionFromFile("bidName").SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			String(name).
			UFix64(amount)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
			"amount":    fmt.Sprintf("%.8f", amount),
			"endsAt":    endTimeSting,
			"buyer":     otu.accountAddress(buyer),
			"buyerName": buyer,
			"name":      name,
			"status":    "active_ongoing",
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

	otu.O.TransactionFromFile("adminMintCharity").SignProposeAndPayAs("find").
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
			String("https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp").
			String("Neo Collectibles FIND").
			String("https://neomotorcycles.co.uk/index.html").
			String("https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp").
			String("https://neomotorcycles.co.uk/assets/img/neo-logo-web-dark.png?h=5a4d226197291f5f6370e79a1ee656a1")).
		Test(otu.T).
		AssertSuccess().
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

func (otu *OverflowTestUtils) buyForgeForName(user, name string) *OverflowTestUtils {
	otu.O.TransactionFromFile("buyAddon").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().String(name).String("forge").UFix64(50.0)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AddonActivated", map[string]interface{}{
			"name":  name,
			"addon": "forge",
		}))

	return otu
}

func (otu *OverflowTestUtils) setupDandy(user string) *OverflowTestUtils {
	return otu.createUser(100.0, user).
		registerUser(user).
		buyForge(user)
}

func (otu *OverflowTestUtils) cancelNFTForSale(name string, id uint64) *OverflowTestUtils {

	otu.O.TransactionFromFile("delistNFTSale").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64Array(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
			"status": "cancel",
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) cancelLeaseForSale(user, name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("delistLeaseSale").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().
			StringArray(name)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale", map[string]interface{}{
			"status": "cancel",
			"name":   name,
			"seller": otu.accountAddress(user),
		}))
	return otu
}

func (otu *OverflowTestUtils) cancelAllNFTForSale(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("delistAllNFTSale").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account")).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) cancelAllLeaseForSale(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("delistAllLeaseSale").
		SignProposeAndPayAs(name).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) listNFTForSale(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("listNFTForSale").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String("Dandy").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
			"status": "active_listed",
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) listLeaseForSale(user string, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("listLeaseForSale").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().
			String(name).
			String("Flow").
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale", map[string]interface{}{
			"status":    "active_listed",
			"amount":    fmt.Sprintf("%.8f", price),
			"leaseName": name,
			"seller":    otu.accountAddress(user),
		}))
	return otu
}

func (otu *OverflowTestUtils) listExampleNFTForSale(name string, id uint64, price float64) []uint64 {

	res := otu.O.TransactionFromFile("listNFTForSale").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String("ExampleNFT").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess()
	return otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketSale.Sale", "id")

}

func (otu *OverflowTestUtils) listNFTForEscrowedAuction(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("listNFTForAuctionEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String("Dandy").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(price + 5.0).
			UFix64(300.0).
			UFix64(60.0).
			UFix64(1.0).
			UFix64(otu.currentTime() + 10.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              fmt.Sprintf("%.8f", price),
			"auctionReservePrice": fmt.Sprintf("%.8f", price+5.0),
			"id":                  fmt.Sprintf("%d", id),
			"seller":              otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) listExampleNFTForEscrowedAuction(name string, id uint64, price float64) []uint64 {

	res := otu.O.TransactionFromFile("listNFTForAuctionEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String("ExampleNFT").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(price + 5.0).
			UFix64(300.0).
			UFix64(60.0).
			UFix64(1.0).
			UFix64(otu.currentTime() + 10.0)).
		Test(otu.T).AssertSuccess()
	return otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", "id")
}

func (otu *OverflowTestUtils) delistAllNFTForEscrowedAuction(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("cancelAllMarketAuctionEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account")).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) listNFTForSoftAuction(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("listNFTForAuctionSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String("Dandy").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(price + 5.0).
			UFix64(300.0).
			UFix64(60.0).
			UFix64(1.0).
			UFix64(otu.currentTime() + 10.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              fmt.Sprintf("%.8f", price),
			"auctionReservePrice": fmt.Sprintf("%.8f", price+5.0),
			"id":                  fmt.Sprintf("%d", id),
			"seller":              otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) listLeaseForSoftAuction(user string, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("listLeaseForAuctionSoft").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().
			String(name).
			String("Flow").
			UFix64(price).
			UFix64(price + 5.0).
			UFix64(300.0).
			UFix64(60.0).
			UFix64(1.0).
			UFix64(otu.currentTime() + 10.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              fmt.Sprintf("%.8f", price),
			"auctionReservePrice": fmt.Sprintf("%.8f", price+5.0),
			"leaseName":           name,
			"seller":              otu.accountAddress(user),
		}))
	return otu
}

func (otu *OverflowTestUtils) delistAllNFT(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("cancelAllMarketListings").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account")).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) delistAllNFTForSoftAuction(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("cancelAllMarketAuctionSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account")).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) delistAllLeaseForSoftAuction(name string) *OverflowTestUtils {

	otu.O.TransactionFromFile("cancelAllLeaseMarketAuctionSoft").
		SignProposeAndPayAs(name).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) checkRoyalty(name string, id uint64, royaltyName string, nftAlias string, expectedPlatformRoyalty float64) *OverflowTestUtils {
	/* Ben : Should we rename the check royalty script name? */
	royalty := Royalty{}
	err := otu.O.ScriptFromFile("getCheckRoyalty").
		Args(otu.O.Arguments().
			String(name).
			UInt64(id).
			String(nftAlias).
			String("A.f8d6e0586b0a20c7.MetadataViews.Royalties")).
		RunMarshalAs(&royalty)
	assert.NoError(otu.T, err)

	for _, item := range royalty.Items {
		if item.Description == royaltyName {
			assert.Equal(otu.T, fmt.Sprintf("%.8f", expectedPlatformRoyalty), item.Cut)
			return otu
		}
	}

	assert.Equal(otu.T, expectedPlatformRoyalty, 0.0)
	return otu

}

func (otu *OverflowTestUtils) buyNFTForMarketSale(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("buyNFTForSale").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String(seller).
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(seller),
			"buyer":  otu.accountAddress(name),
			"status": "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) buyLeaseForMarketSale(buyer string, seller string, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("buyLeaseForSale").
		SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			String(name).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"name":   name,
			"seller": otu.accountAddress(seller),
			"buyer":  otu.accountAddress(buyer),
			"status": "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) increaseAuctioBidMarketEscrow(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("increaseBidMarketAuctionEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", totalPrice),
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"status": "active_ongoing",
		}))
	return otu
}

func (otu *OverflowTestUtils) increaseAuctionBidMarketSoft(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("increaseBidMarketAuctionSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", totalPrice),
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"status": "active_ongoing",
		}))
	return otu
}

func (otu *OverflowTestUtils) increaseAuctionBidLeaseMarketSoft(buyer string, name string, price float64, totalPrice float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("increaseBidLeaseMarketAuctionSoft").
		SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			String(name).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount":    fmt.Sprintf("%.8f", totalPrice),
			"leaseName": name,
			"buyer":     otu.accountAddress(buyer),
			"status":    "active_ongoing",
		}))
	return otu
}

func (otu *OverflowTestUtils) saleItemListed(name string, saleType string, price float64) *OverflowTestUtils {

	t := otu.T
	itemsForSale := otu.getItemsForSale(name)

	assert.Equal(t, 1, len(itemsForSale))
	assert.Equal(t, saleType, itemsForSale[0].SaleType)
	assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)
	return otu
}

func (otu *OverflowTestUtils) saleLeaseListed(name string, saleType string, price float64) *OverflowTestUtils {

	t := otu.T
	itemsForSale := otu.getLeasesForSale(name)

	assert.Equal(t, 1, len(itemsForSale))
	assert.Equal(t, saleType, itemsForSale[0].SaleType)
	assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)
	return otu
}

func (otu *OverflowTestUtils) auctionBidMarketEscrow(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String(seller).
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"status": "active_ongoing",
		}))
	return otu
}

func (otu *OverflowTestUtils) auctionBidMarketSoft(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidMarketAuctionSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String(seller).
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"status": "active_ongoing",
		}))
	return otu
}

func (otu *OverflowTestUtils) auctionBidLeaseMarketSoft(buyer string, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").
		SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			String(name).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount":    fmt.Sprintf("%.8f", price),
			"leaseName": name,
			"buyer":     otu.accountAddress(buyer),
			"status":    "active_ongoing",
		}))
	return otu
}

func (otu *OverflowTestUtils) increaseDirectOfferMarketEscrowed(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("increaseBidMarketDirectOfferEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", totalPrice),
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"status": "active_offered",
		}))
	return otu
}

func (otu *OverflowTestUtils) increaseDirectOfferMarketSoft(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("increaseBidMarketDirectOfferSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", totalPrice),
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"status": "active_offered",
		}))
	return otu
}

func (otu *OverflowTestUtils) directOfferMarketEscrowed(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String(seller).
			String("Dandy").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) directOfferMarketEscrowedExampleNFT(name string, seller string, id uint64, price float64) []uint64 {

	res := otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String(seller).
			String("ExampleNFT").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess()
	return otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", "id")
}

func (otu *OverflowTestUtils) cancelAllDirectOfferMarketEscrowed(signer string) *OverflowTestUtils {

	otu.O.TransactionFromFile("cancelAllMarketDirectOfferEscrowed").
		SignProposeAndPayAs(signer).
		Args(otu.O.Arguments().
			Account("account")).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) directOfferMarketSoft(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String(seller).
			String("Dandy").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
		}))
	return otu
}

func (otu *OverflowTestUtils) cancelAllDirectOfferMarketSoft(signer string) *OverflowTestUtils {

	otu.O.TransactionFromFile("cancelAllMarketDirectOfferSoft").
		SignProposeAndPayAs(signer).
		Args(otu.O.Arguments().
			Account("account")).
		Test(otu.T).AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferMarketEscrowed(name string, id uint64, buyer string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(name),
			"buyer":  otu.accountAddress(buyer),
			"amount": fmt.Sprintf("%.8f", price),
			"status": "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferMarketSoft(name string, id uint64, buyer string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("acceptDirectOfferSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(name),
			"buyer":  otu.accountAddress(buyer),
			"amount": fmt.Sprintf("%.8f", price),
			"status": "active_accepted",
		}))
	return otu
}

func (otu *OverflowTestUtils) rejectDirectOfferEscrowed(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("cancelMarketDirectOfferEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64Array(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"status": "rejected",
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(name),
			"amount": fmt.Sprintf("%.8f", price),
		}))
	return otu
}

func (otu *OverflowTestUtils) retractOfferDirectOfferEscrowed(buyer, seller string, id uint64) *OverflowTestUtils {

	otu.O.TransactionFromFile("retractOfferMarketDirectOfferEscrowed").
		SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"status": "cancel",
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(seller),
		}))
	return otu
}

func (otu *OverflowTestUtils) rejectDirectOfferSoft(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("cancelMarketDirectOfferSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64Array(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel_rejected",
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(name),
			"amount": fmt.Sprintf("%.8f", price),
		}))
	return otu
}

func (otu *OverflowTestUtils) retractOfferDirectOfferSoft(buyer, seller string, id uint64) *OverflowTestUtils {

	otu.O.TransactionFromFile("retractOfferMarketDirectOfferSoft").
		SignProposeAndPayAs(buyer).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel",
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(seller),
		}))
	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionEscrowFromBidder(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketAuctionEscrowedFromBidder").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"amount": fmt.Sprintf("%.8f", price),
			"status": "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionEscrow(name string, id uint64, buyer string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketAuctionEscrowed").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String(name).
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(name),
			"buyer":  otu.accountAddress(buyer),
			"amount": fmt.Sprintf("%.8f", price),
			"status": "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionSoft(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"amount": fmt.Sprintf("%.8f", price),
			"status": "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketAuctionSoft(user string, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().
			String(name).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"leaseName": name,
			"buyer":     otu.accountAddress(user),
			"amount":    fmt.Sprintf("%.8f", price),
			"status":    "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) fulfillMarketDirectOfferSoft(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketDirectOfferSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"amount": fmt.Sprintf("%.8f", price),
			"status": "sold",
		}))
	return otu
}

type Royalty struct {
	Items []struct {
		Cut         string `json:"cut"`
		Description string `json:"description"`
		Receiver    string `json:"receiver"`
	} `json:"cutInfos"`
}

func (otu *OverflowTestUtils) getItemsForSale(name string) []SaleItemInformation {

	var findReport Report
	err := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().
		String(name)).
		RunMarshalAs(&findReport)
	if err != nil {
		swallowErr(err)
	}
	var list []SaleItemInformation
	for _, saleItemCollectionReport := range findReport.FINDReport.ItemsForSale {
		list = append(list, saleItemCollectionReport.Items...)
	}
	return list

}

func (otu *OverflowTestUtils) getLeasesForSale(name string) []SaleItemInformation {

	var findReport Report
	err := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().
		String(name)).
		RunMarshalAs(&findReport)
	if err != nil {
		swallowErr(err)
	}
	var list []SaleItemInformation
	for _, saleItemCollectionReport := range findReport.FINDReport.LeasesForSale {
		list = append(list, saleItemCollectionReport.Items...)
	}
	return list

}

func swallowErr(err error) {
}

func (otu *OverflowTestUtils) registerFTInFtRegistry(alias string, eventName string, eventResult map[string]interface{}) *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetFTInfo_" + alias).
		SignProposeAndPayAs("find").
		Test(otu.T).
		AssertSuccess().
		AssertEmitEvent(overflow.NewTestEvent(eventName, eventResult))

	return otu
}

func (otu *OverflowTestUtils) removeFTInFtRegistry(transactionFile, argument, eventName string, eventResult map[string]interface{}) *OverflowTestUtils {
	otu.O.TransactionFromFile(transactionFile).
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().String(argument)).
		Test(otu.T).
		AssertSuccess().
		AssertEmitEvent(overflow.NewTestEvent(eventName, eventResult))

	return otu
}

func (otu *OverflowTestUtils) registerDandyInNFTRegistry() *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetNFTInfo_Dandy").
		SignProposeAndPayAs("find").
		Test(otu.T).
		AssertSuccess().
		AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.NFTRegistry.NFTInfoRegistered", map[string]interface{}{
			"alias":          "Dandy",
			"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
		}))

	return otu
}

func (otu *OverflowTestUtils) removeDandyInNFtRegistry(transactionFile string, argument string) *OverflowTestUtils {
	otu.O.TransactionFromFile(transactionFile).
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().String(argument)).
		Test(otu.T).
		AssertSuccess().
		AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.NFTRegistry.NFTInfoRemoved", map[string]interface{}{
			"alias":          "Dandy",
			"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
		}))

	return otu
}

func (otu *OverflowTestUtils) registerExampleNFTInNFTRegistry() *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetNFTInfo_ExampleNFT").
		SignProposeAndPayAs("find").
		Test(otu.T).
		AssertSuccess().
		AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.NFTRegistry.NFTInfoRegistered", map[string]interface{}{
			"alias":          "ExampleNFT",
			"typeIdentifier": "A.f8d6e0586b0a20c7.ExampleNFT.NFT",
		}))

	return otu
}

func (otu *OverflowTestUtils) registerFtInRegistry() *OverflowTestUtils {
	otu.registerFTInFtRegistry("fusd", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
		"alias":          "FUSD",
		"typeIdentifier": "A.f8d6e0586b0a20c7.FUSD.Vault",
	}).
		registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
			"alias":          "Flow",
			"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
		}).
		registerFTInFtRegistry("usdc", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
			"alias":          "USDC",
			"typeIdentifier": "A.f8d6e0586b0a20c7.FiatToken.Vault",
		}).
		registerDandyInNFTRegistry()
	return otu
}

func (otu *OverflowTestUtils) setProfile(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("setProfile").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().String("https://find.xyz/assets/img/avatars/avatar14.png")).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) setFlowDandyMarketOption(marketType string) *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetSellDandyForFlow").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			Account("account").
			String(marketType)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) setFlowLeaseMarketOption(marketType string) *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetSellLeaseForFlow").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			Account("user4").
			String(marketType)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) alterMarketOption(marketType, ruleName string) *OverflowTestUtils {
	otu.O.TransactionFromFile("testAlterMarketOption").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().String(marketType).String(ruleName)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) alterLeaseMarketOption(marketType, ruleName string) *OverflowTestUtils {
	otu.O.TransactionFromFile("testAlterLeaseMarketOption").
		SignProposeAndPayAs("user4").
		Args(otu.O.Arguments().String(marketType).String(ruleName)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) removeMarketOption(marketType string) *OverflowTestUtils {
	otu.O.TransactionFromFile("removeMarketOption").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().String(marketType)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) removeTenantRule(optionName, tenantRuleName string) *OverflowTestUtils {
	otu.O.TransactionFromFile("removeTenantRule").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			String(optionName).
			String(tenantRuleName)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) removeLeaseTenantRule(optionName, tenantRuleName string) *OverflowTestUtils {
	otu.O.TransactionFromFile("removeTenantRule").
		SignProposeAndPayAs("user4").
		Args(otu.O.Arguments().
			String(optionName).
			String(tenantRuleName)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) setTenantRuleFUSD(optionName string) *OverflowTestUtils {
	otu.O.TransactionFromFile("setTenantRuleFUSD").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			String(optionName)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) setLeaseTenantRuleFUSD(optionName string) *OverflowTestUtils {
	otu.O.TransactionFromFile("setTenantRuleFUSD").
		SignProposeAndPayAs("user4").
		Args(otu.O.Arguments().
			String(optionName)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) setFindCut(cut float64) *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetFindCut").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			Account("account").
			UFix64(cut)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) setFindLeaseCut(cut float64) *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetFindCut").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			Account("user4").
			UFix64(cut)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) blockDandy(script string) *OverflowTestUtils {
	otu.O.TransactionFromFile(script).
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			Account("account")).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) destroyFUSDVault(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("testDestroyFUSDVault").
		SignProposeAndPayAs(user).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) destroyDandyCollection(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("testDestroyDandyCollection").
		SignProposeAndPayAs(user).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) destroyLeaseCollection(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("testDestroyLeaseCollection").
		SignProposeAndPayAs(user).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) sendDandy(receiver, sender string, id uint64) *OverflowTestUtils {
	otu.O.TransactionFromFile("sendDandy").
		SignProposeAndPayAs(sender).
		Args(otu.O.Arguments().
			String(receiver).
			UInt64(id)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) sendFT(receiver, sender, ft string, amount float64) *OverflowTestUtils {
	otu.O.TransactionFromFile("sendFT").
		SignProposeAndPayAs(sender).
		Args(otu.O.Arguments().
			String(receiver).
			UFix64(amount).
			String(ft).
			String("").
			String("")).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) profileBan(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetProfileBan").
		SignProposeAndPayAs("account").
		Args(otu.O.Arguments().
			String(user)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) leaseProfileBan(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetProfileBan").
		SignProposeAndPayAs("user4").
		Args(otu.O.Arguments().
			String(user)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) removeProfileBan(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("adminRemoveProfileBan").
		SignProposeAndPayAs("account").
		Args(otu.O.Arguments().
			String(user)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) removeLeaseProfileBan(user string) *OverflowTestUtils {
	otu.O.TransactionFromFile("adminRemoveProfileBan").
		SignProposeAndPayAs("user4").
		Args(otu.O.Arguments().
			String(user)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

// func (otu *OverflowTestUtils) setFindName(user, name string) *OverflowTestUtils {
// 	otu.O.TransactionFromFile("testSetMainName").
// 		SignProposeAndPayAs(user).
// 		Args(otu.O.Arguments().
// 			String(name)).
// 		Test(otu.T).
// 		AssertSuccess()
// 	return otu
// }

func (otu *OverflowTestUtils) replaceID(result string, dandyIds []uint64) string {
	counter := 0
	for _, id := range dandyIds {
		result = strings.Replace(result, fmt.Sprint(id)+`"`, "ID"+fmt.Sprint(counter)+`"`, -1)
		counter = counter + 1
	}
	return result
}

func (otu *OverflowTestUtils) replaceDandyList(result string, dandyIds []uint64) string {
	counter := 0
	for _, id := range dandyIds {
		result = strings.Replace(result, `"Dandy`+fmt.Sprint(id)+`"`, `"DandyID"`, 1)
		counter = counter + 1
	}
	return result
}

// func (otu *OverflowTestUtils) replaceEvent(events []*overflow.FormatedEvent, dandyIds []uint64) string {
// 	string := ""
// 	for _, event := range events {
// 		string = string + event.String()
// 	}

// 	counter := 0
// 	for _, id := range dandyIds {
// 		string = strings.Replace(string, fmt.Sprint(id)+`"`, "ID"+fmt.Sprint(counter)+`"`, -1)
// 		counter = counter + 1
// 	}
// 	return string
// }

func (otu *OverflowTestUtils) retrieveEvent(events []*overflow.FormatedEvent, eventNames []string) string {
	string := ""
	for _, event := range events {
		for _, eventName := range eventNames {
			if event.Name == eventName {
				string = fmt.Sprintf("%s%s", string, event.String())
			}
		}
	}

	return string
}

func (otu *OverflowTestUtils) getIDFromEvent(events []*overflow.FormatedEvent, eventName, field string) []uint64 {
	Ids := []uint64{}
	for _, event := range events {
		if event.Name == eventName {
			Ids = append(Ids, event.GetFieldAsUInt64(field))
		}
	}

	return Ids
}

func (otu *OverflowTestUtils) moveNameTo(owner, receiver, name string) *OverflowTestUtils {
	otu.O.TransactionFromFile("moveNameTO").
		SignProposeAndPayAs(owner).
		Args(otu.O.Arguments().String(name).String(otu.accountAddress(receiver))).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Moved", map[string]interface{}{
			"name": name,
		}))
	return otu
}

func (otu *OverflowTestUtils) cancelNameAuction(owner, name string) *OverflowTestUtils {
	otu.O.TransactionFromFile("cancelNameAuction").
		SignProposeAndPayAs(owner).
		Args(otu.O.Arguments().StringArray(name)).
		Test(otu.T).
		AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
			"name":       name,
			"sellerName": owner,
			"status":     "cancel_listing",
		}))
	return otu
}

func (otu *OverflowTestUtils) sendExampleNFT(receiver, sender string) *OverflowTestUtils {
	otu.O.TransactionFromFile("setUpExampleNFT").
		SignProposeAndPayAs(receiver).
		Test(otu.T).
		AssertSuccess()

	otu.O.TransactionFromFile("sendExampleNFT").
		SignProposeAndPayAs(sender).
		Args(otu.O.Arguments().
			String(receiver).
			UInt64(0)).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) setDUCExampleNFT() *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetSellExampleNFTRules").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			Account("account")).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) setDUCLease() *OverflowTestUtils {
	otu.O.TransactionFromFile("adminSetSellDUCLeaseRules").
		SignProposeAndPayAs("find").
		Args(otu.O.Arguments().
			Account("user4")).
		Test(otu.T).
		AssertSuccess()
	return otu
}

func (otu *OverflowTestUtils) listNFTForSaleDUC(name string, id uint64, price float64) []uint64 {

	res := otu.O.TransactionFromFile("listNFTForSaleDUC").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			Account("account").
			String("ExampleNFT").
			UInt64(id).
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess()

	return otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketSale.Sale", "id")

}

func (otu *OverflowTestUtils) listLeaseForSaleDUC(user string, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("listLeaseForSaleDUC").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().
			Account("account").
			String(name).
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess()

	return otu

}

func (otu *OverflowTestUtils) buyNFTForMarketSaleDUC(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("buyNFTForSaleDUC").
		SignProposeAndPayAs(name).PayloadSigner("account").
		Args(otu.O.Arguments().
			Account("account").
			Account("account").
			String(seller).
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(seller),
			"buyer":  otu.accountAddress(name),
			"status": "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) buyLeaseForMarketSaleDUC(buyer, seller, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("buyLeaseForSaleDUC").
		SignProposeAndPayAs(buyer).PayloadSigner("account").
		Args(otu.O.Arguments().
			Account("account").
			String(name).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"name":   name,
			"seller": otu.accountAddress(seller),
			"buyer":  otu.accountAddress(buyer),
			"status": "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) registerDUCInRegistry() *OverflowTestUtils {
	otu.registerFTInFtRegistry("duc", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
		"alias":          "DUC",
		"typeIdentifier": "A.f8d6e0586b0a20c7.DapperUtilityCoin.Vault",
	}).registerExampleNFTInNFTRegistry()
	return otu
}

func (otu *OverflowTestUtils) listNFTForSoftAuctionDUC(name string, id uint64, price float64) []uint64 {

	res := otu.O.TransactionFromFile("listNFTForAuctionSoftDUC").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			Account("account").
			String("ExampleNFT").
			UInt64(id).
			UFix64(price).
			UFix64(price + 5.0).
			UFix64(300.0).
			UFix64(60.0).
			UFix64(1.0).
			UFix64(otu.currentTime() + 10.0)).
		Test(otu.T).AssertSuccess()

	return otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", "id")

}

func (otu *OverflowTestUtils) listLeaseForSoftAuctionDUC(user, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("listLeaseForAuctionSoftDUC").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().
			Account("account").
			String(name).
			UFix64(price).
			UFix64(price + 5.0).
			UFix64(300.0).
			UFix64(60.0).
			UFix64(1.0).
			UFix64(otu.currentTime() + 10.0)).
		Test(otu.T).AssertSuccess()

	return otu

}

func (otu *OverflowTestUtils) listExampleNFTForSoftAuction(name string, id uint64, price float64) []uint64 {

	res := otu.O.TransactionFromFile("listNFTForAuctionSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String("ExampleNFT").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(price + 5.0).
			UFix64(300.0).
			UFix64(60.0).
			UFix64(1.0).
			UFix64(otu.currentTime() + 10.0)).
		Test(otu.T).AssertSuccess()

	return otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", "id")

}

func (otu *OverflowTestUtils) auctionBidMarketSoftDUC(name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidMarketAuctionSoftDUC").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			Account("account").
			String(seller).
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": fmt.Sprintf("%.8f", price),
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"status": "active_ongoing",
		}))
	return otu
}

func (otu *OverflowTestUtils) auctionBidLeaseMarketSoftDUC(user string, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("bidLeaseMarketAuctionSoftDUC").
		SignProposeAndPayAs(user).
		Args(otu.O.Arguments().
			Account("account").
			String(name).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount":    fmt.Sprintf("%.8f", price),
			"leaseName": name,
			"buyer":     otu.accountAddress(user),
			"status":    "active_ongoing",
		}))
	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketAuctionSoftDUC(user string, name string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoftDUC").
		SignProposeAndPayAs(user).PayloadSigner("account").
		Args(otu.O.Arguments().
			String(name).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"leaseName": name,
			"buyer":     otu.accountAddress(user),
			"amount":    fmt.Sprintf("%.8f", price),
			"status":    "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionSoftDUC(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketAuctionSoftDUC").
		SignProposeAndPayAs(name).PayloadSigner("account").
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"amount": fmt.Sprintf("%.8f", price),
			"status": "sold",
		}))
	return otu
}

func (otu *OverflowTestUtils) directOfferMarketSoftDUC(name string, seller string, id uint64, price float64) []uint64 {

	res := otu.O.TransactionFromFile("bidMarketDirectOfferSoftDUC").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			Account("account").
			String(seller).
			String("ExampleNFT").
			UInt64(id).
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess()

	return otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", "id")
}

func (otu *OverflowTestUtils) directOfferMarketSoftExampleNFT(name string, seller string, id uint64, price float64) []uint64 {

	res := otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			String(seller).
			String("ExampleNFT").
			UInt64(id).
			String("Flow").
			UFix64(price).
			UFix64(otu.currentTime() + 100.0)).
		Test(otu.T).AssertSuccess()

	return otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", "id")
}

func (otu *OverflowTestUtils) acceptDirectOfferMarketSoftDUC(name string, id uint64, buyer string, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("acceptDirectOfferSoftDUC").
		SignProposeAndPayAs(name).
		Args(otu.O.Arguments().
			Account("account").
			Account("account").
			UInt64(id)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"seller": otu.accountAddress(name),
			"buyer":  otu.accountAddress(buyer),
			"amount": fmt.Sprintf("%.8f", price),
			"status": "active_accepted",
		}))
	return otu
}

func (otu *OverflowTestUtils) fulfillMarketDirectOfferSoftDUC(name string, id uint64, price float64) *OverflowTestUtils {

	otu.O.TransactionFromFile("fulfillMarketDirectOfferSoftDUC").
		SignProposeAndPayAs(name).PayloadSigner("account").
		Args(otu.O.Arguments().
			Account("account").
			UInt64(id).
			UFix64(price)).
		Test(otu.T).AssertSuccess().
		AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"id":     fmt.Sprintf("%d", id),
			"buyer":  otu.accountAddress(name),
			"amount": fmt.Sprintf("%.8f", price),
			"status": "sold",
		}))
	return otu
}

type SaleItem struct {
	Amount              string `json:"amount"`
	AuctionReservePrice string `json:"auctionReservePrice"`
	Bidder              string `json:"bidder"`
	ExtensionOnLateBid  string `json:"extensionOnLateBid"`
	FtType              string `json:"ftType"`
	FtTypeIdentifier    string `json:"ftTypeIdentifier"`
	ID                  string `json:"id"`
	ListingValidUntil   string `json:"listingValidUntil"`
	Owner               string `json:"owner"`
	SaleType            string `json:"saleType"`
	Type                string `json:"type"`
	TypeID              string `json:"typeId"`
}

type Report struct {
	FINDReport FINDReport `json:"FINDReport"`
	NameReport NameReport `json:"NameReport"`
}

type NameReport struct {
	Status string `json:"status"`
	Cost   string `json:"cost"`
}

type FINDReport struct {
	Profile         interface{}                          `json:"profile"`
	Bids            []interface{}                        `json:"bids"`
	RelatedAccounts map[string]interface{}               `json:"relatedAccounts"`
	Leases          []interface{}                        `json:"leases"`
	PrivateMode     string                               `json:"privateMode"`
	LeasesForSale   map[string]SaleItemCollectionReport  `json:"leasesForSale"`
	LeasesBids      map[string]MarketBidCollectionPublic `json:"leasesBids"`
	ItemsForSale    map[string]SaleItemCollectionReport  `json:"itemsForSale"`
	MarketBids      map[string]MarketBidCollectionPublic `json:"marketBids"`
}

type SaleItemCollectionReport struct {
	Items  []SaleItemInformation `json:"items"`
	Ghosts []GhostListing        `json:"ghosts"`
}

type MarketBidCollectionPublic struct {
	Items  []BidInfo      `json:"items"`
	Ghosts []GhostListing `json:"ghosts"`
}

type BidInfo struct {
	Id                string `json:"id"`
	BidAmount         string `json:"bidAmount"`
	BidTypeIdentifier string `json:"bidTypeIdentifier"`
	// Timestamp         string              `json:"timestamp"`
	Item SaleItemInformation `json:"item"`

	// For Names
	Name string `json:"name"`
}

type SaleItemInformation struct {
	NftIdentifier         string       `json:"nftIdentifier"`
	NftId                 string       `json:"nftId"`
	Seller                string       `json:"seller"`
	SellerName            string       `json:"sellerName"`
	Amount                string       `json:"amount"`
	Bidder                string       `json:"bidder"`
	BidderName            string       `json:"bidderName"`
	ListingId             string       `json:"listingId"`
	SaleType              string       `json:"saleType"`
	ListingTypeIdentifier string       `json:"listingTypeIdentifier"`
	FtAlias               string       `json:"ftAlias"`
	FtTypeIdentifier      string       `json:"ftTypeIdentifier"`
	ListingValidUntil     string       `json:"listingValidUntil"`
	Auction               *AuctionItem `json:"auction,omitempty"`
	ListingStatus         string       `json:"listingStatus"`

	// For Names
	LeaseIdentifier string `json:"leaseIdentifier"`
	LeaseName       string `json:"leaseName"`
}

type NFTInfo struct {
	Id                    string `json:"id"`
	Name                  string `json:"name"`
	Thumbnail             string `json:"thumbnail"`
	Nfttype               string `json:"type"`
	Rarity                string `json:"rarity"`
	EditionNumber         string `json:"editionNumber"`
	TotalInEdition        string `json:"totalInEdition"`
	CollectionName        string `json:"collectionName"`
	CollectionDescription string `json:"collectionDescription"`
}

type AuctionItem struct {
	StartPrice          string `json:"startPrice"`
	CurrentPrice        string `json:"currentPrice"`
	MinimumBidIncrement string `json:"minimumBidIncrement"`
	ReservePrice        string `json:"reservePrice"`
	ExtentionOnLateBid  string `json:"extentionOnLateBid"`
	AuctionEndsAt       string `json:"auctionEndsAt"`
	// Timestamp           string `json:"timestamp"`
}

type GhostListing struct {
	ListingType           string `json:"listingType"`
	ListingTypeIdentifier string `json:"listingTypeIdentifier"`
	Id                    string `json:"id"`
}
