import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"


pub struct Report{
	pub let alias:String
	pub let ids:[UInt64]
	pub let key:String
	pub let address:Address
	pub let resolver:String
	pub let source:String
	pub let community:String?
	pub let project:String

	init(alias: String,ids:[UInt64], key:String, address:Address, resolver:String, source: String, community: String?, project: String) {
		self.alias=alias
		self.ids=ids
		self.key=key
		self.address=address
		self.resolver=resolver
		self.source=source
		self.community=community
		self.project=project
	}
}

pub fun main(address: Address, targetPaths: [String]): {String : Report}{

	let resolvers = {
	"CricketMomentsCollection" : 1,
	"KlktnNFTCollection": 1,
	"KlktnNFT2Collection": 1,
	"MatrixWorldFlowFestNFTCollection": 1,
	"MynftCollection": 1,
	"EternalShardCollection": 1,
	"jambbLaunchVouchersCollection" : 1,
	"BarterYardPackNFTCollection" : 2,
	"bloctoXtinglesCollectibleCollection" : 2,
	"CryptoZooCollection": 2,
	"DieselCollection004" : 2,
	"FlowChinaBadgeCollection" : 2,
	"GeniaceNFTCollection" : 2,
	"MiamiCollection004" : 2,
	"FabricantCollection004" : 2,
	"ARTIFACTCollection" : 3,
	"ARTIFACTPackCollection" : 3,
	"BlindBoxRedeemVoucherCollection" : 3,
	"GogoroCollectibleCollection":3,
	"MatrixWorldAssetNFTCollection" : 3,
	"metaverseCollection" : 3,
	"nftRealityCollection" : 3,
	"NowggNFTsCollection" : 3,
	"AADigitalNFTCollection" : 4,
	"f4264ac8f3256818_Evolution_Collection" : 4,
	"MaxarNFTCollection" : 4,
	"jambbMomentsCollection" : 4,
	"motogpCardCollection" : 4,
	"TroonCollection" : 4,
	"S2ItemCollection0028" : 4,
	"BNVnMissNFTCollection006" : 4
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

				// try to use the key from alchemy as alias
				var alias = key
				// if the item is not in alchemy, then we know it should have NFTCollection, we tries to use the collection display name for alias
				// if not, it has to be the path
				if alias == nil {
					if let nft = collection.borrowNFT(id: ids[0]).resolveView(Type<MetadataViews.NFTCollectionDisplay>()) {
						if let v = nft as? MetadataViews.NFTCollectionDisplay {
							alias = v.name
						}
					} else {
						continue
					}
				}

				// if the item is not in either, we just try our best to give a good collection information
				if alias == nil {
					var pIden = p
					let col = "Collection"
					if pIden.length > col.length {
						let pslice = pIden.slice(from: (pIden.length - col.length) , upTo: pIden.length)
						if pslice == col {
							pIden = pIden.slice(from: 0 , upTo: (pIden.length - col.length))
						}
					}
					alias = pIden
				}

				report[p]=Report(
					alias: alias!,
					ids:ids,
					key:key ?? p,
					address:address,
					resolver:getAlchemyItem(resolver) ?? "getNFTItems",
					source: getAlchemyDetail(resolver) ?? "getNFTDetails",
					community: resolver!=nil ? nil : "getNFTDetailsCommunity",
					project: getProject(key) ?? p
				)

			}
		}
	}
	return report
}

pub fun getAlchemyItem(_ shard: Int?) : String? {
	if shard == nil {
		return nil
	}
	return "getAlchemy".concat(shard!.toString()).concat("Items")
}

pub fun getAlchemyDetail(_ shard: Int?) : String? {
		if shard == nil {
		return nil
	}
	return "getNFTDetailsShard".concat(shard!.toString())
}

pub fun getProject(_ shard: String?) : String? {

	if shard == "BarterYardPackNFT" {
		return "BarterYardPack"
	}
	return shard
}
