import FindPack from "../contracts/FindPack.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

pub fun main(packTypeName: String, packTypeId: UInt64) : Report? {
	if let metadata = FindPack.getMetadataById(packTypeName: packTypeName, typeId: packTypeId) {
		let packsLeft = FindPack.getPacksCollection(packTypeName: packTypeName, packTypeId: packTypeId).getPacksLeft()
		return Report(metadata, packsLeft: packsLeft)
	}
	return nil
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
			self.saleEnded=false
			if self.packsLeft == 0 {
				self.saleEnded=true
			} else {
				let currentTime = getCurrentBlock().timestamp
				for saleInfo in self.saleInfos{
					if saleInfo.endTime == nil || saleInfo.endTime! > currentTime {
						self.saleEnded=true
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

pub fun convertSaleInfo(_ info: [FindPack.SaleInfo]) : [SaleInfo] {
	let res : [SaleInfo] = []
	for i in info {
		res.append(SaleInfo(i))
	}
	return res
}