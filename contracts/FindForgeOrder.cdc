import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindForge from "./FindForge.cdc"
import FIND from "./FIND.cdc"
import FindUtils from "./FindUtils.cdc"

pub contract FindForgeOrder {

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event ForgeOrdered(lease: String, mintType: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String , collectionBannerImage: String, collectionSocials: {String : String})
	pub event ForgeOrderCompleted(lease: String, mintType: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String , collectionBannerImage: String, collectionSocials: {String : String}, contractName: String)

	pub let QueuedCollectionStoragePath: StoragePath
	pub let QueuedCollectionPublicPath: PublicPath
	pub let CompletedCollectionStoragePath: StoragePath
	pub let CompletedCollectionPublicPath: PublicPath

	pub let mintTypes : [String]
	// contractName : Resource UUID
	pub let contractNames : {String : UInt64}
	
	pub resource Order: MetadataViews.Resolver {
		pub let id: UInt64
		pub let leaseName: String 
		pub let mintType: String 
		pub let contractName: String
		pub let collectionDisplay : MetadataViews.NFTCollectionDisplay 

		init(
			lease: String,
			mintType: String, 
			collectionDisplay : MetadataViews.NFTCollectionDisplay 
		) {
			pre{
				collectionDisplay.name.toLower() == lease : "Collection Display Name must equal to lease Name"
				FindForgeOrder.mintTypes.contains(mintType) : "MintType is not supported at the moment"
			}
			self.id = self.uuid
			self.leaseName=lease
			self.mintType=mintType
			self.contractName="Find".concat(FindUtils.firstUpperLetter(self.leaseName)).concat(mintType)
			self.collectionDisplay = collectionDisplay
		}

		pub fun getViews(): [Type] {
			return [
				Type<MetadataViews.Display>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {
			switch view {
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: self.collectionDisplay.name,
					description: self.collectionDisplay.description,
					thumbnail: self.collectionDisplay.squareImage.file
				)
			
			// This can be implemented when borrow contract is implemented 
			//case Type<MetadataViews.NFTCollectionData>():
			//	return MetadataViews.NFTCollectionData(
			//		storagePath: NFGv3.CollectionStoragePath,
			//		publicPath: NFGv3.CollectionPublicPath,
			//		providerPath: NFGv3.CollectionPrivatePath,
			//		publicCollection: Type<&NFGv3.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
			//		publicLinkedType: Type<&NFGv3.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
			//		providerLinkedType: Type<&NFGv3.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
			//		createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
			//			return <-NFGv3.createEmptyCollection()
			//		})
			//	)
			case Type<MetadataViews.NFTCollectionDisplay>():
				return self.collectionDisplay
			}
			return nil
		}
	}

	pub resource Collection : MetadataViews.ResolverCollection {
		pub let orders: @{UInt64: FindForgeOrder.Order}

		init () {
			self.orders <- {}
		}

		destroy () {
			destroy self.orders
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @FindForgeOrder.Order {
			let token <- self.orders.remove(key: withdrawID) ?? panic("missing Order : ".concat(withdrawID.toString()))

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @FindForgeOrder.Order) {

			emit Deposit(id: token.id, to: self.owner?.address)

			self.orders[token.id] <-! token
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.orders.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrow(_ id: UInt64): &FindForgeOrder.Order {
			return (&self.orders[id] as &FindForgeOrder.Order?)!
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let nft = (&self.orders[id] as auth &FindForgeOrder.Order?)!
			return nft as &AnyResource{MetadataViews.Resolver}
		}

	}

	pub fun orderForge(lease: &FIND.Lease, mintType: String, collectionDisplay: MetadataViews.NFTCollectionDisplay) {
		let leaseName = lease.getName()
		let order <- create FindForgeOrder.Order(lease: leaseName, mintType: mintType, collectionDisplay: collectionDisplay)
		let c = collectionDisplay
		let s : {String : String} = {}
		for social in c.socials.keys {
			s[social] = c.socials[social]!.url
		} 
		emit ForgeOrdered(lease: leaseName, mintType: mintType, collectionDescription: c.description, collectionExternalURL: c.externalURL.url, collectionSquareImage: c.squareImage.file.uri() , collectionBannerImage: c.bannerImage.file.uri(), collectionSocials: s)

		let col = FindForgeOrder.account.borrow<&FindForgeOrder.Collection>(from: FindForgeOrder.QueuedCollectionStoragePath)!
		col.deposit(token: <- order)
	}

	access(account) fun fulfillForge(_ contractName: String) : MetadataViews.NFTCollectionDisplay {
		let id = FindForgeOrder.contractNames[contractName] ?? panic("Forge is not ordered. identifier : ".concat(contractName))

		let queuedCol = FindForgeOrder.account.borrow<&FindForgeOrder.Collection>(from: FindForgeOrder.QueuedCollectionStoragePath)!
		let order <- queuedCol.withdraw(withdrawID: id) 
		let c = order.collectionDisplay
		let s : {String : String} = {}
		for social in c.socials.keys {
			s[social] = c.socials[social]!.url
		} 
		emit ForgeOrdered(lease: order.leaseName, mintType: order.mintType, collectionDescription: c.description, collectionExternalURL: c.externalURL.url, collectionSquareImage: c.squareImage.file.uri() , collectionBannerImage: c.bannerImage.file.uri(), collectionSocials: s)

		let completedCol = FindForgeOrder.account.borrow<&FindForgeOrder.Collection>(from: FindForgeOrder.CompletedCollectionStoragePath)!
		completedCol.deposit(token: <- order)
		return c
	}

	access(account) fun addMintType(_ mintType: String) {
		pre{
			!self.mintTypes.contains(mintType) : "Mint type is already there : ".concat(mintType)
		}
		self.mintTypes.append(mintType)
	}

	access(account) fun removeMintType(_ mintType: String) {
		pre{
			self.mintTypes.contains(mintType) : "Mint type not there : ".concat(mintType)
		}
		self.mintTypes.remove(at: self.mintTypes.firstIndex(of: mintType)!)
	}


	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @FindForgeOrder.Collection {
		return <- create Collection()
	}

	init() {
		// Initialize the total supply
		self.mintTypes = []
		self.contractNames = {}

		// Set the named paths
		self.QueuedCollectionStoragePath = /storage/queuedFindForgeOrder
		self.QueuedCollectionPublicPath = /public/queuedFindForgeOrder
		self.CompletedCollectionStoragePath = /storage/completedFindForgeOrder
		self.CompletedCollectionPublicPath = /public/completedFindForgeOrder

		// Create a Collection resource and save it to storage
		let queuedCollection <- create Collection()
		self.account.save(<-queuedCollection, to: self.QueuedCollectionStoragePath)

		// create a public capability for the collection
		self.account.link<&FindForgeOrder.Collection{MetadataViews.ResolverCollection}>(
			self.QueuedCollectionPublicPath,
			target: self.QueuedCollectionStoragePath
		)

		// Create a Collection resource and save it to storage
		let completedCollection <- create Collection()
		self.account.save(<-completedCollection, to: self.QueuedCollectionStoragePath)

		// create a public capability for the collection
		self.account.link<&FindForgeOrder.Collection{MetadataViews.ResolverCollection}>(
			self.CompletedCollectionPublicPath,
			target: self.CompletedCollectionStoragePath
		)

	}
}

 