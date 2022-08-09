package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	//adminSigner := WithSigner("find-admin")

	o := Overflow(
		WithNetwork("mainnet"),
		WithGlobalPrintOptions(),
	)
	o.Tx("adminAddNFTCatalog",
		WithSigner("find"),
		WithArg("collectionIdentifier", "A.123cb666996b8432.NFGv3.NFT"),
		WithArg("contractName", "NonFunGerbils"),
		WithArg("contractAddress", "0x123cb666996b8432"),
		WithArg("addressWithNFT", "0x7f97054dc583b63c"),
		WithArg("nftID", 423757528),
		WithArg("publicPathIdentifier", "nfgNFTCollection"),
	)

	/*
		o.Tx("adminAddForge",
			adminSigner,
			WithPayloadSigner("find-forge"),
			WithArg("storagePath", "/storage/nfgforge"),
			WithArg("name", "nonfungerbils"),
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
			"NFGv3'": `["A.123cb666996b8432.NFGv3.NFT"]`,
			/*
				  "BYC'": `["A.28abb9f291cadaf2.BarterYardClubWerewolf.NFT"]`,
					"bl0x":       `["A.7620acf6d7f2468a.Bl0x.NFT"]`,
					"pharaohs":   `["A.9d21537544d9123d.Momentables.NFT"]`,
					"versus":     `["A.d796ff17107bbff6.Art.NFT"]`,
					"flovatar":   `["A.921ea449dffec68a.Flovatar.NFT" , "A.921ea449dffec68a.FlovatarComponent.NFT"]`,
					"neoCharity": `["A.097bafa4e0b48eef.CharityNFT.NFT"]`,
					"starly":     `["A.5b82f21c0edf76e3.StarlyCard.NFT"]`,
					"float":      `["A.2d4c3caffbeab845.FLOAT.NFT"]`,
					"dayNFT":     `["A.1600b04bf033fb99.DayNFT.NFT"]`,
		}

		for name, contracts := range flowNfts {
			upsertItem(
				WithArg("nftName", name), //primary key
				WithArg("nftTypes", contracts),
			)
		}
	*/
}
