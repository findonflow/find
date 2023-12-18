import FindPack from "../contracts/FindPack.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

access(all) main(packTypeName: String) : {UInt64 : Report} {
	let packs = FindPack.getMetadataByName(packTypeName: packTypeName)
	let packData : {UInt64 : Report} = {}
	for packTypeId in packs.keys {
		if let metadata = FindPack.getMetadataById(packTypeName: packTypeName, typeId: packTypeId) {
			let packsLeft = FindPack.getPacksCollection(packTypeName: packTypeName, packTypeId: packTypeId).getPacksLeft()
			packData[packTypeId] = Report(metadata, packsLeft: packsLeft)
		}
	}
	return packData
}

pub struct Report {
		pub let name: String
		pub let description: String

		pub let thumbnailHash: String?
		pub let thumbnailUrl:String?

		pub let walletType: String
		pub let walletAlias: String?

		pub let openTime: UFix64
		pub var saleEnded: Bool
		pub let saleInfos: [SaleInfo]

		pub let storageRequirement: UInt64
		pub let collectionDisplay: MetadataViews.NFTCollectionDisplay

		pub let itemTypes: [Type]

		pub let extraData : {String : AnyStruct}
		pub let packFields: {String : String}
		pub let requiresReservation: Bool

		pub let packsLeft : Int 

		init(_ md: FindPack.Metadata, packsLeft: Int) {
			self.packsLeft = packsLeft
			self.name=md.name
			self.description=md.description
			self.thumbnailHash=md.thumbnailHash
			self.thumbnailUrl=md.thumbnailUrl
			self.walletType=md.walletType.identifier
			self.walletAlias=FTRegistry.getFTInfoByTypeIdentifier(md.walletType.identifier)?.alias
			self.openTime=md.openTime
			self.storageRequirement=md.storageRequirement
			self.itemTypes=md.itemTypes
			self.extraData=md.extraData
			self.packFields=md.packFields
			self.requiresReservation=md.requiresReservation
			self.saleInfos=convertSaleInfo(md.saleInfos)
			self.collectionDisplay=md.collectionDisplay
			self.saleEnded=true
			if self.packsLeft != 0 {
				self.saleEnded=false
			} else {
				let currentTime = getCurrentBlock().timestamp
				var saleEnded = true
				for saleInfo in self.saleInfos{
					if saleInfo.endTime == nil || saleInfo.endTime! > currentTime {
						saleEnded=true
						break
					}
				}
			}
		}
}

pub struct SaleInfo {
		pub let name : String
		pub let startTime : UFix64 
		pub let endTime : UFix64?
		pub let price : UFix64
		pub let purchaseLimit : UInt64?
		pub let purchaseRecord : {Address : UInt64}
		pub let verifiers : [String]
		pub let verifyAll : Bool 

		init(_ si: FindPack.SaleInfo) {
			self.name=si.name
			self.startTime=si.startTime
			self.endTime=si.endTime
			self.price=si.price
			self.purchaseLimit=si.purchaseLimit
			self.purchaseRecord=si.purchaseRecord

			var verifierDesc : [String] = []
			for verifier in si.verifiers {
				verifierDesc.append(verifier.description)
			}
			self.verifiers=verifierDesc
			self.verifyAll=si.verifyAll
		}
}

access(all) convertSaleInfo(_ info: [FindPack.SaleInfo]) : [SaleInfo] {
	let res : [SaleInfo] = []
	for i in info {
		res.append(SaleInfo(i))
	}
	return res
}