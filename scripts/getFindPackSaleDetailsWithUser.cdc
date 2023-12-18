import FindPack from "../contracts/FindPack.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FlowStorageFees from "../contracts/standard/FlowStorageFees.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(packTypeName: String, packTypeId: UInt64, user: Address) : Report? {
	if let metadata = FindPack.getMetadataById(packTypeName: packTypeName, typeId: packTypeId) {
		let packsLeft = FindPack.getPacksCollection(packTypeName: packTypeName, packTypeId: packTypeId).getPacksLeft()
		return Report(metadata, user: user, packsLeft:packsLeft)
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

		pub let storageRequirement: UInt64
		pub let collectionDisplay: MetadataViews.NFTCollectionDisplay

		pub let itemTypes: [Type]

		pub let extraData : {String : AnyStruct}
		pub let packFields: {String : String}
		pub let requiresReservation: Bool
		pub let storageFlowNeeded: UFix64? 

		pub let userQualifiedSale : UserSaleInfo?
		pub let saleInfos: [SaleInfo]
		pub let packsLeft : Int 

		init(_ md: FindPack.Metadata, user: Address, packsLeft: Int) {
			self.packsLeft=packsLeft
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
			self.userQualifiedSale=getSoonestQualifiedSale(md.saleInfos, user: user)
			self.storageFlowNeeded=getRequiredFlow(md.storageRequirement, user: user)
			self.collectionDisplay=md.collectionDisplay
			self.saleInfos=convertSaleInfo(md.saleInfos)
		}
}

pub struct UserSaleInfo {
		pub let name : String
		pub let startTime : UFix64 
		pub let endTime : UFix64?
		pub let price : UFix64
		pub let purchaseLimit : UInt64?
		pub let userPurchaseRecord : UInt64
		pub let canBuyNow : Bool

		init(_ si: FindPack.SaleInfo, user: Address, timeStamp: UFix64) {
			self.name=si.name
			self.startTime=si.startTime
			self.endTime=si.endTime
			self.price=si.price
			self.purchaseLimit=si.purchaseLimit
			self.userPurchaseRecord=si.purchaseRecord[user] ?? 0
			self.canBuyNow= si.startTime<=timeStamp
		}
}

pub fun getSoonestQualifiedSale(_ infos: [FindPack.SaleInfo], user: Address) : UserSaleInfo? {
	let res : [UserSaleInfo] = []
	let currentTime = getCurrentBlock().timestamp
	var availableOption : FindPack.SaleInfo? = nil 
	var soonestOption : FindPack.SaleInfo? = nil 

	// check for the sale option that is available to the user, and is with the lowest price
	for info in infos {
		if info.checkBuyable(addr: user, time: currentTime){
			if availableOption == nil || availableOption!.price > info!.price {
				availableOption = info
			}
		} else {
			let endTime = info.endTime ?? UFix64.max
			if currentTime > endTime {
				continue
			}

	// if there is no option available, get the soonest option available to the user, again, lowest price
			if info.checkBuyable(addr: user, time: info.startTime) {
				if soonestOption == nil || soonestOption!.startTime > info.startTime {
					soonestOption = info
				} else if soonestOption!.startTime == info.startTime && soonestOption!.price > info.price {
					soonestOption = info
				}
			}
		}
	}

	if availableOption != nil {
		return UserSaleInfo(availableOption!, user: user, timeStamp: currentTime)
	} else if soonestOption != nil {
		return UserSaleInfo(soonestOption!, user: user, timeStamp: currentTime)
	}
	return nil
}

pub fun getRequiredFlow(_ requiresReservation: UInt64, user: Address) : UFix64? {

	let account = getAccount(user)
	if account.storageCapacity > account.storageUsed {
		if account.storageCapacity - account.storageUsed > requiresReservation {
			return nil
		}
	}
	return FlowStorageFees.storageCapacityToFlow(FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(account.storageUsed + requiresReservation))
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