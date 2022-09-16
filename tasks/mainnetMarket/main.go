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
			WithSigner("find"),
			WithArg("collectionIdentifier", "A.9a57dfe5c8ce609c.SoulMadeComponent"),
		)

		o.Tx("adminAddNFTCatalog",
			WithSigner("find"),
			WithArg("collectionIdentifier", "SoulMadeComponent"),
			WithArg("contractName", "SoulMadeComponent"),
			WithArg("contractAddress", "0x9a57dfe5c8ce609c"),
			WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
			WithArg("nftID", 33029),
			WithArg("publicPathIdentifier", "SoulMadeComponentCollection"),
		)
			o.Tx("adminAddNFTCatalog",
				WithSigner("find"),
				WithArg("collectionIdentifier", "SoulMade"),
				WithArg("contractName", "SoulMadeMain"),
				WithArg("contractAddress", "0x9a57dfe5c8ce609c"),
				WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
				WithArg("nftID", 7352),
				WithArg("publicPathIdentifier", "SoulMadeMainCollection"),
			)

			o.Tx("adminAddNFTCatalog",
				WithSigner("find"),
				WithArg("collectionIdentifier", "SoulMadeComponent"),
				WithArg("contractName", "SoulMadeComponent"),
				WithArg("contractAddress", "0x9a57dfe5c8ce609c"),
				WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
				WithArg("nftID", 33029),
				WithArg("publicPathIdentifier", "SoulMadeComponentCollection"),
			)

			o.Tx("adminAddNFTCatalog",
				WithSigner("find"),
				WithArg("collectionIdentifier", "Bitku"),
				WithArg("contractName", "HaikuNFT"),
				WithArg("contractAddress", "0xf61e40c19db2a9e2"),
				WithArg("addressWithNFT", "0x92ba5cba77fc1e87"),
				WithArg("nftID", 225),
				WithArg("publicPathIdentifier", "BitkuCollection"),
			)

			o.Tx("adminAddNFTCatalog",
				WithSigner("find"),
				WithArg("collectionIdentifier", "some.place"),
				WithArg("contractName", "SomePlaceCollectible"),
				WithArg("contractAddress", "0x667a16294a089ef"),
				WithArg("addressWithNFT", "0x886f3aeaf848c535"),
				WithArg("nftID", 164769803),
				WithArg("publicPathIdentifier", "somePlaceCollectibleCollection"),
			)

			o.Tx("adminAddNFTCatalog",
				WithSigner("find"),
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
		//	"SoulMade": `["A.9a57dfe5c8ce609c.SoulMadeComponent.NFT", "A.9a57dfe5c8ce609c.SoulMadeMain.NFT"]`,
		//	"Bitku":    `["A.f61e40c19db2a9e2.HaikuNFT.NFT"]`,
		//		"Dandy": `["A.097bafa4e0b48eef.Dandy.NFT"]`,
		// "some.place": `["A.667a16294a089ef8.SomePlaceCollectible.NFT"]`,
		// "bl0xPack": `["A.7620acf6d7f2468a.Bl0xPack.NFT"]`,
		"bl0xPack": `["A.7620acf6d7f2468a.Bl0xPack.NFT"]`,
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
