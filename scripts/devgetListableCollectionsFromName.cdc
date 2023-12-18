import NFTCatalog from 0x49a7cda3a1eecc29
import FindMarket from 0x097bafa4e0b48eef
import FindMarketSale from 0x097bafa4e0b48eef

access(all) main():AnyStruct {
	let r : {String : String} = {}

	let tenant = "Dapper"

	let list : [String] = [
"Analogs",
"Bobblz",
"SNKRHUDNFT",
"UFCStrike",
"Flunks",
"MFLPacks",
"MFLClubs",
"MetaPanda",
// "DimensionX",
"Driverz",
"Backpack",
"Gamisodes",
"Genies",
"GaiaPackNFT",
"GaiaElementNFT",
"LaligaGolazos",
"MFLPlayers",
"TicalUniverse",
"TuneKitties",
"RaptaIconCollection",
"RaceDayNFT",
"InceptionBlackBox",
"InceptionAvatar",
"JollyJokers",
"TheCryptoPiggoPotionCollection",
"CryptoPiggoV2NFTCollection",
"ThePublishedNFTCollection",
"XvsXNFTCollection",
"SeedsOfHappinessGenesis",
"TheCryptoPiggoPotionCollection",
"Aera",
"AeraRewards",
// "Footballer'sJourneyPanel",
"NextName",
"SwaychainToknd",
"NBATopShot",
"TokndSwaychain",
"NBATopShotInArena",
"CanesVault",
"PiratesOfTheMetaverse",
"Eternal",
"StoreFrontTR",
"ThePlayersLounge",
"JukeFrames",
"Fuchibola",
"NFLAllDayPacks",
"Wearables",
"TuneGONFT",
"PuddleV1",
"SeussiblesNFTCollectionbyTibles",
"RTLStoreItem",
"NiftoryDapperMainnet",
"MintStoreItem",
"TheKeeprCollection",
"BarterYardClub_Werewolves",
"JukeReels",
"OneShotsComicBookTradingCardsbyTibles"
	]

	var tenantAddr = FindMarket.getFindTenantAddress()
	if tenant == "Dapper" {
		tenantAddr = FindMarket.getTenantAddress("find")!
	}
	let tenantRef = FindMarket.getTenant(tenantAddr)

	for l in list {
		let nftType = NFTCatalog.getCatalogEntry(collectionIdentifier : l)?.nftType ?? panic(l)
		if tenantRef.getAllowedListings(nftType: nftType, marketType: Type<@FindMarketSale.SaleItem>()) == nil {
			r[l] = "[`".concat(NFTCatalog.getCatalogEntry(collectionIdentifier : l)!.nftType.identifier).concat("`]")
		}

	}

	return r
}
