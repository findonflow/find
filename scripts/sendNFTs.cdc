import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import Profile from "../contracts/Profile.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindAirdropper from "../contracts/FindAirdropper.cdc"
import FindUtils from "../contracts/FindUtils.cdc"

pub fun main(sender: Address, nftIdentifiers: [String],  allReceivers:[String] , ids: [UInt64], memos: [String]) : [Report] {

 	fun logErr(_ i: Int , err: String) : Report {
		return Report(receiver: allReceivers[i] , inputName: nil, findName: nil, avatar: nil, isDapper: nil, type: nftIdentifiers[i], id: ids[i] , message: memos[i] ,receiverLinked: nil , collectionPublicLinked: nil , accountInitialized: nil , nftInPlace: nil, royalties: nil, err: err)
	}

		let paths : [PublicPath] = []
		let contractData : {Type : NFTCatalog.NFTCatalogMetadata} = {}
		let addresses : {String : Address} = {} 

		let account = getAuthAccount(sender)
		let report : [Report] = []
		for i , typeIdentifier in nftIdentifiers {
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

			let checkCol = account.borrow<&NonFungibleToken.Collection>(from: path.storagePath)
			if checkCol == nil {
				report.append(logErr(i, err: "Cannot borrow collection from sender. Type : ".concat(type.identifier)))
				continue
			}
			let ownedNFTs : &{UInt64 : NonFungibleToken.NFT} = &checkCol!.ownedNFTs as &{UInt64 : NonFungibleToken.NFT} 
			let owned = ownedNFTs.containsKey(ids[i])

			let receiver = allReceivers[i]
			let id = ids[i] 
			let message = memos[i]

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

			var isDapper=false
			if let receiver =account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow() {
			 	isDapper=receiver.isInstance(Type<@TokenForwarding.Forwarder>())
			} else {
				if let duc = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver).borrow() {
					isDapper = duc.isInstance(Type<@TokenForwarding.Forwarder>())
				}
				isDapper = false
			}

			// check receiver account storage 
			let receiverCap = getAccount(user!).getCapability<&{NonFungibleToken.Receiver}>(path.publicPath)
			let collectionPublicCap = getAccount(user!).getCapability<&{NonFungibleToken.CollectionPublic}>(path.publicPath)
			let storage = getAuthAccount(user!).type(at: path.storagePath)

			var storageInited = false 
			if storage != nil && checkSameContract(collection: storage!, nft: type){
				storageInited = true
			}

			var royalties : Royalties? = nil
			let mv = account.borrow<&{MetadataViews.ResolverCollection}>(from: path.storagePath)
			if mv != nil {
				let rv = mv!.borrowViewResolver(id: id)
				if let r = MetadataViews.getRoyalties(rv) {
					royalties = Royalties(r)
				}
			}

			var inputName : String? = receiver
			var findName : String? = FIND.reverseLookup(user!)
			if FindUtils.hasPrefix(receiver, prefix: "0x") {
				inputName = nil
			}

			var avatar : String? = nil
			if let profile = getAccount(user!).getCapability<&{Profile.Public}>(Profile.publicPath).borrow() {
				avatar = profile.getAvatar()
			}

			let r = Report(receiver: allReceivers[i] , inputName: inputName, findName: findName, avatar: avatar, isDapper: isDapper, type: nftIdentifiers[i], id: ids[i] , message: memos[i] ,receiverLinked: receiverCap.check() , collectionPublicLinked: collectionPublicCap.check() , accountInitialized: storageInited , nftInPlace: owned, royalties:royalties, err: nil)
			report.append(r)
		}
	
	return report
}


pub struct Report {
	pub let receiver: String 
	pub let inputName: String?
	pub let findName: String?
	pub let avatar: String?
	pub let isDapper: Bool?
	pub let type: String 
	pub let id: UInt64 
	pub let message: String 
	pub var ok: Bool
	pub let receiverLinked: Bool?
	pub let collectionPublicLinked: Bool?
	pub let accountInitialized: Bool?
	pub let nftInPlace: Bool?
	pub let royalties: Royalties?
	pub let err: String?

	init(receiver: String , inputName: String?, findName: String?, avatar: String?, isDapper: Bool? , type: String, id: UInt64 , message: String ,receiverLinked: Bool? , collectionPublicLinked: Bool? , accountInitialized: Bool? , nftInPlace: Bool?, royalties: Royalties?, err: String?) {
		self.receiver=receiver
		self.inputName=inputName
		self.findName=findName
		self.avatar=avatar
		self.isDapper=isDapper
		self.type=type
		self.id=id
		self.message=message
		self.receiverLinked=receiverLinked
		self.collectionPublicLinked=collectionPublicLinked
		self.accountInitialized=accountInitialized
		self.nftInPlace=nftInPlace
		self.err=err
		self.royalties=royalties
		self.ok = false 
		if accountInitialized == true && nftInPlace == true {
			if receiverLinked == true || collectionPublicLinked == true {
				self.ok = true
			}
		}
	}
}

pub struct Royalties {
	pub let totalRoyalty: UFix64 
	pub let royalties: [Royalty]

	init(_ royalties: MetadataViews.Royalties) {
		var totalR = 0.0 
		let array : [Royalty] = []
		for r in royalties.getRoyalties() {
			array.append(Royalty(r))
			totalR = totalR + r.cut
		}
		self.totalRoyalty = totalR 
		self.royalties = array 
	}
}

pub struct Royalty {
	pub let name: String? 
	pub let address: Address 
	pub let cut: UFix64 
	pub let acceptTypes: [String]
	pub let description: String 
	
	init(_ r: MetadataViews.Royalty) {
		self.name = FIND.reverseLookup(r.receiver.address)
		self.address = r.receiver.address
		self.cut = r.cut
		self.description = r.description
		let acceptTypes : [String] = []
		if r.receiver.check() {
			let ref = r.receiver.borrow()!
			let t = ref.getType()
			if t.isInstance(Type<@FungibleToken.Vault>()) {
				acceptTypes.append(t.identifier)
			} else if t == Type<@TokenForwarding.Forwarder>() {
				acceptTypes.append(Type<@FlowToken.Vault>().identifier)
			} else if t == Type<@Profile.User>() {
				let ref = getAccount(r.receiver.address).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()! 
				let wallets = ref.getWallets()
				for w in wallets {
					acceptTypes.append(w.accept.identifier)
				}
			} 
		}
		self.acceptTypes = acceptTypes
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
 