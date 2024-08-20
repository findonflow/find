import "FindPack"
import "FTRegistry"
import "MetadataViews"

access(all) fun main(packTypeName: String) : {UInt64 : Report} {
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

access(all) struct Report {
		access(all) let name: String
		access(all) let description: String

		access(all) let thumbnailHash: String?
		access(all) let thumbnailUrl:String?

		access(all) let walletType: String
		access(all) let walletAlias: String?

		access(all) let openTime: UFix64
		access(all) var saleEnded: Bool
		access(all) let saleInfos: [SaleInfo]

		access(all) let storageRequirement: UInt64
		access(all) let collectionDisplay: MetadataViews.NFTCollectionDisplay

		access(all) let itemTypes: [Type]

		access(all) let extraData : {String : AnyStruct}
		access(all) let packFields: {String : String}
		access(all) let requiresReservation: Bool

		access(all) let packsLeft : Int 

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

access(all) struct SaleInfo {
		access(all) let name : String
		access(all) let startTime : UFix64 
		access(all) let endTime : UFix64?
		access(all) let price : UFix64
		access(all) let purchaseLimit : UInt64?
		access(all) let purchaseRecord : {Address : UInt64}
		access(all) let verifiers : [String]
		access(all) let verifyAll : Bool 

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
