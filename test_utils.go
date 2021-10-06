package test_main

import (
	"fmt"
	"strconv"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/stretchr/testify/assert"
)

type GWTFTestUtils struct {
	T    *testing.T
	GWTF *gwtf.GoWithTheFlow
}

func NewGWTFTest(t *testing.T) *GWTFTestUtils {
	return &GWTFTestUtils{T: t, GWTF: gwtf.NewTestingEmulator()}
}

const leaseDurationFloat = 31536000.0
const lockDurationFloat = 7776000.0
const auctionDurationFloat = 86400.0

func (gt *GWTFTestUtils) setupFIND() *GWTFTestUtils {
	//first step create the adminClient as the fin user

	gt.GWTF.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find").
		Test(gt.T).AssertSuccess().AssertNoEvents()

	//link in the server in the versus client
	gt.GWTF.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		AccountArgument("find").
		Test(gt.T).AssertSuccess().AssertNoEvents()

	//set up fin network as the fin user
	gt.GWTF.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("find").
		UFix64Argument(fmt.Sprintf("%f", leaseDurationFloat)).
		Test(gt.T).AssertSuccess().AssertNoEvents()

	return gt.tickClock("1.0")
}

func (gt *GWTFTestUtils) expireAuction() *GWTFTestUtils {
	return gt.tickClock(fmt.Sprintf("%f", auctionDurationFloat))
}

func (gt *GWTFTestUtils) expireLease() *GWTFTestUtils {
	return gt.tickClock(fmt.Sprintf("%f", leaseDurationFloat))
}

func (gt *GWTFTestUtils) expireLock() *GWTFTestUtils {
	return gt.tickClock(fmt.Sprintf("%f", lockDurationFloat))
}
func (gt *GWTFTestUtils) tickClock(time string) *GWTFTestUtils {
	gt.GWTF.TransactionFromFile("clock").SignProposeAndPayAs("find").UFix64Argument(time).Test(gt.T).AssertSuccess()
	return gt
}

func (gt *GWTFTestUtils) createUser(fusd string, name string) *GWTFTestUtils {

	gt.GWTF.TransactionFromFile("create_profile").
		SignProposeAndPayAs(name).
		StringArgument(name).
		Test(gt.T).
		AssertSuccess()

	gt.GWTF.TransactionFromFile("mint_fusd").
		SignProposeAndPayAsService().
		AccountArgument(name).
		UFix64Argument(fusd).
		Test(gt.T).
		AssertSuccess().
		AssertEventCount(3)
	return gt
}

func (gt *GWTFTestUtils) registerUser(name string) *GWTFTestUtils {
	gt.registerUserTransaction(name)
	return gt
}

func (gt *GWTFTestUtils) registerUserTransaction(name string) gwtf.TransactionResult {
	nameAddress := fmt.Sprintf("0x%s", gt.GWTF.Account(name).Address().String())
	expireTime := gt.currentTime() + leaseDurationFloat
	expireTimeString := fmt.Sprintf("%f00", expireTime)

	return gt.GWTF.TransactionFromFile("register").
		SignProposeAndPayAs(name).
		StringArgument(name).
		Test(gt.T).
		AssertSuccess().
		AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Register", map[string]interface{}{
			"expireAt": expireTimeString,
			"owner":    nameAddress,
			"name":     name,
		})).
		AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
			"amount": "5.00000000",
			"to":     "0x1cf0e2f2f715450",
		})).
		AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
			"amount": "5.00000000",
			"from":   nameAddress,
		}))

}

func (gt *GWTFTestUtils) currentTime() float64 {
	value, err := gt.GWTF.Script(`import Clock from "../contracts/Clock.cdc"
pub fun main() :  UFix64 {
    return Clock.time()
}`).RunReturns()
	assert.NoErrorf(gt.T, err, "Could not execute script")
	currentTime := value.String()
	res, err := strconv.ParseFloat(currentTime, 64)
	assert.NoErrorf(gt.T, err, "Could not parse as float")
	return res
}

func (gt *GWTFTestUtils) assertLookupAddress(expected string) {
	value := gt.GWTF.Script(`import FIND from "../contracts/FIND.cdc"
pub fun main(name: String) :  Address? {
    return FIND.lookupAddress(name)
}
		`).StringArgument("user1").RunReturnsInterface()

	assert.Equal(gt.T, expected, value)
}

func (gt *GWTFTestUtils) listForSale(name string) *GWTFTestUtils {
	expireTime := gt.currentTime() + leaseDurationFloat
	expireTimeString := fmt.Sprintf("%f00", expireTime)
	nameAddress := fmt.Sprintf("0x%s", gt.GWTF.Account(name).Address().String())

	gt.GWTF.TransactionFromFile("sell").
		SignProposeAndPayAs(name).
		StringArgument(name).
		UFix64Argument("10.0").
		Test(gt.T).AssertSuccess().
		AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
			"active":   "true",
			"amount":   "10.00000000",
			"name":     name,
			"expireAt": expireTimeString,
			"owner":    nameAddress,
		}))
	return gt
}

func (gt *GWTFTestUtils) blindBid(buyer, name, amount string) *GWTFTestUtils {
	bidderAddress := fmt.Sprintf("0x%s", gt.GWTF.Account(buyer).Address().String())
	gt.GWTF.TransactionFromFile("bid").SignProposeAndPayAs(buyer).
		StringArgument(name).
		UFix64Argument(amount).
		Test(gt.T).
		AssertSuccess().
		AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBid", map[string]interface{}{
			"amount": fmt.Sprintf("%s0000000", amount),
			"bidder": bidderAddress,
			"name":   name,
		}))

	return gt
}

func (gt *GWTFTestUtils) bid(buyer, name, amount string) *GWTFTestUtils {

	endTime := gt.currentTime() + auctionDurationFloat
	endTimeSting := fmt.Sprintf("%f00", endTime)
	bidderAddress := fmt.Sprintf("0x%s", gt.GWTF.Account(buyer).Address().String())
	gt.GWTF.TransactionFromFile("bid").SignProposeAndPayAs(buyer).
		StringArgument(name).
		UFix64Argument(amount).
		Test(gt.T).
		AssertSuccess().
		AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
			"amount":       fmt.Sprintf("%s0000000", amount),
			"auctionEndAt": endTimeSting,
			"bidder":       bidderAddress,
			"name":         name,
		}))
	return gt
}
