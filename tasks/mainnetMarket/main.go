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

	/*
		o.Tx("adminRemoveNFTCatalog",
			adminSigner,
			WithArg("collectionIdentifier", "A.9a57dfe5c8ce609c.SoulMadeComponent"),
		)

		o.Tx("adminAddNFTCatalog",
			adminSigner,
			WithArg("collectionIdentifier", "SoulMadeComponent"),
			WithArg("contractName", "SoulMadeComponent"),
			WithArg("contractAddress", "0x9a57dfe5c8ce609c"),
			WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
			WithArg("nftID", 33029),
			WithArg("publicPathIdentifier", "SoulMadeComponentCollection"),
		)
			o.Tx("adminAddNFTCatalog",
				adminSigner,
				WithArg("collectionIdentifier", "SoulMade"),
				WithArg("contractName", "SoulMadeMain"),
				WithArg("contractAddress", "0x9a57dfe5c8ce609c"),
				WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
				WithArg("nftID", 7352),
				WithArg("publicPathIdentifier", "SoulMadeMainCollection"),
			)

			o.Tx("adminAddNFTCatalog",
				adminSigner,
				WithArg("collectionIdentifier", "SoulMadeComponent"),
				WithArg("contractName", "SoulMadeComponent"),
				WithArg("contractAddress", "0x9a57dfe5c8ce609c"),
				WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
				WithArg("nftID", 33029),
				WithArg("publicPathIdentifier", "SoulMadeComponentCollection"),
			)

			o.Tx("adminAddNFTCatalog",
				adminSigner,
				WithArg("collectionIdentifier", "Bitku"),
				WithArg("contractName", "HaikuNFT"),
				WithArg("contractAddress", "0xf61e40c19db2a9e2"),
				WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
				WithArg("nftID", 225),
				WithArg("publicPathIdentifier", "BitkuCollection"),
			)

			o.Tx("adminAddNFTCatalog",
				adminSigner,
				WithArg("collectionIdentifier", "some.place"),
				WithArg("contractName", "SomePlaceCollectible"),
				WithArg("contractAddress", "0x667a16294a089ef"),
				WithArg("addressWithNFT", "0x886f3aeaf848c535"),
				WithArg("nftID", 164769803),
				WithArg("publicPathIdentifier", "somePlaceCollectibleCollection"),
			)

			o.Tx("adminAddNFTCatalog",
				adminSigner,
				WithArg("collectionIdentifier", "bl0xPack"),
				WithArg("contractName", "Bl0xPack"),
				WithArg("contractAddress", "0x7620acf6d7f2468a"),
				WithArg("addressWithNFT", "0x0893d4423f25c7d6"),
				WithArg("nftID", 208638414),
				WithArg("publicPathIdentifier", "Bl0xPackCollection"),
			)
	*/

	upsertItem := o.TxFileNameFN("adminMainnetAddItem",
		adminSigner,
		WithArg("tenant", "find"),
		WithArg("ftName", "flow"),
		WithArg("ftTypes", `["A.1654653399040a61.FlowToken.Vault"]`),
		WithArg("listingName", "escrow"),
		WithArg("listingTypes", `["A.097bafa4e0b48eef.FindMarketSale.SaleItem" , "A.097bafa4e0b48eef.FindMarketAuctionEscrow.SaleItem" , "A.097bafa4e0b48eef.FindMarketDirectOfferEscrow.SaleItem"]`),
	)

	flowNfts := map[string]string{
		// "SoulMade": `["A.9a57dfe5c8ce609c.SoulMadeComponent.NFT", "A.9a57dfe5c8ce609c.SoulMadeMain.NFT","A.9a57dfe5c8ce609c.SoulMadePack.NFT"]`,
		// "Bitku":    `["A.f61e40c19db2a9e2.HaikuNFT.NFT"]`,
		// "Dandy": `["A.097bafa4e0b48eef.Dandy.NFT"]`,
		// "bl0xPack": `["A.7620acf6d7f2468a.Bl0xPack.NFT"]`,
		// "TheKrikeySolarpupsCollection": `["A.a8d493db1bb4df56.SolarpupsNFT.NFT"]`,
		// "DisruptArt":                   `["A.cd946ef9b13804c6.DisruptArt.NFT"]`,
		// "SequelDigitalArt":             `["A.3cb7ceeb625a600a.DigitalArt.NFT"]`,
		// "Yahoo":                        `["A.758252ab932a3416.YahooPartnersCollectible.NFT", "A.758252ab932a3416.YahooCollectible.NFT"]`,
		// "MonoCats":                     `["A.8529aaf64c168952.MonoCat.NFT", "A.8529aaf64c168952.MonoCatMysteryBox.NFT"]`,
		// "YBees":                        `["A.20187093790b9aef.YBees.NFT"]`,
		// "RCRDSHP":                      `["A.6c3ff40b90b928ab.RCRDSHPNFT.NFT"]`,
		// "CryptoPiggoNFTCollection":     `["A.d3df824bf81910a4.CryptoPiggo.NFT"]`,
		// "FlowverseSocks":               `["A.ce4c02539d1fabe8.FlowverseSocks.NFT"]`,
		// "Zeedz":                        `["A.62b3063fbe672fc8.ZeedzINO.NFT"]`,
		// "PartyFavorz": `["A.123cb666996b8432.PartyFavorz.NFT"]`,
		// "xG":     `["A.c357c8d061353f5f.XGStudio.NFT"]`,
		// "digiYo": `["A.ae3baa0d314e546b.Digiyo.NFT"]`,
		//"flovatar":             `["A.921ea449dffec68a.Flovatar.NFT" , "A.921ea449dffec68a.FlovatarComponent.NFT", "A.921ea449dffec68a.Flobot.NFT"]`,
		//"Emeralds":             `["A.5643fd47a29770e7.Emeralds.NFT"]`,
		//"FridgeMagnet":         `["A.4e7213d003a3a38a.FridgeMagnet.NFT"]`,
		"FlowverseMysteryPass":    `["A.9212a87501a8a6a2.FlowversePass.NFT"]`,
		"AsobaNFTCollection":      `["A.9eafd89fa6abb1d3.Asoba.NFT"]`,
		"IceTraeDiamondHands":     `["A.bb39f0dae1547256.IceTraeDiamondHands.NFT"]`,
		"TouchstoneManekiPlanets": `["A.cf3c77ef638573e8.TouchstoneManekiPlanets.NFT"]`,
		"ChainmonstersRewards":    `["A.93615d25d14fa337.ChainmonstersRewards.NFT"]`,
		"TheFootballClub":         `["A.81e95660ab5308e1.TFCItems.NFT"]`,

		// Delisted
	}

	for name, contracts := range flowNfts {
		upsertItem(
			WithArg("nftName", name), //primary key
			WithArg("nftTypes", contracts),
		)
	}

	delistItem := o.TxFileNameFN("adminMainnetRemoveItem",
		adminSigner,
		WithArg("tenant", "find"),
		WithArg("ftName", "flow"),
		WithArg("listingName", "escrow"),
	)

	delist := []string{
		"FlowverseMysteryPass",
	}

	for _, name := range delist {
		delistItem(
			WithArg("nftName", name),
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
