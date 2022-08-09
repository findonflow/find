package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	adminSigner := WithSigner("find-admin")

	o := Overflow(
		WithNetwork("testnet"),
		WithGlobalPrintOptions(),
	)

	upsertItem := o.TxFileNameFN("adminMainnetAddItem",
		adminSigner,
		WithArg("tenant", "find"),
		WithArg("ftName", "flow"),
		WithArg("ftTypes", `["A.7e60df042a9c0868.FlowToken.Vault"]`),
		WithArg("listingName", "escrow"),
		WithArg("listingTypes", `["A.35717efbbce11c74.FindMarketSale.SaleItem" , "A.35717efbbce11c74.FindMarketAuctionEscrow.SaleItem" , "A.35717efbbce11c74.FindMarketDirectOfferEscrow.SaleItem"]`),
	)

	flowNfts := map[string]string{
		"BYC": `["A.195caada038c5806.BarterYardClubWerewolf.NFT"]`,
		/*
			"bl0x":       `["A.7620acf6d7f2468a.Bl0x.NFT"]`,
			"pharaohs":   `["A.9d21537544d9123d.Momentables.NFT"]`,
			"versus":     `["A.d796ff17107bbff6.Art.NFT"]`,
			"flovatar":   `["A.921ea449dffec68a.Flovatar.NFT" , "A.921ea449dffec68a.FlovatarComponent.NFT"]`,
			"neoCharity": `["A.097bafa4e0b48eef.CharityNFT.NFT"]`,
			"starly":     `["A.5b82f21c0edf76e3.StarlyCard.NFT"]`,
			"float":      `["A.2d4c3caffbeab845.FLOAT.NFT"]`,
			"dayNFT":     `["A.1600b04bf033fb99.DayNFT.NFT"]`,
		*/
	}

	for name, contracts := range flowNfts {
		upsertItem(
			WithArg("nftName", name), //primary key
			WithArg("nftTypes", contracts),
		)
	}
	o.Tx("adminAddNFTCatalog",
		WithSigner("find"),
		WithArg("collectionIdentifier", "A.195caada038c5806.BarterYardClubWerewolf.NFT"),
		WithArg("contractName", "BarterYardClubWerewolf"),
		WithArg("contractAddress", "0x195caada038c5806"),
		WithArg("addressWithNFT", "0x2a2d480b4037029d"),
		WithArg("nftID", 2),
		WithArg("publicPathIdentifier", "BarterYardClubWerewolfCollection"),
	)

}
