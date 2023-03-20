import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"


pub struct Report{
	pub let ids:[UInt64]
	pub let key:String
	pub let address:Address
	pub let resolver:String

	init(ids:[UInt64], key:String, address:Address, resolver:String) {
		self.ids=ids
		self.key=key
		self.address=address
		self.resolver=resolver

	}
}

pub fun main(address: Address, targetPaths: [String]): {String : Report}{


	let resolvers = {
	"CricketMomentsCollection" : "getAlchemy1Items",
	"KlktnNFTCollection": "getAlchemy1Items",
	"KlktnNFT2Collection": "getAlchemy1Items",
	"MatrixWorldFlowFestNFTCollection": "getAlchemy1Items",
	"MynftCollection": "getAlchemy1Items",
	"EternalShardCollection": "getAlchemy1Items",
	"jambbLaunchVouchersCollection" : "getAlchemy1Items",
	"BarterYardPackNFTCollection" : "getAlchemy2Items",
	"bloctoXtinglesCollectibleCollection" : "getAlchemy2Items",
	"CryptoZooCollection": "getAlchemy2Items",
	"DieselCollection004" : "getAlchemy2Items",
	"FlowChinaBadgeCollection" : "getAlchemy2Items", 
	"GeniaceNFTCollection" : "getAlchemy2Items", 
	"MiamiCollection004" : "getAlchemy2Items", 
	"FabricantCollection004" : "getAlchemy2Items",
	"ARTIFACTCollection" : "getAlchemy3Items",
	"ARTIFACTPackCollection" : "getAlchemy3Items",
	"BlindBoxRedeemVoucherCollection" : "getAlchemy3Items",
	"GogoroCollectibleCollection":"getAlchemy3Items",
	"MatrixWorldAssetNFTCollection" : "getAlchemy3Items",
	"metaverseCollection" : "getAlchemy3Items", 
	"nftRealityCollection" : "getAlchemy3Items",
	"NowggNFTsCollection" : "getAlchemy3Items",
	"AADigitalNFTCollection" : "getAlchemy4Items",
	"f4264ac8f3256818_Evolution_Collection" : "getAlchemy4Items",
	"MaxarNFTCollection" : "getAlchemy4Items", 
	"jambbMomentsCollection" : "getAlchemy4Items",
	"motogpCardCollection" : "getAlchemy4Items",
	"TroonCollection" : "getAlchemy4Items",
	"S2ItemCollection0028" : "getAlchemy4Items",
	"BNVnMissNFTCollection006" : "getAlchemy4Items"
}


	let keys = {
	"CricketMomentsCollection" : "CricketMoments",
	"KlktnNFTCollection": "KlktnNFT",
	"KlktnNFT2Collection": "KlktnNFT2",
	"MatrixWorldFlowFestNFTCollection": "MatrixWorldFlowFestNFT",
	"MynftCollection": "Mynft",
	"EternalShardCollection": "EternalShard",
	"jambbLaunchVouchersCollection" : "Vouchers",
	"BarterYardPackNFTCollection" : "BarterYardPackNFT",
	"bloctoXtinglesCollectibleCollection" : "Xtingles",
	"CryptoZooCollection": "InceptionAnimals",
	"DieselCollection004" : "DieselNFT",
	"FlowChinaBadgeCollection" : "FlowFans", 
	"GeniaceNFTCollection" : "GeniaceNFT", 
	"MiamiCollection004" : "MiamiNFT", 
	"FabricantCollection004" : "TheFabricantMysteryBox_FF1",
	"ARTIFACTCollection" : "ARTIFACT",
	"ARTIFACTPackCollection" : "ARTIFACTPack",
	"BlindBoxRedeemVoucherCollection" : "BlindBoxRedeemVoucher",
	"GogoroCollectibleCollection":"GogoroCollectible",
	"MatrixWorldAssetNFTCollection" : "MatrixWorldAssetsNFT",
	"metaverseCollection" : "Metaverse", 
	"nftRealityCollection" : "NftReality",
	"NowggNFTsCollection" : "NowggNFT",
	"AADigitalNFTCollection" : "AvatarArt",
	"f4264ac8f3256818_Evolution_Collection" : "Evolution",
	"MaxarNFTCollection" : "Maxar", 
	"jambbMomentsCollection" : "Moments",
	"motogpCardCollection" : "MotoGPCard",
	"TroonCollection" : "NFTContract",
	"S2ItemCollection0028" : "TheFabricantS2ItemNFT",
	"BNVnMissNFTCollection006" : "VnMiss"
}

	let report : {String:Report}={}
	let account=getAuthAccount(address)
	for p in targetPaths {
		let storagePath = StoragePath(identifier:p)!
		var type = account.type(at: storagePath)!
		if type.isSubtype(of: Type<@NonFungibleToken.Collection>()) {
			let collection = account.borrow<&NonFungibleToken.Collection>(from: storagePath)!
			let ids = collection.getIDs()
			if ids.length > 0{

				let resolver = resolvers[p]
				let key = keys[p]


				report[p]=Report(
					ids:ids,
					key:key ?? p,
					address:address,
					resolver:resolver ?? "getNFTItems")

			}
		}
	}
	return report
}
