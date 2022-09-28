import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import Crypto
import Clock from "../contracts/Clock.cdc"
import Debug from "./Debug.cdc"
import FLOAT from "../contracts/standard/FLOAT.cdc"
import FindForge from "../contracts/FindForge.cdc"
import FindVerifier from "../contracts/FindVerifier.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub contract FindPack: NonFungibleToken {
	// Events
	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id: UInt64, typeId:UInt64)

	pub event Requeued(packId: UInt64, address:Address)

	pub event Opened(packTypeName: String, packTypeId:UInt64, packId: UInt64, address:Address)
	pub event Fulfilled(packTypeName: String, packTypeId:UInt64, packId:UInt64, address:Address, packFields: {String : String})
	pub event PackReveal(packTypeName: String, packTypeId:UInt64, packId:UInt64, address:Address, rewardId:UInt64, rewardType:String, rewardFields:{String:String}, packFields: {String : String})

	pub event Purchased(packTypeName: String, packTypeId: UInt64, packId: UInt64, address: Address, amount:UFix64)
	pub event MetadataRegistered(packTypeName: String, packTypeId: UInt64)
	pub event FulfilledError(packTypeName: String, packTypeId: UInt64, packId:UInt64, address:Address?, reason:String)

	pub let PackMetadataStoragePath: StoragePath

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath

	pub let OpenedCollectionPublicPath: PublicPath
	pub let OpenedCollectionStoragePath: StoragePath


	pub let DLQCollectionPublicPath: PublicPath
	pub let DLQCollectionStoragePath: StoragePath

	pub var totalSupply: UInt64

	// Mapping of packTypeName (which is the find name) : {typeId : Metadata}
	access(contract) let packMetadata: {String : {UInt64: Metadata}}


	// Verifier container for packs
	// Each struct is one sale type. If they 
	pub struct SaleInfo {
		pub let name : String
		pub let startTime : UFix64 
		pub let endTime : UFix64?
		pub let price : UFix64
		pub let purchaseLimit : UInt64?
		pub let purchaseRecord : {Address : UInt64}
		pub let verifiers : [{FindVerifier.Verifier}]
		pub let verifyAll : Bool 

		init(name : String, startTime : UFix64 , endTime : UFix64? , price : UFix64, purchaseLimit : UInt64?, verifiers: [{FindVerifier.Verifier}], verifyAll : Bool ) {
			self.name = name
			self.startTime = startTime
			self.endTime = endTime
			self.price = price
			self.purchaseLimit = purchaseLimit
			self.purchaseRecord = {}
			self.verifiers = verifiers
			self.verifyAll = verifyAll
		}

		pub fun inTime(_ time: UFix64) : Bool {
			let started = time >= self.startTime
			if self.endTime == nil {
				return started
			}

			return started && time <= self.endTime!
		}

		pub fun buy(_ addr: Address) {

			// If verified false, then panic 

			if !self.verify(addr) {
				panic("You are not qualified to buy this pack at the moment")
			}

			let purchased = (self.purchaseRecord[addr] ?? 0 ) + 1
			if self.purchaseLimit != nil && self.purchaseLimit! < purchased {
				panic("You are only allowed to purchase ".concat(self.purchaseLimit!.toString()))
			}
			self.purchaseRecord[addr] = purchased
		}

		pub fun checkBought(_ addr: Address) : UInt64 {
			return self.purchaseRecord[addr] ?? 0
		}

		pub fun checkBuyable(addr: Address, time: UFix64) : Bool {
			// If not in time, return false
			if !self.inTime(time) {
				return false
			}

			// If verified false, then false 
			if !self.verify(addr) {
				return false
			}

			// If exceed purchase limit, return false
			let purchased = (self.purchaseRecord[addr] ?? 0 ) + 1
			if self.purchaseLimit != nil && self.purchaseLimit! < purchased {
				return false
			}
			// else return true
			return true
		}

		access(contract) fun verify(_ addr: Address) : Bool {
			if self.verifiers.length == 0 {
				return true
			}

			if self.verifyAll {
				for verifier in self.verifiers {
					if !verifier.verify(self.generateParam(addr)) {
						return false
					}
				}
				return true
			}
			// If only has to verify one 
			for verifier in self.verifiers {
				if verifier.verify(self.generateParam(addr)) {
					return true
				}
			}
			return false
		}

		access(contract) fun generateParam(_ addr: Address) : {String : AnyStruct} {
			return {
				"address" : addr
			}
		}

	}

	// Input for minting packs from forge
	pub struct MintPackData {
		pub let packTypeName: String
		pub let typeId: UInt64 
		pub let hash: String 
		pub let verifierRef: &FindForge.Verifier

		init(packTypeName: String, typeId: UInt64, hash: String, verifierRef: &FindForge.Verifier) {
			self.packTypeName = packTypeName
			self.typeId = typeId
			self.hash = hash
			self.verifierRef = verifierRef
		}
	}

	pub struct PackRevealData {

		pub let data: {String:String}

		init(_ data: {String:String}) {
			self.data=data
		}
	}

	pub struct Metadata {
		pub let name: String
		pub let description: String

		pub let thumbnailHash: String?
		pub let thumbnailUrl:String?

		pub let wallet: Capability<&{FungibleToken.Receiver}>
		pub let walletType: Type

		pub let openTime: UFix64
		pub let saleInfos: [SaleInfo]

		pub let storageRequirement: UInt64
		pub let collectionDisplay: MetadataViews.NFTCollectionDisplay

		pub let packFields: {String : String}
		pub let extraData : {String : AnyStruct}

		pub let itemTypes: [Type]
		access(contract) let providerCaps: {Type : Capability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection}>} 

		access(contract) let primarySaleRoyalties : MetadataViews.Royalties
		access(contract) let royalties : MetadataViews.Royalties

		pub let requiresReservation: Bool

		init(name: String, description: String, thumbnailUrl: String?,thumbnailHash: String?, wallet: Capability<&{FungibleToken.Receiver}>, openTime:UFix64, walletType:Type, itemTypes: [Type],  providerCaps: {Type : Capability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection}>} , requiresReservation:Bool, storageRequirement: UInt64, saleInfos: [SaleInfo], primarySaleRoyalties : MetadataViews.Royalties, royalties : MetadataViews.Royalties, collectionDisplay: MetadataViews.NFTCollectionDisplay, packFields: {String : String} , extraData : {String : AnyStruct}) {
			self.name = name
			self.description = description
			self.thumbnailUrl = thumbnailUrl
			self.thumbnailHash = thumbnailHash
			self.wallet=wallet
			self.walletType=walletType

			self.openTime=openTime
			self.itemTypes=itemTypes
			self.providerCaps=providerCaps

			self.primarySaleRoyalties=primarySaleRoyalties
			self.royalties=royalties

			self.storageRequirement= storageRequirement
			self.collectionDisplay= collectionDisplay

			self.requiresReservation=requiresReservation
			self.packFields=packFields

			self.saleInfos=saleInfos
			self.extraData=extraData
		}

		pub fun getThumbnail() : AnyStruct{MetadataViews.File} {
			if let hash = self.thumbnailHash {
				return MetadataViews.IPFSFile(cid: hash, path: nil)
			}
			return MetadataViews.HTTPFile(url:self.thumbnailUrl!)
		}

		pub fun canBeOpened() : Bool {
			return self.openTime <= Clock.time()
		}

		access(contract) fun borrowSaleInfo(_ i: Int) : &SaleInfo {
			return &self.saleInfos[i] as &FindPack.SaleInfo
		}
	}

	access(account) fun registerMetadata(packTypeName: String, typeId: UInt64, metadata: Metadata) {
		emit MetadataRegistered(packTypeName: packTypeName, packTypeId: typeId)
		let mapping = self.packMetadata[packTypeName] ?? {} //<- if this is empty then setup the storage slot for this pack type

		// first time we create this type ID, if its not there then we create it. 
		if mapping[typeId] == nil {
			let pathIdentifier = self.getPacksCollectionPath(packTypeName: packTypeName, packTypeId: typeId)
			let storagePath = StoragePath(identifier: pathIdentifier) ?? panic("Cannot create path from identifier : ".concat(pathIdentifier))
			let publicPath = PublicPath(identifier: pathIdentifier) ?? panic("Cannot create path from identifier : ".concat(pathIdentifier))
			FindPack.account.save<@NonFungibleToken.Collection>( <- FindPack.createEmptyCollection(), to: storagePath)
			FindPack.account.link<&FindPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, FindPack.CollectionPublic, MetadataViews.ResolverCollection}>(
				publicPath,
				target: storagePath
			)
		}

		mapping[typeId] = metadata
		self.packMetadata[packTypeName] = mapping
	}

	pub fun getMetadataById(packTypeName: String, typeId: UInt64): Metadata? {

		if self.packMetadata[packTypeName] != nil {
			return self.packMetadata[packTypeName]![typeId]
		}

		return nil
	}

	pub fun getMetadataByName(packTypeName: String): {UInt64 : Metadata} {

		if self.packMetadata[packTypeName] != nil {
			return self.packMetadata[packTypeName]!
		}

		return {}
	}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		// The token's ID
		pub let id: UInt64
		pub let packTypeName: String

		// The token's typeId
		access(self) var typeId: UInt64

		//this is added to the NFT when it is opened
		access(self) var openedBy: {Type : Capability<&{NonFungibleToken.Receiver}>}

		access(account) let hash: String

		access(self) let royalties : [MetadataViews.Royalty]

		// init
		//
		init(packTypeName: String, typeId: UInt64, hash:String, royalties: [MetadataViews.Royalty]) {
			self.id = self.uuid
			self.typeId = typeId
			self.openedBy={}
			self.hash=hash
			self.royalties=royalties
			self.packTypeName=packTypeName
		}

		pub fun getOpenedBy() : {Type : Capability<&{NonFungibleToken.Receiver}>} {
			if self.openedBy== nil {
				panic("Pack is not opened")
			}
			return self.openedBy!
		}

		pub fun getHash() : String{
			return self.hash
		}

		access(contract) fun setTypeId(_ id: UInt64) {
			self.typeId=id
		}

		access(contract) fun resetOpenedBy() : Address {
			if self.openedBy.length == 0 {
				panic("Pack is not opened")
			}
			let cap = self.openedBy!

			self.openedBy={}
			return cap.values[0].address
		}

		access(contract) fun setOpenedBy(_ cap:{Type : Capability<&{NonFungibleToken.Receiver}>}) {
			if self.openedBy.length != 0 {
				panic("Pack has already been opened")
			}
			self.openedBy=cap
		}

		pub fun getTypeID() :UInt64 {
			return self.typeId
		}

		pub fun getMetadata(): Metadata {
			return FindPack.getMetadataById(packTypeName: self.packTypeName, typeId: self.typeId)!
		}

		pub fun getViews(): [Type] {
			return [
			Type<MetadataViews.Display>(), 
			Type<Metadata>(),
			Type<String>(), 
			Type<MetadataViews.ExternalURL>(), 
			Type<MetadataViews.Royalties>(), 
			Type<MetadataViews.NFTCollectionData>(), 
			Type<MetadataViews.NFTCollectionDisplay>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {
			let metadata = self.getMetadata()
			switch view {
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: metadata.name,
					description: metadata.description,
					thumbnail: metadata.getThumbnail()
				)
			case Type<String>():
				return metadata.name

				case Type<FindPack.Metadata>(): 
				return metadata
				case Type<MetadataViews.ExternalURL>(): 
				//return MetadataViews.ExternalURL("https://find.xyz/".concat(self.owner!.address.toString()).concat("/collection/findPack/").concat(self.id.toString()))
				return MetadataViews.ExternalURL("https://find.xyz/")

				case Type<MetadataViews.Royalties>(): 
				return MetadataViews.Royalties(self.royalties)

				case Type<MetadataViews.NFTCollectionData>(): 
				return MetadataViews.NFTCollectionData(
					storagePath: FindPack.CollectionStoragePath,
					publicPath: FindPack.CollectionPublicPath,
					providerPath: FindPack.CollectionPrivatePath,
					publicCollection: Type<&FindPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
					publicLinkedType: Type<&FindPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
					providerLinkedType: Type<&FindPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
					createEmptyCollectionFunction: fun () : @NonFungibleToken.Collection {
						return <- FindPack.createEmptyCollection()
					}
				)

				case Type<MetadataViews.NFTCollectionDisplay>(): 

				return self.getMetadata().collectionDisplay

				/* to be determined
				//let externalURL = MetadataViews.ExternalURL("https://find.xyz/mp/findPack")
				let externalURL = MetadataViews.ExternalURL("https://find.xyz/")
				let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_images/1467546091780550658/R1uc6dcq_400x400.jpg"), mediaType: "image")
				let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_banners/1448245049666510848/1652452073/1500x500"), mediaType: "image")
				return MetadataViews.NFTCollectionDisplay(name: "find Pack", 
				description: "Find pack", 
				externalURL: externalURL, 
				squareImage: squareImage, 
				bannerImage: bannerImage, 
				socials: { 
					"discord": MetadataViews.ExternalURL("https://discord.gg/ejdVgzWmYN"), 
					"twitter" : MetadataViews.ExternalURL("https://twitter.com/findonflow")
				})
				*/
			}
			return nil
		}

	}

	pub resource interface CollectionPublic {
		pub fun deposit(token: @NonFungibleToken.NFT)
		pub fun getIDs(): [UInt64]
		pub fun contains(_ id: UInt64): Bool
		pub fun getPacksLeft() : Int   // returns the no of a type 
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
		pub fun borrowFindPack(id: UInt64): &FindPack.NFT? 
		pub fun buyWithSignature(packId: UInt64, signature:String, vault: @FungibleToken.Vault, collectionCapability: Capability<&Collection{NonFungibleToken.Receiver}>) 
		pub fun buy(packTypeName: String, typeId: UInt64, vault: @FungibleToken.Vault, collectionCapability: Capability<&Collection{NonFungibleToken.Receiver}>)
	}

	// Collection
	// A collection of FindPack NFTs owned by an account
	//
	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic, MetadataViews.ResolverCollection {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		//this has to be called on the DLQ collection
		pub fun requeue(packId:UInt64) {
			let token <- self.withdraw(withdrawID: packId) as! @NFT

			let address=token.resetOpenedBy()
			let cap=getAccount(address).getCapability<&Collection{NonFungibleToken.Receiver}>(FindPack.CollectionPublicPath)
			let receiver = cap.borrow()!
			receiver.deposit(token: <- token)
			emit Requeued(packId:packId, address: cap.address)
		}

		pub fun open(packId: UInt64, receiverCap: {Type : Capability<&{NonFungibleToken.Receiver}>}) {
			for cap in receiverCap.values {
				if !cap.check() {
					panic("Receiver cap is not valid")
				}
			}
			let pack=self.borrowFindPack(id:packId) ?? panic ("This pack is not in your collection")

			if !pack.getMetadata().canBeOpened() {
				panic("You cannot open the pack yet")
			}

			let token <- self.withdraw(withdrawID: packId) as! @FindPack.NFT
			token.setOpenedBy(receiverCap)

			// establish the receiver for Redeeming FindPack
			let receiver = FindPack.account.getCapability<&{NonFungibleToken.Receiver}>(FindPack.OpenedCollectionPublicPath).borrow()!

			let typeId=token.getTypeID()
			let packTypeName=token.packTypeName
			// deposit for consumption
			receiver.deposit(token: <- token)

			emit Opened(packTypeName: packTypeName, packTypeId:typeId, packId: packId, address:self.owner!.address) 
		}

		pub fun buyWithSignature(packId: UInt64, signature:String, vault: @FungibleToken.Vault, collectionCapability: Capability<&Collection{NonFungibleToken.Receiver}>) {
			pre {
				self.owner!.address == FindPack.account.address : "You can only buy pack directly from the FindPack account"
			}

			let nft <- self.withdraw(withdrawID: packId) as!  @NFT
			let metadata= nft.getMetadata()

			// get the correct sale struct based on time and lowest price
			let timestamp=Clock.time()
			var lowestPrice : UFix64? = nil
			var saleInfo : SaleInfo? = nil
			var saleInfoIndex : Int? = nil
			for i, info in metadata.saleInfos {
				// for later implement : if it requires all sale info checks 
				if info.checkBuyable(addr: collectionCapability.address, time:timestamp) {
					if lowestPrice == nil || lowestPrice! > info!.price {
						lowestPrice = info!.price
						saleInfo = info
						saleInfoIndex = i
					}
				}
			}

			if saleInfo == nil || saleInfoIndex == nil || lowestPrice == nil {
				panic("You cannot buy the pack yet")
			}

			if !metadata.requiresReservation {
				panic("This pack type does not require reservation, use the open buy method")
			}

			if vault.getType() != metadata.walletType {
				panic("The vault sent in is not of the desired type ".concat(metadata.walletType.identifier))
			}

			if saleInfo!.price != vault.balance {
				panic("Vault does not contain required amount of FT ".concat(saleInfo!.price.toString()))
			}
			let keyList = Crypto.KeyList()
			let accountKey = self.owner!.keys.get(keyIndex: 0)!.publicKey

			// Adds the public key to the keyList
			keyList.add(
				PublicKey(
					publicKey: accountKey.publicKey,
					signatureAlgorithm: accountKey.signatureAlgorithm
				),
				hashAlgorithm: HashAlgorithm.SHA3_256,
				weight: 1.0
			)

			// Creates a Crypto.KeyListSignature from the signature provided in the parameters
			let signatureSet: [Crypto.KeyListSignature] = []
			signatureSet.append(
				Crypto.KeyListSignature(
					keyIndex: 0,
					signature: signature.decodeHex()
				)
			)

			// Verifies that the signature is valid and that it was generated from the
			// owner of the collection
			if(!keyList.verify(signatureSet: signatureSet, signedData: nft.hash.utf8)){
				panic("Unable to validate the signature for the pack!")
			}

			let packTypeId=nft.getTypeID()
			let packTypeName = nft.packTypeName

			for royalty in metadata.primarySaleRoyalties.getRoyalties() {
				if royalty.receiver.check(){
					royalty.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: vault.balance * royalty.cut))
				} else {
					//to-do :  emit events here ?
				}
			}

			metadata.wallet.borrow()!.deposit(from: <- vault)
			collectionCapability.borrow()!.deposit(token: <- nft)

			emit Purchased(packTypeName: packTypeName, packTypeId: packTypeId, packId: packId, address: collectionCapability.address, amount:saleInfo!.price)
		}

		pub fun buy(packTypeName: String, typeId: UInt64, vault: @FungibleToken.Vault, collectionCapability: Capability<&Collection{NonFungibleToken.Receiver}>) {
			pre {
				self.owner!.address == FindPack.account.address : "You can only buy pack directly from the FindPack account"
			}

			let keys = self.ownedNFTs.keys
			if  keys.length == 0 {
				panic("No more packs of this type. PackName: ".concat(packTypeName).concat(" packId : ").concat(typeId.toString()))
			}

			let key=keys[0]
			let nft <- self.withdraw(withdrawID: key) as!  @NFT
			let metadata= nft.getMetadata()

			if metadata.requiresReservation {
				panic("Cannot buy a pack that requires reservation without a reservation signature and id")
			}

			let user=collectionCapability.address
			let timestamp=Clock.time()

			var lowestPrice : UFix64? = nil
			var saleInfo : SaleInfo? = nil
			var saleInfoIndex : Int? = nil
			for i, info in metadata.saleInfos {
				// for later implement : if it requires all sale info checks 
				if info.checkBuyable(addr: collectionCapability.address, time:timestamp) {
					if lowestPrice == nil || lowestPrice! > info!.price {
						lowestPrice = info!.price
						saleInfo = info
						saleInfoIndex = i
					}
				}
			}

			if saleInfo == nil || saleInfoIndex == nil || lowestPrice == nil {
				panic("You cannot buy the pack yet")
			}

			if vault.getType() != metadata.walletType {
				panic("The vault sent in is not of the desired type ".concat(metadata.walletType.identifier))
			}

			if saleInfo!.price != vault.balance {
				panic("Vault does not contain required amount of FT ".concat(saleInfo!.price.toString()))
			}

			//TODO: test
			for royalty in metadata.primarySaleRoyalties.getRoyalties() {
				if royalty.receiver.check(){
					royalty.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: vault.balance * royalty.cut))
				} else {
					//to-do :  emit events here ?
				}
			}

			// record buy 
			FindPack.borrowSaleInfo(packTypeName: packTypeName, packTypeId: typeId, index: saleInfoIndex!).buy(collectionCapability.address)

			metadata.wallet.borrow()!.deposit(from: <- vault)
			collectionCapability.borrow()!.deposit(token: <- nft)

			emit Purchased(packTypeName: packTypeName, packTypeId: typeId, packId: key, address: collectionCapability.address, amount:saleInfo!.price)
		}

		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Could not withdraw nft")

			let nft <- token as! @NFT

			emit Withdraw(id: nft.id, from: self.owner?.address)

			return <-nft
		}

		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @FindPack.NFT

			let id: UInt64 = token.id
			let tokenTypeId = token.getTypeID()

			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)

			destroy oldToken
		}

		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		pub fun contains(_ id: UInt64) : Bool {
			return self.ownedNFTs.containsKey(id)
		}

		//return the number of packs left of a type
		pub fun getPacksLeft() : Int {
			return self.ownedNFTs.length
		}

		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		// borrowFindPack
		// Gets a reference to an NFT in the collection as a FindPack.NFT,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the FindPack.
		//
		pub fun borrowFindPack(id: UInt64): &FindPack.NFT? {
			if self.ownedNFTs[id] != nil {
				let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
				return ref as! &FindPack.NFT
			} else {
				return nil
			}
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let exampleNFT = nft as! &NFT
			return exampleNFT 
		}

		// destructor
		//
		destroy() {
			destroy self.ownedNFTs
		}

		// initializer
		//
		init () {
			self.ownedNFTs <- {}
		}
	}

	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	access(account) fun mintNFT(packTypeName: String, typeId: UInt64, hash: String, royalties: [MetadataViews.Royalty]) : @NonFungibleToken.NFT {

		let nft <- create FindPack.NFT(packTypeName: packTypeName, typeId: typeId, hash:hash, royalties:royalties)
		emit Minted(id: nft.id, typeId:typeId)

		// deposit it in the recipient's account using their reference
		return <- nft
	}

	access(account) fun fulfill(packId: UInt64, types:[Type], rewardIds: [UInt64], salt:String) {

		let openedPacksCollection = FindPack.account.borrow<&FindPack.Collection>(from: FindPack.OpenedCollectionStoragePath)!
		let pack <- openedPacksCollection.withdraw(withdrawID: packId) as! @FindPack.NFT
		let packTypeName = pack.packTypeName
		let packTypeId = pack.getTypeID()
		let packFields = FindPack.getMetadataById(packTypeName:packTypeName, typeId:packTypeId)!.packFields

		let firstType = types[0]
		let receiver= pack.getOpenedBy()
		let	receivingAddress = receiver[firstType]!.address
		let hash= pack.getHash()
		let rewards=pack.getMetadata().providerCaps

		let receiverAccount=getAccount(receivingAddress)
		var freeStorage=UInt64(0) 
		// prevent underflow
		if receiverAccount.storageCapacity >= receiverAccount.storageUsed {
			freeStorage = receiverAccount.storageCapacity - receiverAccount.storageUsed
		}
		Debug.log("Free capacity from account ".concat(freeStorage.toString()))
		if pack.getMetadata().storageRequirement > freeStorage {
			emit FulfilledError(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receivingAddress, reason: "Not enough flow to hold the content of the pack. Please top up your account")
			self.transferToDLQ(<- pack)
			return
		}

		let receiverCheck :{Type: Bool} = {}
		var hashString = salt
		for i, type in types {

			if receiverCheck[type] == nil {
				if !receiver[type]!.check() {
					emit FulfilledError(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receiver[type]!.address, reason: "The receiver registered in this pack is not valid")
					self.transferToDLQ(<- pack)
					return
				}

				if !rewards[type]!.check() {
					emit FulfilledError(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receiver[type]!.address, reason: "Cannot borrow provider capability to withdraw nfts")
					self.transferToDLQ(<- pack)
					return
				}
				receiverCheck[type]=true
			}

			let id = rewardIds[i]
			hashString= hashString.concat(",").concat(type.identifier).concat(";").concat(id.toString())
		}

		let digest = HashAlgorithm.SHA3_384.hash(hashString.utf8)
		let digestAsString=String.encodeHex(digest)
		if digestAsString != hash {
			emit FulfilledError(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receivingAddress, reason: "The content of the pack was not verified with the hash provided at mint")
			Debug.log("digestAsString : ".concat(hashString))
			Debug.log("hash : ".concat(hash))
			self.transferToDLQ(<- pack)
			return
		}

		for i, type in types {
			let id = rewardIds[i]
			let target=receiver[type]!.borrow()!
			let source=rewards[type]!.borrow()!

			let viewType= Type<PackRevealData>()
			let nft=source.borrowViewResolver(id: id)

			var fields : {String: String}= {}
			if nft.getViews().contains(viewType) {
				let view=nft.resolveView(viewType)! as! PackRevealData
				fields=view.data
			}
			let token <- source.withdraw(withdrawID: id)

			let metadata = pack.getMetadata()

			emit PackReveal(
				packTypeName: packTypeName, 
				packTypeId: packTypeId,

				packId:packId,
				address:receiver[type]!.address,
				rewardId: id,
				rewardType: token.getType().identifier,
				rewardFields: fields,
				packFields: metadata.packFields
			)
			target.deposit(token: <-token)
		}
		emit Fulfilled(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receivingAddress!, packFields:packFields)

		destroy pack
	}

	access(account) fun transferToDLQ(_ pack: @NFT) {
		let dlq = FindPack.account.borrow<&FindPack.Collection>(from: FindPack.DLQCollectionStoragePath)!
		dlq.deposit(token: <- pack)
	}

	access(account) fun getPacksCollectionPath(packTypeName: String, packTypeId: UInt64) : String {
		return "FindPack_".concat(packTypeName).concat("_").concat(packTypeId.toString())
	}

	pub fun getPacksCollection(packTypeName: String, packTypeId: UInt64) : &FindPack.Collection{CollectionPublic} {

		let pathIdentifier = self.getPacksCollectionPath(packTypeName: packTypeName, packTypeId: packTypeId)
		let path = PublicPath(identifier: pathIdentifier) ?? panic("Cannot create path from identifier : ".concat(pathIdentifier))
		return FindPack.account.getCapability<&FindPack.Collection{FindPack.CollectionPublic}>(path).borrow() ?? panic("Could not borow FindPack collection for path : ".concat(pathIdentifier))
	}

	// given a path, lookin to the NFT Collection and return a new empty collection
	pub fun createEmptyCollectionFromPackData(packData: FindPack.Metadata, type: Type) : @NonFungibleToken.Collection {
		let cap = packData.providerCaps[type] ?? panic("Type passed in does not exist in this pack ".concat(type.identifier))
		if !cap.check() {
			panic("Provider capability of pack is not valid Name and ID".concat(type.identifier))
		}
		let ref = cap.borrow()!
		let resolver = ref.borrowViewResolver(id : ref.getIDs()[0])  // if the ID length is 0, there must be some problem
		let collectionData = MetadataViews.getNFTCollectionData(resolver) ?? panic("Collection Data for this NFT Type is missing. Type : ".concat(resolver.getType().identifier))
		return <- collectionData.createEmptyCollection()
	}

	pub fun canBuy(packTypeName: String, packTypeId:UInt64, user:Address) : Bool {

		let packs=FindPack.getPacksCollection(packTypeName: packTypeName, packTypeId:packTypeId)

		let packsLeft= packs.getPacksLeft()
		if packsLeft == 0 {
			return false
		}

		let packMetadata=FindPack.getMetadataById(packTypeName: packTypeName, typeId: packTypeId)

		if packMetadata==nil {
			return false
		}
		let timestamp=Clock.time() 

		let metadata=packMetadata!

		for info in metadata.saleInfos {
			if info.checkBuyable(addr: user, time:timestamp) {
				return true
			}
		}

		return false
	}

	pub fun getCurrentPrice(packTypeName: String, packTypeId:UInt64, user:Address) : UFix64? {

		let packs=FindPack.getPacksCollection(packTypeName: packTypeName, packTypeId:packTypeId)

		let packsLeft= packs.getPacksLeft()
		if packsLeft == 0 {
			return nil
		}

		let packMetadata=FindPack.getMetadataById(packTypeName: packTypeName, typeId: packTypeId)

		if packMetadata==nil {
			return nil
		}
		let timestamp=Clock.time() 

		let metadata=packMetadata!

		var lowestPrice : UFix64? = nil
		for info in metadata.saleInfos {
			if info.checkBuyable(addr: user, time:timestamp) {
				if lowestPrice == nil || lowestPrice! > info!.price {
					lowestPrice = info!.price
				}
			}
		}

		return lowestPrice
	}

	access(contract) fun borrowSaleInfo(packTypeName: String, packTypeId: UInt64, index: Int) : &FindPack.SaleInfo {
		let mappingRef = (&FindPack.packMetadata[packTypeName] as &{UInt64: FindPack.Metadata}?)!
		let ref = (&mappingRef[packTypeId] as &FindPack.Metadata?)!
		return ref.borrowSaleInfo(index)
	}

	pub fun getOwnerCollection() : Capability<&FindPack.Collection{MetadataViews.ResolverCollection}> {
		return FindPack.account.getCapability<&FindPack.Collection{MetadataViews.ResolverCollection}>(FindPack.CollectionPublicPath)
	}

	pub resource Forge: FindForge.Forge {
		pub fun mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @NonFungibleToken.NFT {

			let royalties : [MetadataViews.Royalty] = []
			// there should be no find cut for the pack. 
			if platform.minterCut != nil && platform.minterCut! != 0.0 {
				royalties.append(MetadataViews.Royalty(receiver:platform.getMinterFTReceiver(), cut: platform.minterCut!, description: "creator"))
			}
			let input = data as? MintPackData ?? panic("The data passed in is not in MintPackData Struct")
			return <- FindPack.mintNFT(packTypeName: platform.name, typeId: input.typeId , hash: input.hash, royalties: royalties)
		}

		pub fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
			let type = data.getType() 

			switch type {
				case Type<{UInt64 : Metadata}>() : 
				let typedData = data as! {UInt64 : Metadata}
				for key in typedData.keys {
					FindPack.registerMetadata(packTypeName: platform.name, typeId: key, metadata: typedData[key]!)
				}
				return

				default : 
				panic("Type : ".concat(data.getType().identifier).concat("is not supported in Find Pack"))
			}
		}
	}

	access(account) fun createForge() : @{FindForge.Forge} {
		return <- create Forge()
	}

	// initializer
	//
	init() {
		self.CollectionStoragePath = /storage/FindPackCollection
		self.CollectionPublicPath = /public/FindPackCollection
		self.CollectionPrivatePath = /private/FindPackCollection

		self.OpenedCollectionStoragePath = /storage/FindPackOpenedCollection
		self.OpenedCollectionPublicPath = /public/FindPackOpenedCollection

		self.DLQCollectionStoragePath = /storage/FindPackDLQCollection
		self.DLQCollectionPublicPath = /public/FindPackDLQCollection

		self.PackMetadataStoragePath= /storage/FindPackMetadata

		//this will not be used, we use UUID as id
		self.totalSupply = 0

		self.packMetadata={}

		// this contract will hold a Collection that FindPack can be deposited to and Admins can Consume them to transfer nfts to the depositing account
		let openedCollection <- create Collection()
		self.account.save(<- openedCollection, to: self.OpenedCollectionStoragePath) 
		self.account.link<&FindPack.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, FindPack.CollectionPublic, MetadataViews.ResolverCollection}>(FindPack.OpenedCollectionPublicPath, target: FindPack.OpenedCollectionStoragePath)


		//a DLQ storage slot so that the opener can put items that cannot be opened/transferred here.
		let dlqCollection <- create Collection()
		self.account.save(<- dlqCollection, to: self.DLQCollectionStoragePath) 
		self.account.link<&FindPack.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, FindPack.CollectionPublic, MetadataViews.ResolverCollection}>(FindPack.DLQCollectionPublicPath, target: FindPack.DLQCollectionStoragePath)

		FindForge.addForgeType(<- create Forge())

		//TODO: Add the Forge resource aswell
		FindForge.addPublicForgeType(forgeType: Type<@Forge>())

		emit ContractInitialized()

	}
}

 
