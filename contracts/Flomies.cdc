import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindForge from "./FindForge.cdc"
import FindPack from "./FindPack.cdc"


pub contract Flomies: NonFungibleToken {

	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id:UInt64, serial: UInt64, traits: [UInt64])
	pub event RegisteredTraits(traitId:UInt64, trait:{String : String})

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath

	access(account) var royalties : [MetadataViews.Royalty]
	access(self) let traits : {UInt64: MetadataViews.Trait}

	/*
	Iconic
	Legendary
	Rare
	Common
	*/

	pub struct Metadata {
		pub let nftId: UInt64
		pub let name: String
		pub let serial:UInt64
		pub let thumbnail: String
		pub let image: String
		pub let traits: [UInt64]

		init(nftId: UInt64,name:String,thumbnail: String, image:String, serial:UInt64, traits: [UInt64]) {
			self.nftId=nftId
			self.name=name
			self.thumbnail=thumbnail
			self.image=image
			self.serial=serial
			self.traits=traits
		}
	}

	pub resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver {

		pub let id:UInt64
		pub let serial:UInt64
		pub var nounce:UInt64
		pub let rootHash:String
		pub let traits: [UInt64]

		init(
			serial:UInt64,
			rootHash:String,
			traits: [UInt64]
		) {
			self.nounce=0
			self.serial=serial
			self.id=self.uuid
			self.rootHash=rootHash
			self.traits=traits
		}

		pub fun getViews(): [Type] {
			return  [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Medias>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.ExternalURL>(),
			Type<Metadata>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.Traits>(), 
			Type<FindPack.PackRevealData>(), 
			Type<MetadataViews.Editions>(), 
			Type<MetadataViews.Serial>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {

			let imageFile=MetadataViews.IPFSFile( url: self.rootHash, path: self.serial.toString().concat(".png"))
			var fullMediaType="image/png"
			let traits = self.traits

			let fullMedia=MetadataViews.Media(file:imageFile, mediaType: fullMediaType)

			let name ="Flomies #".concat(self.serial.toString())
			let description= "Flomies is a collection of 3333 homies living on the flow blockchain. Flomies are about art, mental health and innovating in this ecosystem. Our adventure is unique, as is our community."

			switch view {
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: name,
					description: description,
					thumbnail: imageFile
				)

			case Type<MetadataViews.ExternalURL>():
				if self.owner == nil {
					return MetadataViews.ExternalURL("https://find.xyz/")
				}
				return MetadataViews.ExternalURL("https://find.xyz/".concat(self.owner!.address.toString()).concat("/collection/flomies/").concat(self.id.toString()))

			case Type<MetadataViews.Royalties>():
				return MetadataViews.Royalties(Flomies.royalties)

			case Type<MetadataViews.Medias>():
				return MetadataViews.Medias([fullMedia])

			case Type<Metadata>():
				return Metadata(
					nftId : self.id ,
					name : name ,
					thumbnail : imageFile.uri(),
					image : imageFile.uri(),
					serial:self.serial,
					traits:self.traits
				)
			case Type<MetadataViews.NFTCollectionDisplay>():
				let externalURL = MetadataViews.ExternalURL("https://flomiesnft.com")
				let squareImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmYtowktCz6GbP6MqMd6SXqJEYazCpGTcFm4HrWX89nUvo", path: nil), mediaType: "image/png")
				let bannerImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmPeZUjsfrFvkB1bvKBpAsxfoQ6jSoezqwWz9grkmNYdz1", path: nil), mediaType: "image/png")
				return MetadataViews.NFTCollectionDisplay(name: "flomies", 
														  description: "Flomies is a collection of 3333 homies living on the flow blockchain. Flomies are about art, mental health and innovating in this ecosystem. Our adventure is unique, as is our community.", 
														  externalURL: externalURL, 
														  squareImage: squareImage, 
														  bannerImage: bannerImage, 
														  socials: { 
														  	"discord": MetadataViews.ExternalURL("https://discord.gg/tVavHtPD"), 
															"twitter" : MetadataViews.ExternalURL("https://twitter.com/flomiesnft"),
															"instagram" : MetadataViews.ExternalURL("https://www.instagram.com/flomies_nft/")
														  })

			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: Flomies.CollectionStoragePath,
				publicPath: Flomies.CollectionPublicPath,
				providerPath: Flomies.CollectionPrivatePath,
				publicCollection: Type<&Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(),
				publicLinkedType: Type<&Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(),
				providerLinkedType: Type<&Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(),
				createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Flomies.createEmptyCollection()})

			case Type<MetadataViews.Traits>():
				return MetadataViews.Traits(self.getAllTraitsMetadataAsArray())
			

			case Type<FindPack.PackRevealData>():
				let data : {String : String} = {
					"nftImage" : imageFile.uri() ,
					"nftName" : "Flomies ".concat(self.serial.toString()), 
					"packType" : "Flomies"
				}
				return FindPack.PackRevealData(data)

			case Type<MetadataViews.Editions>() : 
				return MetadataViews.Editions([
					MetadataViews.Edition(name: "set", number: self.serial, max: 3333)
				])

			case Type<MetadataViews.Serial>() : 
				return MetadataViews.Serial(self.serial)
			}

			return nil
		}

		pub fun increaseNounce() {
			self.nounce=self.nounce+1
		}

		pub fun getAllTraitsMetadataAsArray() : [MetadataViews.Trait] {
			let traits = self.traits

			var traitMetadata : [MetadataViews.Trait] = []
			for trait in traits {
				traitMetadata.append(Flomies.traits[trait]!)
			}
			return traitMetadata
		}

		pub fun getAllTraitsMetadata() : {String : MetadataViews.Trait} {
			let traitMetadata : {String : MetadataViews.Trait} = {}
			for trait in self.getAllTraitsMetadataAsArray() {
				let traitName = trait.name
				traitMetadata[traitName] = trait
			}
			return traitMetadata
		}
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, ViewResolver.ResolverCollection {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		init () {
			self.ownedNFTs <- {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			let id: UInt64 = token.id
			//TODO: add nounce and emit better event the first time it is moved.

			token.increaseNounce()
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)


			destroy oldToken
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{ViewResolver.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let flomies = nft as! &NFT
			return flomies as &AnyResource{ViewResolver.Resolver}
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//The distinction between sending in a reference and sending in a capability is that when you send in a reference it cannot be stored. So it can only be used in this method
	//while a capability can be stored and used later. So in this case using a reference is the right choice, but it needs to be owned so that you can have a good event
	access(account) fun mintNFT( 
		serial:UInt64,
		rootHash:String,
		traits: [UInt64]
	) : @NonFungibleToken.NFT {

		Flomies.totalSupply = Flomies.totalSupply + 1
		// create a new NFT
		var newNFT <- create NFT(
			serial:serial,
			rootHash:rootHash,
			traits: traits)

		emit Minted(id: newNFT.uuid, serial: newNFT.serial, traits: traits)

			//Always emit events on state changes! always contain human readable and machine readable information
			//TODO: discuss that fields we want in this event. Or do we prefer to use the richer deposit event, since this is really done in the backend
			//emit Minted(id:newNFT.id, address:recipient.owner!.address)
			// deposit it in the recipient's account using their reference
		return <-newNFT

	}

	access(account) fun addTrait(_ traits: {UInt64 : MetadataViews.Trait}) {
		for key in traits.keys {
			let trait = traits[key]!
			self.traits[key]=trait
			let traits : {String : String} = {}
			traits["name"] = trait.name 
			traits["value"] = trait.value as! String 
			traits["rarity_description"] = trait.rarity?.description
			traits["rarity_score"] = trait.rarity?.score?.toString()
			traits["rarity_max"] = trait.rarity?.max?.toString()

			emit RegisteredTraits(traitId: key, trait:traits)
		}
	}

	pub fun getTraits() : {UInt64:MetadataViews.Trait}{
		return self.traits
	}

	pub fun getTrait(_ id:UInt64) : MetadataViews.Trait? {
		return self.traits[id]
	}

	access(account) fun addRoyaltycut(_ cutInfo: [MetadataViews.Royalty]) {
		var cutInfos = self.royalties 
		cutInfos.appendAll(cutInfo)
		// for validation only
		let royalties = MetadataViews.Royalties(cutInfos)
		self.royalties.appendAll(cutInfo)
	}

	pub resource Forge: FindForge.Forge {
		pub fun mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @NonFungibleToken.NFT {
			let info = data as? {String : AnyStruct} ?? panic("The data passed in is not in form of {String : AnyStruct}")

			let serial = info["serial"]! as? UInt64 ?? panic("Serial is missing")
			let rootHash = info["rootHash"]! as? String ?? panic("RootHash is missing")
			let traits = info["traits"]! as? [UInt64] ?? panic("traits are missing")

			return <- Flomies.mintNFT( 
				serial:serial,
				rootHash:rootHash,
				traits:traits
			)
		}

		pub fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
			let type = data.getType() 

			switch type {
				case Type<{UInt64 : MetadataViews.Trait}>() : 
					// for duplicated indexes, the new one will replace the old one 
					let typedData = data as! {UInt64 : MetadataViews.Trait}
					Flomies.addTrait(typedData)
					return

				case Type<[MetadataViews.Royalty]>() : 
					let typedData = data as! [MetadataViews.Royalty]
					Flomies.royalties = typedData
					return

			}
		}
	}

	access(account) fun createForge() : @{FindForge.Forge} {
		return <- create Forge()
	}

	init() {
		self.traits={}
		// Initialize the total supply
		self.totalSupply = 0

		self.royalties = []

		// Set the named paths
		self.CollectionStoragePath = /storage/flomiesNFT
		self.CollectionPublicPath = /public/flomiesNFT
		self.CollectionPrivatePath = /private/flomiesNFT

		self.account.save<@NonFungibleToken.Collection>(<- Flomies.createEmptyCollection(), to: Flomies.CollectionStoragePath)
		self.account.link<&Flomies.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
			Flomies.CollectionPublicPath,
			target: Flomies.CollectionStoragePath
		)
		self.account.link<&Flomies.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
			Flomies.CollectionPrivatePath,
			target: Flomies.CollectionStoragePath
		)

		FindForge.addForgeType(<- create Forge())

		emit ContractInitialized()
	}
}
 