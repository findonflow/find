import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import ViewResolver from "./standard/ViewResolver.cdc"
import FIND from "./FIND.cdc"
import FindUtils from "./FindUtils.cdc"

access(all) contract FindForgeOrder {

	access(all) event ContractInitialized()
	access(all) event Withdraw(id: UInt64, from: Address?)
	access(all) event Deposit(id: UInt64, to: Address?)
	access(all) event ForgeOrdered(lease: String, mintType: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String , collectionBannerImage: String, collectionSocials: {String : String})
	access(all) event ForgeOrderCompleted(lease: String, mintType: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String , collectionBannerImage: String, collectionSocials: {String : String}, contractName: String)
	access(all) event ForgeOrderCancelled(lease: String, mintType: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String , collectionBannerImage: String, collectionSocials: {String : String}, contractName: String)

	access(all) let QueuedCollectionStoragePath: StoragePath
	access(all) let QueuedCollectionPublicPath: PublicPath
	access(all) let CompletedCollectionStoragePath: StoragePath
	access(all) let CompletedCollectionPublicPath: PublicPath

	access(all) let mintTypes : [String]
	// contractName : Resource UUID
	access(all) let contractNames : {String : UInt64}
	
	access(all) resource Order: ViewResolver.Resolver {
		access(all) let id: UInt64
		access(all) let leaseName: String 
		access(all) let mintType: String 
		access(all) let contractName: String
		access(all) let minterCut: UFix64?
		access(all) let collectionDisplay : MetadataViews.NFTCollectionDisplay 

		init(
			lease: String,
			mintType: String, 
			minterCut: UFix64?,
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
			self.minterCut=minterCut
			self.collectionDisplay = collectionDisplay
		}

		access(all) view fun getViews(): [Type] {
			return [
				Type<MetadataViews.Display>()
			]
		}

		access(all) fun resolveView(_ view: Type): AnyStruct? {
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
			//		publicCollection: Type<&NFGv3.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,ViewResolver.ResolverCollection}>(),
			//		publicLinkedType: Type<&NFGv3.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,ViewResolver.ResolverCollection}>(),
			//		providerLinkedType: Type<&NFGv3.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,ViewResolver.ResolverCollection}>(),
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

	access(all) resource Collection : ViewResolver.ResolverCollection {
		access(all) let orders: @{UInt64: FindForgeOrder.Order}

		init () {
			self.orders <- {}
		}

		destroy () {
			destroy self.orders
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		access(all) fun withdraw(withdrawID: UInt64): @FindForgeOrder.Order {
			let token <- self.orders.remove(key: withdrawID) ?? panic("missing Order : ".concat(withdrawID.toString()))

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all) fun deposit(token: @FindForgeOrder.Order) {

			emit Deposit(id: token.id, to: self.owner?.address)

			self.orders[token.id] <-! token
		}

		// getIDs returns an array of the IDs that are in the collection
		access(all) view fun getIDs(): [UInt64] {
			return self.orders.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all) fun borrow(_ id: UInt64): &FindForgeOrder.Order {
			return &self.orders[id] as &{FindForgeOrder.Order}?
		}

		access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver} {
			let nft = &self.orders[id] as &{FindForgeOrder.Order}?
			return nft! as &{ViewResolver.Resolver}
		}

	}

	access(account) fun orderForge(leaseName: String, mintType: String, minterCut: UFix64?, collectionDisplay: MetadataViews.NFTCollectionDisplay) {

		let order <- create FindForgeOrder.Order(lease: leaseName, mintType: mintType, minterCut: minterCut, collectionDisplay: collectionDisplay)
		let c = collectionDisplay
		let s : {String : String} = {}
		for social in c.socials.keys {
			s[social] = c.socials[social]!.url
		} 
		emit ForgeOrdered(lease: leaseName, mintType: mintType, collectionDescription: c.description, collectionExternalURL: c.externalURL.url, collectionSquareImage: c.squareImage.file.uri() , collectionBannerImage: c.bannerImage.file.uri(), collectionSocials: s)
		FindForgeOrder.contractNames[order.contractName] = order.id
		let col = FindForgeOrder.account.storage.borrow<&FindForgeOrder.Collection>(from: FindForgeOrder.QueuedCollectionStoragePath)!
		col.deposit(token: <- order)
	}

	access(account) fun cancelForgeOrder(leaseName: String, mintType: String) {
		let contractName = "Find".concat(FindUtils.firstUpperLetter(leaseName)).concat(mintType)
		let id = FindForgeOrder.contractNames[contractName] ?? panic("Forge is not ordered. identifier : ".concat(contractName))
		let queuedCol = FindForgeOrder.account.storage.borrow<&FindForgeOrder.Collection>(from: FindForgeOrder.QueuedCollectionStoragePath)!
		let order <- queuedCol.withdraw(withdrawID: id) 
		let c = order.collectionDisplay
		let s : {String : String} = {}
		for social in c.socials.keys {
			s[social] = c.socials[social]!.url
		} 
		emit ForgeOrderCancelled(lease: order.leaseName, mintType: order.mintType, collectionDescription: c.description, collectionExternalURL: c.externalURL.url, collectionSquareImage: c.squareImage.file.uri() , collectionBannerImage: c.bannerImage.file.uri(), collectionSocials: s, contractName : contractName)
		destroy order
	}

	access(account) fun fulfillForgeOrder(_ contractName: String, forgeType: Type) : &FindForgeOrder.Order {
		let id = FindForgeOrder.contractNames[contractName] ?? panic("Forge is not ordered. identifier : ".concat(contractName))

		let queuedCol = FindForgeOrder.account.storage.borrow<&FindForgeOrder.Collection>(from: FindForgeOrder.QueuedCollectionStoragePath)!
		let order <- queuedCol.withdraw(withdrawID: id) 
		let c = order.collectionDisplay
		let s : {String : String} = {}
		for social in c.socials.keys {
			s[social] = c.socials[social]!.url
		} 
		emit ForgeOrderCompleted(lease: order.leaseName, mintType: order.mintType, collectionDescription: c.description, collectionExternalURL: c.externalURL.url, collectionSquareImage: c.squareImage.file.uri() , collectionBannerImage: c.bannerImage.file.uri(), collectionSocials: s, contractName : contractName)

		let completedCol = FindForgeOrder.account.storage.borrow<&FindForgeOrder.Collection>(from: FindForgeOrder.CompletedCollectionStoragePath)!
		completedCol.deposit(token: <- order)
		let ref = completedCol.borrow(id)
		return ref
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
	access(all) fun createEmptyCollection(): @FindForgeOrder.Collection {
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
		let cap = self.account.capabilities.storage.issue<&{FindForgeOrder.Collection}>(self.QueuedCollectionStoragePath)
		self.account.capabilities.publish(cap, at: self.QueuedCollectionPublicPath)

		// Create a Collection resource and save it to storage
		let completedCollection <- create Collection()
		self.account.save(<-completedCollection, to: self.CompletedCollectionStoragePath)

		// create a public capability for the collection
		let cap2 = self.account.capabilities.storage.issue<&{FindForgeOrder.Collection}>(self.CompletedCollectionStoragePath)
		self.account.capabilities.publish(cap2, at: self.CompletedCollectionPublicPath)
	}
}

 