package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	adminSigner := WithSigner("find")

	o := Overflow(
		WithNetwork("testnet"),
		WithGlobalPrintOptions(),
	)

	upsertItem := o.TxFN(
		adminSigner,
		WithArg("cut", 0.0),
	)

	flowNfts := map[string]string{
		"FlovatarComponent": "A.9392a4a7c3f49a0b.FlovatarComponent.NFT",
		/*
			"bl0x":       `["A.7620acf6d7f2468a.Bl0x.NFT"]`,
			"pharaohs":   `["A.9d21537544d9123d.Momentables.NFT"]`,
			"versus":     `["A.d796ff17107bbff6.Art.NFT"]`,
			"flovatar":   `["A.921ea449dffec68a.Flovatar.NFT" , "A.921ea449dffec68a.FlovatarComponent.NFT"]`,
			"neoCharity": `["A.097bafa4e0b48eef.CharityNFT.NFT"]`,
			"starly":     `["A.5b82f21c0edf76e3.StarlyCard.NFT"]`,
			"float":      `["A.2d4c3caffbeab845.FLOAT.NFT"]`,
			"dayNFT":     `["A.1600b04bf033fb99.DayNFT.NFT"]`,
			"BYC": `["A.195caada038c5806.BarterYardClubWerewolf.NFT"]`,
		*/
	}

	for name, contracts := range flowNfts {
		/*
			upsertItem(
				"tenantsetMarketOptionDapper",
				WithArg("nftName", name), //primary key
				WithArg("nftTypes", []string{contracts}),
			)
		*/

		upsertItem(
			"tenantsetMarketOption",
			WithArg("nftName", name), //primary key
			WithArg("nftTypes", []string{contracts}),
		)
	}
	// o.Tx("adminAddNFTCatalog",
	// 	WithSigner("find-admin"),
	// 	WithArg("collectionIdentifier", "A.195caada038c5806.BarterYardClubWerewolf.NFT"),
	// 	WithArg("contractName", "BarterYardClubWerewolf"),
	// 	WithArg("contractAddress", "0x195caada038c5806"),
	// 	WithArg("addressWithNFT", "0x2a2d480b4037029d"),
	// 	WithArg("nftID", 2),
	// 	WithArg("publicPathIdentifier", "BarterYardClubWerewolfCollection"),
	// )

}
