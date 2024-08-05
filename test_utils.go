package test_main

import (
	"fmt"
	"strings"
	"testing"

	. "github.com/bjartek/overflow/v2"
	"github.com/bjartek/underflow"
	"github.com/findonflow/find/findGo"
	"github.com/findonflow/find/utils"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var (
	findAdminSigner = WithSigner("find-admin")
	findSigner      = WithSigner("find")
	user1Signer     = WithSigner("user1")

	dandyNFTType = func(otu *OverflowTestUtils) string {
		res, _ := otu.O.QualifiedIdentifier("Dandy", "NFT")
		return res
	}
)

type OverflowTestUtils struct {
	T *testing.T
	O *OverflowState
}

type FindMarket_TenantRule struct {
	Name     string              `json:"name"`
	RuleType string              `json:"ruleType"`
	Types    []cadence.TypeValue `json:"types"`
	Allow    bool                `json:"allow"`
}

const (
	leaseDurationFloat   = 31536000.0
	lockDurationFloat    = 7776000.0
	auctionDurationFloat = 86400.0
)

func (otu *OverflowTestUtils) AutoGoldRename(fullname string, value interface{}) *OverflowTestUtils {
	otu.T.Helper()
	fullname = strings.ReplaceAll(fullname, " ", "_")
	autogold.Equal(otu.T, value, autogold.Name(otu.T.Name()+"/"+fullname))
	return otu
}

func (otu *OverflowTestUtils) tickClock(time float64) *OverflowTestUtils {
	otu.O.Tx("devClock",
		findAdminSigner,
		WithArg("clock", time),
	).AssertSuccess(otu.T)
	return otu
}

func (otu *OverflowTestUtils) registerUser(name string) *OverflowTestUtils {
	otu.registerUserTransaction(name)
	return otu
}

func (otu *OverflowTestUtils) registerUserTransaction(name string) OverflowResult {
	nameAddress := otu.O.Address(name)
	expireTime := otu.currentTime() + leaseDurationFloat

	lockedTime := otu.currentTime() + leaseDurationFloat + lockDurationFloat

	return otu.O.Tx("register",
		WithSigner(name),
		WithArg("name", name),
		WithArg("maxAmount", 10.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Register", map[string]interface{}{
			"validUntil":  expireTime,
			"lockedUntil": lockedTime,
			"owner":       nameAddress,
			"name":        name,
		}).
		AssertEvent(otu.T, ".FungibleToken.Deposited", map[string]interface{}{
			"amount": 10.0,
			"to":     otu.O.Address("find-admin"),
		}).
		AssertEvent(otu.T, ".FungibleToken.Withdrawn", map[string]interface{}{
			"amount": 10.0,
			"from":   nameAddress,
		})
}

func (otu *OverflowTestUtils) registerUserWithName(buyer, name string) *OverflowTestUtils {
	otu.registerUserWithNameTransaction(buyer, name)
	return otu
}

func (otu *OverflowTestUtils) registerUserWithNameTransaction(buyer, name string) OverflowResult {
	nameAddress := otu.O.Address(buyer)
	expireTime := otu.currentTime() + leaseDurationFloat
	lockedTime := otu.currentTime() + leaseDurationFloat + lockDurationFloat
	return otu.O.Tx("register",
		WithSigner(buyer),
		WithArg("name", name),
		WithArg("maxAmount", 10.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Register", map[string]interface{}{
			"validUntil":  expireTime,
			"lockedUntil": lockedTime,
			"owner":       nameAddress,
			"name":        name,
		}).
		AssertEvent(otu.T, "FungibleToken.Deposited", map[string]interface{}{
			"amount": 10.0,
			"to":     otu.O.Address("find-admin"),
		}).
		AssertEvent(otu.T, "FungibleToken.Withdrawn", map[string]interface{}{
			"amount": 10.0,
			"from":   nameAddress,
		})
}

func (out *OverflowTestUtils) currentTime() float64 {
	value, err := out.O.Script(`import "Clock"
access(all) fun main() :  UFix64 {
    return Clock.time()
}`).GetAsInterface()
	assert.NoErrorf(out.T, err, "Could not execute script")
	res, _ := value.(float64)
	return res
}

func (otu *OverflowTestUtils) listForSale(name string) *OverflowTestUtils {
	return otu.listNameForSale(name, name)
}

func (otu *OverflowTestUtils) listNameForSale(seller, name string) *OverflowTestUtils {
	otu.O.Tx("listNameForSale",
		WithSigner(seller),
		WithArg("name", name),
		WithArg("directSellPrice", 10.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Sale", map[string]interface{}{
			"amount":     10.0,
			"status":     "active_listed",
			"seller":     otu.O.Address(seller),
			"sellerName": seller,
		})
	return otu
}

func (otu *OverflowTestUtils) directOffer(buyer, name string, amount float64) *OverflowTestUtils {
	otu.O.Tx("bidName",
		WithSigner(buyer),
		WithArg("name", name),
		WithArg("amount", amount),
	).AssertSuccess(otu.T).AssertEvent(otu.T, "FIND.DirectOffer", map[string]interface{}{
		"amount": amount,
		"buyer":  otu.O.Address(buyer),
		"name":   name,
		"status": "active_offered",
	})

	return otu
}

func (otu *OverflowTestUtils) listForAuction(name string) *OverflowTestUtils {
	otu.O.Tx("listNameForAuction",
		WithSigner(name),
		WithArg("name", name),
		WithArg("auctionStartPrice", 5.0),
		WithArg("auctionReservePrice", 20.0),
		WithArg("auctionDuration", auctionDurationFloat),
		WithArg("auctionExtensionOnLateBid", 300.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.EnglishAuction", map[string]interface{}{
			"amount":              5.0,
			"auctionReservePrice": 20.0,
			"status":              "active_listed",
			"name":                name,
			"seller":              otu.O.Address(name),
		})
	return otu
}

func (otu *OverflowTestUtils) bid(buyer, name string, amount float64) *OverflowTestUtils {
	endTime := otu.currentTime() + auctionDurationFloat
	otu.O.Tx("bidName",
		WithSigner(buyer),
		WithArg("name", name),
		WithArg("amount", amount),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.EnglishAuction", map[string]interface{}{
			"amount":    amount,
			"endsAt":    endTime,
			"buyer":     otu.O.Address(buyer),
			"buyerName": buyer,
			"name":      name,
			"status":    "active_ongoing",
		})
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

func (otu *OverflowTestUtils) buyForge(user string) *OverflowTestUtils {
	otu.O.Tx("buyAddon",
		WithSigner(user),
		WithArg("name", user),
		WithArg("addon", "forge"),
		WithArg("amount", 50.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.AddonActivated", map[string]interface{}{
			"name":  user,
			"addon": "forge",
		})

	return otu
}

func (otu *OverflowTestUtils) cancelNFTForSale(name string, id uint64) *OverflowTestUtils {
	otu.O.Tx("delistNFTSale",
		WithSigner(name),
		WithArg("ids", []uint64{id}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "Sale", map[string]interface{}{
			"status": "cancel",
			"id":     id,
			"seller": otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) cancelLeaseForSale(user, name string) *OverflowTestUtils {
	otu.O.Tx("delistLeaseSale",
		WithSigner(user),
		WithArg("leases", []string{name}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "Sale", map[string]interface{}{
			"status": "cancel",
			"seller": otu.O.Address(user),
		})
	return otu
}

func (otu *OverflowTestUtils) listNFTForSale(name string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("listNFTForSale",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("directSellPrice", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketSale.Sale", map[string]interface{}{
			"status": "active_listed",
			"amount": price,
			"id":     id,
			"seller": otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) listNFTForEscrowedAuction(name string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("listNFTForAuctionEscrowed",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionStartTime", nil),
		WithArg("auctionValidUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              price,
			"auctionReservePrice": price + 5.0,
			"id":                  id,
			"seller":              otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) listNFTForSoftAuction(name string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("listNFTForAuctionSoft",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              price,
			"auctionReservePrice": price + 5.0,
			"id":                  id,
			"seller":              otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) listLeaseForSoftAuction(user string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("listLeaseForAuctionSoftDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              price,
			"auctionReservePrice": price + 5.0,
			"seller":              otu.O.Address(user),
		})

	return otu
}

func (otu *OverflowTestUtils) checkRoyalty(name string, id uint64, royaltyName string, nftAlias string, expectedPlatformRoyalty float64) *OverflowTestUtils {
	var royalty Royalty

	royaltyIden, err := otu.O.QualifiedIdentifier("MetadataViews", "Royalties")
	assert.NoError(otu.T, err)

	err = otu.O.Script("devgetCheckRoyalty",
		WithSigner(name),
		WithArg("name", name),
		WithArg("id", id),
		WithArg("nftAliasOrIdentifier", nftAlias),
		WithArg("viewIdentifier", royaltyIden),
	).MarshalAs(&royalty)

	assert.NoError(otu.T, err)

	for _, item := range royalty.Items {
		if item.Description == royaltyName {
			assert.Equal(otu.T, expectedPlatformRoyalty, item.Cut)
			return otu
		}
	}

	assert.Equal(otu.T, expectedPlatformRoyalty, 0.0)
	return otu
}

func (otu *OverflowTestUtils) buyNFTForMarketSale(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("buyNFTForSale",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketSale.Sale", map[string]interface{}{
			"amount": price,
			"id":     id,
			"seller": otu.O.Address(seller),
			"buyer":  otu.O.Address(name),
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseAuctionBidMarketSoft(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidMarketAuctionSoft",
		WithSigner(name),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": totalPrice,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseAuctionBidLeaseMarketSoft(buyer string, name string, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidLeaseMarketAuctionSoft",
		WithSigner(buyer),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": totalPrice,
			"buyer":  otu.O.Address(buyer),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) saleItemListed(name string, saleType string, price float64) *OverflowTestUtils {
	t := otu.T
	itemsForSale := otu.getItemsForSale(name)

	assert.Equal(t, 1, len(itemsForSale))
	assert.Equal(t, saleType, itemsForSale[0].SaleType)
	assert.Equal(t, price, itemsForSale[0].Amount)
	return otu
}

func (otu *OverflowTestUtils) saleLeaseListed(name string, saleType string, price float64) *OverflowTestUtils {
	t := otu.T
	itemsForSale := otu.getLeasesForSale(name)

	assert.Equal(t, 1, len(itemsForSale))
	assert.Equal(t, saleType, itemsForSale[0].SaleType)
	assert.Equal(t, price, itemsForSale[0].Amount)
	return otu
}

func (otu *OverflowTestUtils) auctionBidMarketEscrow(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("bidMarketAuctionEscrowed",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) auctionBidMarketSoft(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("bidMarketAuctionSoftDapper",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) auctionBidLeaseMarketSoft(buyer string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
		WithSigner(buyer),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": price,
			"buyer":  otu.O.Address(buyer),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseDirectOfferMarketEscrowed(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidMarketDirectOfferEscrowed",
		WithSigner(name),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"amount": totalPrice,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_offered",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseDirectOfferMarketSoft(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidMarketDirectOfferSoft",
		WithSigner(name),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": totalPrice,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_offered",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseDirectOfferLeaseMarketSoft(user, name string, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidLeaseMarketDirectOfferSoft",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": totalPrice,
			"buyer":  otu.O.Address(user),
			"status": "active_offered",
		})

	return otu
}

func (otu *OverflowTestUtils) directOfferMarketEscrowed(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidMarketDirectOfferEscrowed",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) directOfferMarketSoft(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) directOfferLeaseMarketSoft(user string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("bidLeaseMarketDirectOfferSoftDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": price,
			"buyer":  otu.O.Address(user),
		})

	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferMarketEscrowed(name string, id uint64, buyer string, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketDirectOfferEscrowed",
		WithSigner(name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"id":     id,
			"seller": otu.O.Address(name),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferMarketSoft(name string, id uint64, buyer string, price float64) *OverflowTestUtils {
	otu.O.Tx("acceptDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"id":     id,
			"seller": otu.O.Address(name),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "active_accepted",
		})

	return otu
}

func (otu *OverflowTestUtils) acceptLeaseDirectOfferMarketSoft(buyer, seller string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("acceptLeaseDirectOfferSoftDapper",
		WithSigner(seller),
		WithArg("leaseName", name),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"seller": otu.O.Address(seller),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "active_accepted",
		})

	return otu
}

func (otu *OverflowTestUtils) rejectDirectOfferEscrowed(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("cancelMarketDirectOfferEscrowed",
		WithSigner(name),
		WithArg("ids", []uint64{id}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"status": "rejected",
			"id":     id,
			"seller": otu.O.Address(name),
			"amount": price,
		})

	return otu
}

func (otu *OverflowTestUtils) retractOfferDirectOfferEscrowed(buyer, seller string, id uint64) *OverflowTestUtils {
	otu.O.Tx("retractOfferMarketDirectOfferEscrowed",
		WithSigner(buyer),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"status": "cancel",
			"id":     id,
			"seller": otu.O.Address(seller),
		})

	return otu
}

func (otu *OverflowTestUtils) rejectDirectOfferSoft(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("cancelMarketDirectOfferSoft",
		WithSigner(name),
		WithArg("ids", []uint64{id}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel_rejected",
			"id":     id,
			"seller": otu.O.Address(name),
			"amount": price,
		})

	return otu
}

func (otu *OverflowTestUtils) rejectDirectOfferLeaseSoft(user, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("cancelLeaseMarketDirectOfferSoft",
		WithSigner(user),
		WithArg("leaseNames", []string{name}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel_rejected",
			"seller": otu.O.Address(user),
			"amount": price,
		})

	return otu
}

func (otu *OverflowTestUtils) retractOfferDirectOfferSoft(buyer, seller string, id uint64) *OverflowTestUtils {
	otu.O.Tx("retractOfferMarketDirectOfferSoft",
		WithSigner(buyer),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel",
			"id":     id,
			"seller": otu.O.Address(seller),
		})

	return otu
}

func (otu *OverflowTestUtils) retractOfferDirectOfferLeaseSoft(buyer, seller, name string) *OverflowTestUtils {
	otu.O.Tx("retractOfferLeaseMarketDirectOfferSoft",
		WithSigner(buyer),
		WithArg("leaseName", name),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel",
			"seller": otu.O.Address(seller),
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionEscrowFromBidder(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketAuctionEscrowedFromBidder",
		WithSigner(name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionEscrow(name string, id uint64, buyer string, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketAuctionEscrowed",
		WithSigner(name),
		WithArg("owner", name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"id":     id,
			"seller": otu.O.Address(name),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionSoft(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketAuctionSoftDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketAuctionSoft(user string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"buyer":  otu.O.Address(user),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketDirectOfferSoft(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketDirectOfferSoft(user, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillLeaseMarketDirectOfferSoftDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"buyer":  otu.O.Address(user),
			"amount": price,
			"status": "sold",
		})

	return otu
}

type Cap struct {
	Address string
	Id      uint64
}
type Royalty struct {
	Items []struct {
		Description string  `json:"description"`
		Receiver    Cap     `json:"receiver"`
		Cut         float64 `json:"cut"`
	} `json:"cutInfos"`
}

func (otu *OverflowTestUtils) getItemsForSale(name string) []SaleItemInformation {
	var findReport FINDReport
	err := otu.O.Script("getFindMarket",
		WithArg("user", name),
	).MarshalAs(&findReport)
	if err != nil {
		require.NoError(otu.T, err)
		//    panic(err)
	}
	var list []SaleItemInformation
	for _, saleItemCollectionReport := range findReport.ItemsForSale {
		list = append(list, saleItemCollectionReport.Items...)
	}
	return list
}

func (otu *OverflowTestUtils) getLeasesForSale(name string) []SaleItemInformation {
	var findReport FINDReport
	err := otu.O.Script("getFindLeaseMarket",
		WithArg("user", name),
	).MarshalAs(&findReport)
	if err != nil {
		require.NoError(otu.T, err)
		//		swallowErr(err)
	}
	var list []SaleItemInformation
	for _, saleItemCollectionReport := range findReport.LeasesForSale {
		list = append(list, saleItemCollectionReport.Items...)
	}
	return list
}

func (otu *OverflowTestUtils) removeFTInFtRegistry(transactionFile, argument, eventName string, eventResult map[string]interface{}) *OverflowTestUtils {
	arg := WithArg("typeIdentifier", argument)

	if transactionFile == "adminRemoveFTInfoByAlias" {
		arg = WithArg("alias", argument)
	}

	otu.O.Tx(transactionFile,
		WithSigner("find-admin"),
		arg,
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventName, eventResult)

	return otu
}

func (otu *OverflowTestUtils) setProfile(user string) *OverflowTestUtils {
	otu.O.Tx("setProfile",
		WithSigner(user),
		WithArg("avatar", "https://find.xyz/assets/img/avatars/avatar14.png"),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) alterMarketOption(ruleName string) *OverflowTestUtils {
	otu.O.Tx("devAlterMarketOption",
		WithSigner("find"),
		WithArg("action", ruleName),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) alterMarketOptionDapper(ruleName string) *OverflowTestUtils {
	otu.O.Tx("devAlterMarketOptionDapper",
		WithSigner("find"),
		WithArg("action", ruleName),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) alterLeaseMarketOption(ruleName string) *OverflowTestUtils {
	otu.O.Tx("devAlterLeaseMarketOption",
		WithSigner("find"),
		WithArg("action", ruleName),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) setFindCut(cut float64) *OverflowTestUtils {
	otu.O.Tx("adminSetFindCut",
		WithSigner("find-admin"),
		WithArg("tenant", "find"),
		WithArg("cut", cut),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindCutRules", map[string]interface{}{
			"tenant":   "find",
			"ruleName": "findRoyalty",
			"cut":      cut,
			"status":   "active",
		})

	return otu
}

func (otu *OverflowTestUtils) removeProfileWallet(user string) *OverflowTestUtils {
	otu.O.Tx("devRemoveProfileWallet",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) destroyFUSDVault(user string) *OverflowTestUtils {
	otu.O.Tx("devDestroyFUSDVault",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) unlinkDandyProvider(user string) *OverflowTestUtils {
	otu.O.Tx("devUnlinkDandyProvider",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) unlinkDandyReceiver(user string) *OverflowTestUtils {
	otu.O.Tx("devUnlinkDandyReceiver",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) destroyDandyCollection(user string) *OverflowTestUtils {
	otu.O.Tx("devDestroyDandyCollection",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) sendDandy(receiver, sender string, id uint64) *OverflowTestUtils {
	otu.O.Tx("sendDandy",
		WithSigner(sender),
		WithArg("user", receiver),
		WithArg("id", id),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) profileBan(user string) *OverflowTestUtils {
	otu.O.Tx("adminSetProfileBan",
		WithSigner("find"),
		WithArg("user", user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) leaseProfileBan(user string) *OverflowTestUtils {
	otu.O.Tx("adminSetProfileBan",
		WithSigner("find"),
		WithArg("user", user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) removeProfileBan(user string) *OverflowTestUtils {
	otu.O.Tx("adminRemoveProfileBan",
		WithSigner("find"),
		WithArg("user", user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) removeLeaseProfileBan(user string) *OverflowTestUtils {
	otu.O.Tx("adminRemoveProfileBan",
		WithSigner("find"),
		WithArg("user", user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) moveNameTo(owner, receiver, name string) *OverflowTestUtils {
	otu.O.Tx("moveNameTO",
		WithSigner(owner),
		WithArg("name", name),
		WithArg("receiver", otu.O.Address(receiver)),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Moved", map[string]interface{}{
			"name": name,
		})

	return otu
}

func (otu *OverflowTestUtils) listNFTForSaleDUC(name string, id uint64, price float64) []uint64 {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	eventIden, err := otu.O.QualifiedIdentifier("FindMarketSale", "Sale")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("listNFTForSaleDapper",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", ftIden),
		WithArg("directSellPrice", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent(eventIden, "id")

	return res
}

func (otu *OverflowTestUtils) listLeaseForSaleDUC(user string, name string, price float64) *OverflowTestUtils {
	ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("listLeaseForSaleDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", ftIden),
		WithArg("directSellPrice", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	)

	res.AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) buyLeaseForMarketSaleDUC(buyer, seller, name string, price float64) *OverflowTestUtils {
	amount := price * 0.025
	dapperAmount := price * 0.01
	if dapperAmount < 0.44 {
		dapperAmount = 0.44
	}
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketSale", "Sale")
	assert.NoError(otu.T, err)

	otu.O.Tx("buyLeaseForSaleDapper",
		WithSigner(buyer),
		WithPayloadSigner("dapper"),
		WithArg("sellerAccount", seller),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"amount": price,
			"seller": otu.O.Address(seller),
			"buyer":  otu.O.Address(buyer),
			"status": "sold",
		}).
		AssertEvent(otu.T, "RoyaltyPaid", map[string]interface{}{
			"amount":      amount,
			"address":     otu.O.Address("find"),
			"royaltyName": "find",
			"tenant":      "find",
		}).
		AssertEvent(otu.T, "RoyaltyPaid", map[string]interface{}{
			"amount":      dapperAmount,
			"address":     otu.O.Address("dapper"),
			"royaltyName": "dapper",
			"tenant":      "find",
		})

	return otu
}

func (otu *OverflowTestUtils) listNFTForSoftAuctionDUC(name string, id uint64, price float64) []uint64 {
	ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	eventIden, err := otu.O.QualifiedIdentifier("FindMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("listNFTForAuctionSoftDapper",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", ftIden),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+10.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent(eventIden, "id")

	return res
}

func (otu *OverflowTestUtils) listLeaseForSoftAuctionDUC(user, name string, price float64) *OverflowTestUtils {
	ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	otu.O.Tx("listLeaseForAuctionSoftDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", ftIden),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+10.0),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) auctionBidMarketSoftDUC(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidMarketAuctionSoftDapper",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) auctionBidLeaseMarketSoftDUC(user string, name string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"amount": price,
			"buyer":  otu.O.Address(user),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketAuctionSoftDUC(user string, name string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"buyer":  otu.O.Address(user),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionSoftDUC(name string, id uint64, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	otu.O.Tx("fulfillMarketAuctionSoftDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) directOfferMarketSoftDUC(name string, seller string, id uint64, price float64) []uint64 {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	DUC, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("bidMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", DUC),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent("FindMarketDirectOfferSoft.DirectOffer", "id")

	return res
}

func (otu *OverflowTestUtils) directOfferLeaseMarketSoftDUC(buyer string, name string, price float64) *OverflowTestUtils {
	DUC, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidLeaseMarketDirectOfferSoftDapper",
		WithSigner(buyer),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", DUC),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferMarketSoftDUC(name string, id uint64, buyer string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindMarketDirectOfferSoft", "DirectOffer")
	assert.NoError(otu.T, err)

	otu.O.Tx("acceptDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"id":     id,
			"seller": otu.O.Address(name),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "active_accepted",
		})

	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferLeaseMarketSoftDUC(buyer, seller string, name string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketDirectOfferSoft", "DirectOffer")
	assert.NoError(otu.T, err)

	otu.O.Tx("acceptLeaseDirectOfferSoftDapper",
		WithSigner(seller),
		WithArg("leaseName", name),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"seller": otu.O.Address(seller),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "active_accepted",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketDirectOfferSoftDUC(name string, id uint64, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindMarketDirectOfferSoft", "DirectOffer")
	assert.NoError(otu.T, err)

	otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketDirectOfferSoftDUC(user, name string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketDirectOfferSoft", "DirectOffer")
	assert.NoError(otu.T, err)

	otu.O.Tx("fulfillLeaseMarketDirectOfferSoftDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"buyer":  otu.O.Address(user),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) SendNFTsLostAndFound(nftType string, id uint64, receiver string) uint64 {
	t := otu.T
	res := otu.O.Tx("sendNFTs",
		WithSigner("user1"),
		WithArg("nftIdentifiers", []string{nftType}),
		WithArg("allReceivers", []string{otu.O.Address(receiver)}),
		WithArg("ids", []uint64{id}),
		WithArg("memos", `["Hello!"]`),
		WithArg("donationTypes", `[nil]`),
		WithArg("donationAmounts", `[nil]`),
		WithArg("findDonationType", nil),
		WithArg("findDonationAmount", nil),
	).
		AssertSuccess(t).
		AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
			"receiver": otu.O.Address(receiver),
			"sender":   otu.O.Address("user1"),
			"type":     nftType,
			"memo":     "Hello!",
			"name":     "Neo Motorcycle 1 of 3",
		})
	ticketID, err := res.GetIdFromEvent("FindLostAndFoundWrapper.TicketDeposited", "ticketID")
	assert.NoError(otu.T, err)
	return ticketID
}

func generatePackStruct(o *OverflowState, user string, packTypeId uint64, itemType []string, whitelistTime float64, buyTime float64, openTime float64, requiresReservation bool, floatId uint64, clientAddress string) findGo.FindPack_PackRegisterInfo {
	flow, _ := o.QualifiedIdentifier("FlowToken", "Vault")

	saleInfo := []findGo.FindPack_PackRegisterSaleInfo{
		{
			Name:      "public sale",
			StartTime: buyTime,
			Price:     4.2,
			Verifiers: []findGo.FindVerifier_HasOneFLOAT{},
			VerifyAll: false,
		},
		{
			Name:      "whitelist sale",
			StartTime: whitelistTime,
			Price:     4.2,
			Verifiers: []findGo.FindVerifier_HasOneFLOAT{
				{
					FloatEventIds: []uint64{
						floatId,
					},
					Description: "",
				},
			},
			VerifyAll: true,
		},
	}

	return findGo.FindPack_PackRegisterInfo{
		Forge:           user,
		Name:            user,
		Description:     "description",
		TypeId:          packTypeId,
		ExternalURL:     "url",
		SquareImageHash: "thumbnailHash",
		BannerHash:      "bannerHash",
		Socials: map[string]string{
			"twitter": "@ABC",
		},
		PaymentAddress:      o.Address(clientAddress),
		PaymentType:         flow,
		OpenTime:            openTime,
		RequiresReservation: requiresReservation,
		NFTTypes:            itemType,
		StorageRequirement:  60000.0,
		SaleInfo:            saleInfo,
		PrimaryRoyalty: []findGo.FindPack_Royalty{
			{
				Recipient:   o.Address("find"),
				Cut:         0.15,
				Description: "find",
			},
		},
		SecondaryRoyalty: []findGo.FindPack_Royalty{},
		PackFields: map[string]string{
			"Items": "1",
		},
		Extra: map[string]interface{}{},
	}
}

func (otu *OverflowTestUtils) registerPackType(user string, packTypeId uint64, itemType []string, whitelistTime, buyTime, openTime float64, requiresReservation bool, floatId uint64, clientAddress, _ string) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	eventIden, err := otu.O.QualifiedIdentifier("FindPack", "MetadataRegistered")
	assert.NoError(otu.T, err)

	info := generatePackStruct(otu.O, user, packTypeId, itemType, whitelistTime, buyTime, openTime, requiresReservation, floatId, clientAddress)

	/*
		o.Tx("setupFindPackMinterPlatform",
			WithSigner(user),
			WithArg("lease", user),
		).
			AssertSuccess(t)
	*/

	o.Tx("adminRegisterFindPackMetadataStruct",
		WithSigner("find-admin"),
		WithArg("info", info),
	).
		AssertSuccess(t).
		AssertEvent(t, eventIden, map[string]interface{}{
			"packTypeId": packTypeId,
		})
	return otu
}

func (otu *OverflowTestUtils) mintPack(minter string, packTypeId uint64, input []uint64, types []string, salt string) uint64 {
	o := otu.O
	t := otu.T

	packHash := utils.CreateSha3Hash(input, types, salt)

	eventIden, err := otu.O.QualifiedIdentifier("FindPack", "%s")
	assert.NoError(otu.T, err)

	res, err := o.Tx("adminMintFindPack",
		WithSigner("find-admin"),
		WithArg("packTypeName", minter),
		WithArg("typeId", packTypeId),
		WithArg("hashes", []string{packHash}),
	).
		AssertSuccess(t).
		AssertEvent(t, fmt.Sprintf(eventIden, "Minted"), map[string]interface{}{
			"typeId": packTypeId,
		}).
		GetIdFromEvent(fmt.Sprintf(eventIden, "Deposit"), "id")

	publicPathIdentifier := "FindPack_" + minter + "_" + fmt.Sprint(packTypeId)

	otu.O.Tx("devaddNFTCatalog",
		WithSigner("account"),
		WithArg("collectionIdentifier", minter+" season#"+fmt.Sprint(packTypeId)),
		WithArg("contractName", fmt.Sprintf(eventIden, "NFT")),
		WithArg("contractAddress", "find"),
		WithArg("addressWithNFT", "find"),
		WithArg("nftID", res),
		WithArg("publicPathIdentifier", publicPathIdentifier),
	).
		AssertSuccess(otu.T)

	assert.NoError(t, err)
	return res
}

func (otu *OverflowTestUtils) buyPack(user, packTypeName string, packTypeId uint64, numberOfPacks uint64, amount float64) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	eventIden, err := otu.O.QualifiedIdentifier("FindPack", "Purchased")
	assert.NoError(otu.T, err)

	o.Tx("buyFindPack",
		WithSigner(user),
		WithArg("packTypeName", packTypeName),
		WithArg("packTypeId", packTypeId),
		WithArg("numberOfPacks", numberOfPacks),
		WithArg("totalAmount", amount),
	).
		AssertSuccess(t).
		AssertEvent(t, eventIden, map[string]interface{}{
			"amount":  amount,
			"address": otu.O.Address(user),
			"packFields": map[string]interface{}{
				"packImage": "ipfs://thumbnailHash",
				"Items":     "1",
			},
		})

	return otu
}

func (otu *OverflowTestUtils) openPack(user string, packId uint64) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	eventIden, err := otu.O.QualifiedIdentifier("FindPack", "Opened")
	assert.NoError(otu.T, err)

	o.Tx("openFindPack",
		WithSigner(user),
		WithArg("packId", packId),
	).
		AssertSuccess(t).
		AssertEvent(t, eventIden, map[string]interface{}{
			"packId":  packId,
			"address": otu.O.Address(user),
			"packFields": map[string]interface{}{
				"packImage": "ipfs://thumbnailHash",
				"Items":     "1",
			},
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillPack(packId uint64, ids []uint64, salt string) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	o.Tx("adminFulfillFindPack",
		WithSigner("find-admin"),
		WithArg("packId", packId),
		WithArg("typeIdentifiers", []string{dandyNFTType(otu)}),
		WithArg("rewardIds", ids),
		WithArg("salt", salt),
	).
		AssertSuccess(t).
		AssertEvent(t, "Fulfilled", map[string]interface{}{
			"packId": packId,
		})

	return otu
}

func (otu *OverflowTestUtils) createFloatEvent(minter string) uint64 {
	o := otu.O
	t := otu.T

	eventIden, err := otu.O.QualifiedIdentifier("FLOAT", "FLOATEventCreated")
	assert.NoError(otu.T, err)

	floatId, err := o.Tx("devfloatCreateEvent",
		WithSigner(minter),
		WithArg("forHost", minter),
		WithArg("claimable", true),
		WithArg("name", "FloatName"),
		WithArg("description", "FloatDesciption"),
		WithArg("image", "IMG"),
		WithArg("url", "URL"),
		WithArg("transferrable", true),
		WithArg("timelock", false),
		WithArg("dateStart", 0.0),
		WithArg("timePeriod", 0.0),
		WithArg("secret", false),
		WithArg("secrets", `[]`),
		WithArg("limited", false),
		WithArg("capacity", 0),
		WithArg("initialGroups", `[]`),
		WithArg("flowTokenPurchase", false),
		WithArg("flowTokenCost", 0.0),
	).
		AssertSuccess(t).
		GetIdFromEvent(eventIden, "eventId")

	assert.NoError(t, err)
	return floatId
}

func (otu *OverflowTestUtils) claimFloat(minter, receiver string, floatId uint64) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	o.Tx("devfloatClaim",
		WithSigner(receiver),
		WithArg("eventId", floatId),
		WithArg("host", minter),
	).
		AssertSuccess(t)

	return otu
}

func (otu *OverflowTestUtils) addRelatedAccount(user, wallet, network, address string) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	var res *OverflowResult
	if network == "Flow" {

		res = o.Tx("addRelatedFlowAccount",
			WithSigner(user),
			WithArg("name", wallet),
			WithArg("address", address),
		)
		address = o.Address(address)
	} else {
		res = o.Tx("addRelatedAccount",
			WithSigner(user),
			WithArg("name", wallet),
			WithArg("network", network),
			WithArg("address", address),
		)
	}

	res.AssertSuccess(t).
		AssertEvent(t, "RelatedAccount", map[string]interface{}{
			"user":       otu.O.Address(user),
			"walletId":   fmt.Sprintf("%s_%s_%s", network, wallet, address),
			"walletName": wallet,
			"address":    address,
			"network":    network,
			"action":     "add",
		})
	return otu
}

func (otu *OverflowTestUtils) updateRelatedAccount(user, wallet, network, oldAddress, address string) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	var res *OverflowResult
	if network == "Flow" {

		res = o.Tx("updateRelatedFlowAccount",
			WithSigner(user),
			WithArg("name", wallet),
			WithArg("oldAddress", oldAddress),
			WithArg("address", address),
		)
		address = o.Address(address)
		oldAddress = o.Address(oldAddress)
	} else {
		res = o.Tx("updateRelatedAccount",
			WithSigner(user),
			WithArg("name", wallet),
			WithArg("network", network),
			WithArg("oldAddress", oldAddress),
			WithArg("address", address),
		)
	}

	res.AssertSuccess(t).
		AssertEvent(t, "RelatedAccount", map[string]interface{}{
			"walletId":   fmt.Sprintf("%s_%s_%s", network, wallet, address),
			"walletName": wallet,
			"address":    address,
			"network":    network,
			"action":     "add",
		}).
		AssertEvent(t, "RelatedAccount", map[string]interface{}{
			"user":       otu.O.Address(user),
			"walletId":   fmt.Sprintf("%s_%s_%s", network, wallet, oldAddress),
			"walletName": wallet,
			"address":    oldAddress,
			"network":    network,
			"action":     "remove",
		})
	return otu
}

func (otu *OverflowTestUtils) reactToThought(thoughtId uint64, reaction string) *OverflowTestUtils {
	t := otu.T
	otu.O.Tx("reactToFindThoughts",
		WithSigner("user2"),
		WithArg("users", []string{"user1"}),
		WithArg("ids", []uint64{thoughtId}),
		WithArg("reactions", []string{reaction}),
		WithArg("undoReactionUsers", `[]`),
		WithArg("undoReactionIds", `[]`),
	).
		AssertSuccess(t).
		AssertEvent(t, "FindThoughts.Reacted", map[string]interface{}{
			"id":          thoughtId,
			"by":          otu.O.Address("user2"),
			"byName":      "user2",
			"creator":     otu.O.Address("user1"),
			"creatorName": "user1",
			"reaction":    reaction,
			"totalCount": map[string]interface{}{
				"fire": "1",
			},
		})
	return otu
}

func (otu *OverflowTestUtils) postExampleThought() uint64 {
	t := otu.T
	header := "This is header"
	body := "This is body"
	tags := []string{"tag1", "tag2", "@find"}
	mediaHash := "ipfs://mediaHash"
	mediaType := "mediaType"

	cadMediaHash, err := otu.createOptional(mediaHash)
	assert.NoError(t, err)
	cadMediaType, err := otu.createOptional(mediaType)
	assert.NoError(t, err)

	thoughtId, _ := otu.O.Tx("publishFindThought",
		WithSigner("user1"),
		WithArg("header", header),
		WithArg("body", body),
		WithArg("tags", tags),
		WithArg("mediaHash", cadMediaHash),
		WithArg("mediaType", cadMediaType),
		WithArg("quoteNFTOwner", nil),
		WithArg("quoteNFTType", nil),
		WithArg("quoteNFTId", nil),
		WithArg("quoteCreator", nil),
		WithArg("quoteId", nil),
	).
		AssertSuccess(t).
		AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
			"creator":     otu.O.Address("user1"),
			"creatorName": "user1",
			"header":      header,
			"message":     body,
			"medias": []interface{}{
				mediaHash,
			},
			"tags": []interface{}{"tag1", "tag2", "@find"},
		}).
		GetIdFromEvent("FindThoughts.Published", "id")
	return thoughtId
}

func (otu *OverflowTestUtils) createOptional(value any) (cadence.Value, error) {
	val, err := underflow.NewCadenceValue(value)
	if err != nil {
		return nil, err
	}
	opt := cadence.NewOptional(val)
	return opt, nil
}

func (otu *OverflowTestUtils) identifier(contract, structName string) string {
	s, err := otu.O.QualifiedIdentifier(contract, structName)
	assert.NoError(otu.T, err)
	return s
}

type SaleItem struct {
	Bidder              string  `json:"bidder"`
	ExtensionOnLateBid  string  `json:"extensionOnLateBid"`
	FtType              string  `json:"ftType"`
	FtTypeIdentifier    string  `json:"ftTypeIdentifier"`
	ListingValidUntil   string  `json:"listingValidUntil"`
	Owner               string  `json:"owner"`
	SaleType            string  `json:"saleType"`
	Type                string  `json:"type"`
	TypeID              string  `json:"typeId"`
	Amount              float64 `json:"amount"`
	AuctionReservePrice float64 `json:"auctionReservePrice"`
	ID                  uint64  `json:"id"`
}

type Report struct {
	FINDReport FINDReport `json:"FINDReport"`
	NameReport NameReport `json:"NameReport"`
}

type NameReport struct {
	Status string  `json:"status"`
	Cost   float64 `json:"cost"`
}

type FINDReport struct {
	Profile         interface{}                          `json:"profile"`
	RelatedAccounts map[string]interface{}               `json:"relatedAccounts"`
	LeasesForSale   map[string]SaleItemCollectionReport  `json:"leasesForSale"`
	LeasesBids      map[string]MarketBidCollectionPublic `json:"leasesBids"`
	ItemsForSale    map[string]SaleItemCollectionReport  `json:"itemsForSale"`
	MarketBids      map[string]MarketBidCollectionPublic `json:"marketBids"`
	PrivateMode     string                               `json:"privateMode"`
	Bids            []interface{}                        `json:"bids"`
	Leases          []LeaseInformation                   `json:"leases"`
}

type LeaseInformation struct {
	Address            string   `json:"address"`
	LatestBidBy        string   `json:"latestBidBy"`
	Name               string   `json:"name"`
	Status             string   `json:"status"`
	Addons             []string `json:"addons"`
	Cost               int      `json:"cost"`
	CurrentTime        int      `json:"currentTime"`
	ExtensionOnLateBid int      `json:"extensionOnLateBid"`
	LatestBid          int      `json:"latestBid"`
	LockedUntil        int      `json:"lockedUntil"`
	SalePrice          int      `json:"salePrice"`
	ValidUntil         int      `json:"validUntil"`
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
	BidAmount         string              `json:"bidAmount"`
	BidTypeIdentifier string              `json:"bidTypeIdentifier"`
	Name              string              `json:"name"`
	Item              SaleItemInformation `json:"item"`
	Id                uint64              `json:"id"`
}

type SaleItemInformation struct {
	Auction               *AuctionItem `json:"auction,omitempty"`
	BidderName            string       `json:"bidderName"`
	Seller                string       `json:"seller"`
	SellerName            string       `json:"sellerName"`
	NftIdentifier         string       `json:"nftIdentifier"`
	Bidder                string       `json:"bidder"`
	LeaseName             string       `json:"leaseName"`
	LeaseIdentifier       string       `json:"leaseIdentifier"`
	SaleType              string       `json:"saleType"`
	ListingTypeIdentifier string       `json:"listingTypeIdentifier"`
	FtAlias               string       `json:"ftAlias"`
	FtTypeIdentifier      string       `json:"ftTypeIdentifier"`
	ListingStatus         string       `json:"listingStatus"`
	Amount                float64      `json:"amount"`
	ListingValidUntil     float64      `json:"listingValidUntil"`
	ListingId             uint64       `json:"listingId"`
	NftId                 uint64       `json:"nftId"`
}

type AuctionItem struct {
	StartPrice          float64 `json:"startPrice"`
	CurrentPrice        float64 `json:"currentPrice"`
	MinimumBidIncrement float64 `json:"minimumBidIncrement"`
	ReservePrice        float64 `json:"reservePrice"`
	ExtentionOnLateBid  float64 `json:"extentionOnLateBid"`
	AuctionEndsAt       float64 `json:"auctionEndsAt"`
	// Timestamp           string `json:"timestamp"`
}

type GhostListing struct {
	ListingType           string `json:"listingType"`
	ListingTypeIdentifier string `json:"listingTypeIdentifier"`
	Id                    uint64 `json:"id"`
}

type CollectionData struct {
	Collection          string `json:"collection"`
	Media               string `json:"media"`
	MediaType           string `json:"mediaType"`
	Name                string `json:"name"`
	NftDetailIdentifier string `json:"nftDetailIdentifier"`
	Source              string `json:"source"`
	SubCollection       string `json:"subCollection"`
	Edition             int    `json:"edition"`
	SoulBounded         bool   `json:"soulBounded"`
}
