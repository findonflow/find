package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	adminSigner := WithSigner("find-admin")

	o := Overflow(
		WithNetwork("mainnet"),
		WithGlobalPrintOptions(),
	)

	o.Tx("adminAddNFTCatalog",
		WithSigner("find"),
		WithArg("collectionIdentifier", "A.9a57dfe5c8ce609c.SoulMadeMain"),
		WithArg("contractName", "SoulMadeMain"),
		WithArg("contractAddress", "0x9a57dfe5c8ce609c"),
		WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
		WithArg("nftID", 7352),
		WithArg("publicPathIdentifier", "SoulMadeMainCollection"),
	)

	o.Tx("adminAddNFTCatalog",
		WithSigner("find"),
		WithArg("collectionIdentifier", "A.9a57dfe5c8ce609c.SoulMadeComponent"),
		WithArg("contractName", "SoulMadeComponent"),
		WithArg("contractAddress", "0x9a57dfe5c8ce609c"),
		WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
		WithArg("nftID", 33029),
		WithArg("publicPathIdentifier", "SoulMadeComponentCollection"),
	)

	upsertItem := o.TxFileNameFN("adminMainnetAddItem",
		adminSigner,
		WithArg("tenant", "find"),
		WithArg("ftName", "flow"),
		WithArg("ftTypes", `["A.1654653399040a61.FlowToken.Vault"]`),
		WithArg("listingName", "escrow"),
		WithArg("listingTypes", `["A.097bafa4e0b48eef.FindMarketSale.SaleItem" , "A.097bafa4e0b48eef.FindMarketAuctionEscrow.SaleItem" , "A.097bafa4e0b48eef.FindMarketDirectOfferEscrow.SaleItem"]`),
	)

	flowNfts := map[string]string{
		"SoulMade": `["A.9a57dfe5c8ce609c.SoulMadeComponent", "A.9a57dfe5c8ce609c.SoulMadeMain"]`,
	}

	for name, contracts := range flowNfts {
		upsertItem(
			WithArg("nftName", name), //primary key
			WithArg("nftTypes", contracts),
		)
	}
	/*
		o.Tx("adminAddForge",
			adminSigner,
			WithPayloadSigner("find-forge"),
			WithArg("storagePath", "/storage/nfgforge"),
			WithArg("name", "nonfungerbils"),
		)
	*/

}
