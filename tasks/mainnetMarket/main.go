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

	// Items added to Dapper will also be added to non-Dapper tenant.
	// While removing, if you would like to remove from both tenants, you have to do it explicitly in both delist maps

	// Non-Dapper Tenant Items to be listed
	flowNfts := map[string]string{
		// "SoulMade": `["A.9a57dfe5c8ce609c.SoulMadeComponent.NFT", "A.9a57dfe5c8ce609c.SoulMadeMain.NFT","A.9a57dfe5c8ce609c.SoulMadePack.NFT"]`,
		// "Bitku":    `["A.f61e40c19db2a9e2.HaikuNFT.NFT"]`,
		// "Dandy": `["A.097bafa4e0b48eef.Dandy.NFT"]`,
		// "some.place": `["A.667a16294a089ef8.SomePlaceCollectible.NFT"]`,
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
		//"FlowverseMysteryPass": `["A.9212a87501a8a6a2.FlowversePass.NFT"]`,
		//"AsobaNFTCollection":      `["A.9eafd89fa6abb1d3.Asoba.NFT"]`,
		//"IceTraeDiamondHands":     `["A.bb39f0dae1547256.IceTraeDiamondHands.NFT"]`,
		//"TouchstoneManekiPlanets": `["A.cf3c77ef638573e8.TouchstoneManekiPlanets.NFT"]`,
		//"ChainmonstersRewards":    `["A.93615d25d14fa337.ChainmonstersRewards.NFT"]`,
		//"TheFootballClub":         `["A.81e95660ab5308e1.TFCItems.NFT"]`,
		//"PartyMansion": `["A.34f2bf4a80bb0f69.PartyMansionDrinksContract.NFT", "A.34f2bf4a80bb0f69.GooberXContract.NFT"]`,
		// "YoungBoysBern": `["A.20187093790b9aef.YoungBoysBern.NFT"]`,
		// "PharaohCats":   `["A.9d21537544d9123d.Momentables.NFT"]`,
		// "DalleOnFlow":   `["A.58d08685febcfea5.DalleOnFlow.NFT"]`,

		// Delisted
		"DooverseItems":                    "[`A.66ad29c7d7465437.DooverseItems.NFT`]",
		"FlowverseTreasures":               "[`A.9212a87501a8a6a2.FlowverseTreasures.NFT`]",
		"Hoodlums":                         "[`A.427ceada271aa0b1.SturdyItems.NFT`]",
		"SportsIconCollection":             "[`A.8de96244f54db422.SportsIconCollectible.NFT`]",
		"SturdyExchange":                   "[`A.427ceada271aa0b1.SturdyTokens.NFT`]",
		"TheNFTDayTreasureChestCollection": "[`A.117396d8a72ad372.NFTDayTreasureChest.NFT`]",
		"TouchstoneFLOWFREAKS":             "[`A.cf0c62932f6ff1eb.TouchstoneFLOWFREAKS.NFT`]",
		"TouchstoneTheGritIron":            "[`A.84e5586a3fae8ff3.TouchstoneTheGritIron.NFT`]",
		"Trart":                            "[`A.6f01a4b0046c1f87.TrartContractNFT.NFT`]",
		"schmoes_prelaunch_token":          "[`A.6c4fe48768523577.SchmoesPreLaunchToken.NFT`]",
	}

	// Non-Dapper Tenant Items to be DElisted
	delist := []string{
		//"FlowverseMysteryPass",
		// "Flunks",
	}

	// Dapper Tenant Items to be listed
	dapperNFTs := map[string]string{
		"Flunks":     `["A.807c3d470888cc48.Flunks.NFT"]`,
		"NBATopShot": `["A.0b2a3299cc857e29.TopShot.NFT"]`,
		// "Aera":                                  "[`A.30cf5dcf6ea8d379.AeraNFT.NFT`]",
		// "AeraRewards":                           "[`A.30cf5dcf6ea8d379.AeraRewards.NFT`]",
		"Analogs":                               "[`A.427ceada271aa0b1.Analogs.NFT`]",
		"Backpack":                              "[`A.807c3d470888cc48.Backpack.NFT`]",
		"BarterYardClub_Werewolves":             "[`A.28abb9f291cadaf2.BarterYardClubWerewolf.NFT`]",
		"Bobblz":                                "[`A.d45e2bd9a3d5003b.Bobblz_NFT.NFT`]",
		"CanesVault":                            "[`A.329feb3ab062d289.Canes_Vault_NFT.NFT`]",
		"CryptoPiggoV2NFTCollection":            "[`A.d3df824bf81910a4.CryptoPiggoV2.NFT`]",
		"Driverz":                               "[`A.a039bd7d55a96c0c.DriverzNFT.NFT`]",
		"Eternal":                               "[`A.c38aea683c0c4d38.Eternal.NFT`]",
		"Fuchibola":                             "[`A.f3ee684cd0259fed.Fuchibola_NFT.NFT`]",
		"GaiaElementNFT":                        "[`A.ebfaf4d2d7920a18.GaiaElementNFT.NFT`]",
		"GaiaPackNFT":                           "[`A.fdae91e14e960079.GaiaPackNFT.NFT`]",
		"Gamisodes":                             "[`A.09e04bdbcccde6ca.Gamisodes.NFT`]",
		"Genies":                                "[`A.12450e4bb3b7666e.Genies.NFT`]",
		"InceptionAvatar":                       "[`A.83ed64a1d4f3833f.InceptionAvatar.NFT`]",
		"InceptionBlackBox":                     "[`A.83ed64a1d4f3833f.InceptionBlackBox.NFT`]",
		"JollyJokers":                           "[`A.699bf284101a76f1.JollyJokers.NFT`]",
		"JukeFrames":                            "[`A.e23c123e8c93c9eb.Frames.NFT`]",
		"JukeReels":                             "[`A.e23c123e8c93c9eb.Reels.NFT`]",
		"LaligaGolazos":                         "[`A.87ca73a41bb50ad5.Golazos.NFT`]",
		"MFLClubs":                              "[`A.8ebcbfd516b1da27.MFLClub.NFT`]",
		"MFLPacks":                              "[`A.8ebcbfd516b1da27.MFLPack.NFT`]",
		"MFLPlayers":                            "[`A.8ebcbfd516b1da27.MFLPlayer.NFT`]",
		"MetaPanda":                             "[`A.f2af175e411dfff8.MetaPanda.NFT`]",
		"MintStoreItem":                         "[`A.20187093790b9aef.MintStoreItem.NFT`]",
		"NBATopShotInArena":                     "[`A.27ece19eff91bab0.NBATopShotArena.NFT`]",
		"NFLAllDayPacks":                        "[`A.e4cf4bdc1751c65d.PackNFT.NFT`]",
		"NextName":                              "[`A.15b236723f4b88ee.NextName.NFT`]",
		"NiftoryDapperMainnet":                  "[`A.adf8dcc78920950d.NiftoryDapperMainnet.NFT`]",
		"OneShotsComicBookTradingCardsbyTibles": "[`A.4f7ff543c936072b.OneShots.NFT`]",
		"PiratesOfTheMetaverse":                 "[`A.f5fc2c119a988722.PiratesOfTheMetaverse.NFT`]",
		"PuddleV1":                              "[`A.9496a99be6bceb8c.PuddleV1.NFT`]",
		"RTLStoreItem":                          "[`A.9d1d0d0c82bf1c59.RTLStoreItem.NFT`]",
		"RaceDayNFT":                            "[`A.329feb3ab062d289.RaceDay_NFT.NFT`]",
		"RaptaIconCollection":                   "[`A.c8eb8906f29b7a9c.RaptaIcon.NFT`]",
		"SNKRHUDNFT":                            "[`A.80af1db15aa6535a.SNKRHUDNFT.NFT`]",
		"SeedsOfHappinessGenesis":               "[`A.52acb3b399df11fc.SeedsOfHappinessGenesis.NFT`]",
		"SeussiblesNFTCollectionbyTibles":       "[`A.321d8fcde05f6e8c.Seussibles.NFT`]",
		"StoreFrontTR":                          "[`A.766b859539a6679b.StoreFront.NFT`]",
		"SwaychainToknd":                        "[`A.936bdcb98fe497ef.SwaychainToknd.NFT`]",
		"TheCryptoPiggoPotionCollection":        "[`A.d3df824bf81910a4.CryptoPiggoPotion.NFT`]",
		"TheKeeprCollection":                    "[`A.5eb12ad3d5a99945.KeeprItems.NFT`]",
		"ThePlayersLounge":                      "[`A.329feb3ab062d289.DGD_NFT.NFT`]",
		"ThePublishedNFTCollection":             "[`A.52cbea4e6f616b8e.PublishedNFT.NFT`]",
		"TicalUniverse":                         "[`A.fef48806337aabf1.TicalUniverse.NFT`]",
		"TokndSwaychain":                        "[`A.6e4f1e2abdb23c78.TokndSwaychain.NFT`]",
		"TuneGONFT":                             "[`A.c6945445cdbefec9.TuneGONFT.NFT`]",
		"TuneKitties":                           "[`A.0d9bc5af3fc0c2e3.TuneGO.NFT`]",
		"UFCStrike":                             "[`A.329feb3ab062d289.UFC_NFT.NFT`]",
		"XvsXNFTCollection":                     "[`A.f2af175e411dfff8.XvsX.NFT`]",
	}

	// Dapper Tenant Items to be DElisted
	delistDapper := []string{
		// "Flunks",
	}

	upsertItem := o.TxFileNameFN("adminMainnetAddItem",
		adminSigner,
		WithArg("tenant", "find"),
		WithArg("ftName", "flow"),
		WithArg("ftTypes", `["A.1654653399040a61.FlowToken.Vault"]`),
		WithArg("listingName", "escrow"),
		WithArg("listingTypes", `["A.097bafa4e0b48eef.FindMarketSale.SaleItem" , "A.097bafa4e0b48eef.FindMarketAuctionEscrow.SaleItem" , "A.097bafa4e0b48eef.FindMarketDirectOfferEscrow.SaleItem"]`),
	)

	upsertDapperItem := o.TxFileNameFN("adminMainnetAddItem",
		adminSigner,
		WithArg("tenant", "find-dapper"),
		WithArg("ftName", "dapper"),
		WithArg("ftTypes", `["A.ead892083b3e2c6c.FlowUtilityToken.Vault" , "A.ead892083b3e2c6c.DapperUtilityCoin.Vault"]`),
		WithArg("listingName", "soft"),
		WithArg("listingTypes", `["A.097bafa4e0b48eef.FindMarketSale.SaleItem"]`),
	)

	for name, contracts := range flowNfts {
		upsertItem(
			WithArg("nftName", name), //primary key
			WithArg("nftTypes", contracts),
		)
	}

	for name, contracts := range dapperNFTs {
		upsertDapperItem(
			WithArg("nftName", name), //primary key
			WithArg("nftTypes", contracts),
		)

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

	for _, name := range delist {
		delistItem(
			WithArg("nftName", name),
		)
	}

	delistDapperItem := o.TxFileNameFN("adminMainnetRemoveItem",
		adminSigner,
		WithArg("tenant", "find-dapper"),
		WithArg("ftName", "dapper"),
		WithArg("listingName", "soft"),
	)

	for _, name := range delistDapper {
		delistDapperItem(
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
