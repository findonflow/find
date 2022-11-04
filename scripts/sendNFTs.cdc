import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindAirdropper from "../contracts/FindAirdropper.cdc"

pub fun main(sender: Address, receivers:[String], types: [String] , ids: [UInt64], messages: [String]) : [Report] {

 	fun logErr(_ i: Int , err: String) : Report {
		return Report(receiver: receivers[i] , type: types[i], id: ids[i] , message: messages[i] ,receiverLinked: nil , collectionPublicLinked: nil , accountInitialized: nil , nftInPlace: nil, err: err)
	}

		let paths : [PublicPath] = []
		let contractData : {Type : NFTCatalog.NFTCatalogMetadata} = {}
		let addresses : {String : Address} = {} 
		let ownedIds : {Type : [UInt64]} = {}

		let account = getAuthAccount(sender)
		let report : [Report] = []
		for i , typeIdentifier in types {
			let checkType = CompositeType(typeIdentifier) 
			if checkType == nil {
				report.append(logErr(i, err: "Cannot refer to type with identifier : ".concat(typeIdentifier)))
				continue
			}
			let type = checkType!

			var data : NFTCatalog.NFTCatalogMetadata? = contractData[type]
			if data == nil {
				let checkData = FINDNFTCatalog.getMetadataFromType(type) 
				if checkData == nil {
					report.append(logErr(i, err: "NFT Type is not supported by NFT Catalog. Type : ".concat(type.identifier)))
					continue
				}
				contractData[type] = checkData!
				data = checkData!
			}

			let path = data!.collectionData

			var owned = false
			if ownedIds[type] == nil {
				let checkCol = account.borrow<&NonFungibleToken.Collection>(from: path.storagePath)
				if checkCol == nil {
					report.append(logErr(i, err: "Cannot borrow collection from sender. Type : ".concat(type.identifier)))
					continue
				}
				let ids = checkCol!.getIDs()
				ownedIds[type] = ids
			}
			if ownedIds[type]!.contains(ids[i]) {
				owned = true
			}

			let receiver = receivers[i]
			let id = ids[i] 
			let message = messages[i]

			var user = addresses[receiver]
			if user == nil {
				let checkUser = FIND.resolve(receiver)
				if checkUser == nil {
					report.append(logErr(i, err: "Cannot resolve user with name / address : ".concat(receiver)))
					continue
				}
				addresses[receiver] = checkUser!
				user = checkUser!
			}

			// check receiver account storage 
			let receiverCap = getAccount(user!).getCapability<&{NonFungibleToken.Receiver}>(path.publicPath)
			let collectionPublicCap = getAccount(user!).getCapability<&{NonFungibleToken.CollectionPublic}>(path.publicPath)
			let storage = getAuthAccount(user!).type(at: path.storagePath)

			var storageInited = false 
			if storage != nil && checkSameContract(collection: storage!, nft: type){
				storageInited = true
			}

			let r = Report(receiver: receivers[i] , type: types[i], id: ids[i] , message: messages[i] ,receiverLinked: receiverCap.check() , collectionPublicLinked: collectionPublicCap.check() , accountInitialized: storageInited , nftInPlace: owned, err: nil)
			report.append(r)
		}
	
	return report
}


pub struct Report {
	pub let receiver: String 
	pub let type: String 
	pub let id: UInt64 
	pub let message: String 
	pub var ok: Bool
	pub let receiverLinked: Bool?
	pub let collectionPublicLinked: Bool?
	pub let accountInitialized: Bool?
	pub let nftInPlace: Bool?
	pub let err: String?

	init(receiver: String , type: String, id: UInt64 , message: String ,receiverLinked: Bool? , collectionPublicLinked: Bool? , accountInitialized: Bool? , nftInPlace: Bool?, err: String?) {
		self.receiver=receiver
		self.type=type
		self.id=id
		self.message=message
		self.receiverLinked=receiverLinked
		self.collectionPublicLinked=collectionPublicLinked
		self.accountInitialized=accountInitialized
		self.nftInPlace=nftInPlace
		self.err=err
		self.ok = false 
		if accountInitialized == true && nftInPlace == true {
			if receiverLinked == true || collectionPublicLinked == true {
				self.ok = true
			}
		}
	}
}

pub fun checkSameContract(collection: Type, nft: Type) : Bool {
	let colType = collection.identifier
	let croppedCol = colType.slice(from: 0 , upTo : colType.length - "collection".length)
	let nftType = nft.identifier
	let croppedNft = nftType.slice(from: 0 , upTo : nftType.length - "nft".length)
	if croppedCol == croppedNft {
		return true
	}
	return false
}
 