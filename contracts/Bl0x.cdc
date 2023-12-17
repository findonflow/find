import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
//import FindViews from "./FindViews.cdc"

pub contract Bl0x: NonFungibleToken {

	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id:UInt64, address:Address)

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath

	access(self) var rarities : [String]
	access(account) let royalties : [MetadataViews.Royalty]

	/*
	Mythical
	Legendary
	Epic
	Rare
	Uncommon
	Common
	*/

	pub struct Metadata {
		pub let nftId: UInt64
		pub let name: String
		pub let serial:UInt64
		pub let rarity: String
		pub let thumbnail: String
		pub let image: String
		pub let traits: [{String : String}]

		init(nftId: UInt64,name:String,rarity: String,thumbnail: String, image:String, serial:UInt64, traits: [{String : String}]) {
			self.nftId=nftId
			self.name=name
			self.rarity=rarity
			self.thumbnail=thumbnail
			self.image=image
			self.serial=serial
			self.traits=traits
		}
	}

	//TODO: This can be removed before mainnet
	pub struct Data {
		pub let nftId: UInt64
		pub let name: String
		pub let serial:UInt64
		pub let rarity: String
		pub let thumbnail: String
		pub let image: String
		pub let traits: {String : Trait}

		init(nftId: UInt64,name:String,rarity: String,thumbnail: String, image:String, serial:UInt64, traits: {String : Trait}) {
			self.nftId=nftId
			self.name=name
			self.rarity=rarity
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
		pub let season:UInt64
		pub let traits: {String: UInt64}
		pub let royalties: MetadataViews.Royalties

		init(
			serial:UInt64,
			rootHash:String,
			season:UInt64,
			traits: {String: UInt64}
		) {
			self.nounce=0
			self.serial=serial
			self.id=self.uuid
			self.rootHash=rootHash
			self.season=season
			self.traits=traits
			self.royalties=MetadataViews.Royalties(Bl0x.royalties)
		}

		pub fun getViews(): [Type] {
			return  [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Medias>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.ExternalURL>(),
			Type<Data>(),
			Type<Metadata>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.Rarity>(),
			Type<MetadataViews.Traits>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {

			let imageFile=MetadataViews.IPFSFile( url: self.rootHash, path: "thumbnail/".concat(self.serial.toString()).concat(".webp"))


			var fullExtension=".png"
			var fullMediaType="image/png"

			let traits = self.traits
			if self.serial == 885 {
				traits.remove(key: "Module")
			}

			if self.serial == 855 {
				traits["Module"] = 244
			}

			if traits.containsKey("Module") {
				fullExtension=".gif"
				fullMediaType="image/gif"
			}
			let fullFile=MetadataViews.IPFSFile( url: self.rootHash, path: "fullsize/".concat(self.serial.toString()).concat(fullExtension))
			let fullMedia=MetadataViews.Media(file:fullFile, mediaType: fullMediaType)

			let season=self.season
			let name ="Bl0x Season".concat(season.toString()).concat(" #").concat(self.serial.toString())
			let description= "Bl0x Season".concat(season.toString())

			switch view {
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: name,
					description: description,
					thumbnail: imageFile
				)

			case Type<MetadataViews.ExternalURL>():
				return MetadataViews.ExternalURL("https://find.xyz/".concat(self.owner!.address.toString()).concat("/collection/bl0x/").concat(self.id.toString()))

			case Type<MetadataViews.Royalties>():
				return self.royalties

			case Type<MetadataViews.Medias>():
				return MetadataViews.Medias([fullMedia])

			case Type<Data>():
				return Data(
					nftId : self.id ,
					name : name ,
					rarity : self.getRarity() ,
					thumbnail : imageFile.uri(),
					image : fullFile.uri(),
					serial:self.serial,
					traits:self.getAllTraitsMetadata()
				)

			case Type<Metadata>():
				return Metadata(
					nftId : self.id ,
					name : name ,
					rarity : self.getRarity() ,
					thumbnail : imageFile.uri(),
					image : fullFile.uri(),
					serial:self.serial,
					traits:self.getAllTraitsMetadataAsArray()
				)
			case Type<MetadataViews.NFTCollectionDisplay>():
				let externalURL = MetadataViews.ExternalURL("https://find.xyz/mp/bl0x")
				let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://bl0x.xyz/assets/home/Bl0xlogo.webp"), mediaType: "image")
				let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_banners/1535883931777892352/1661105339/1500x500"), mediaType: "image")
				return MetadataViews.NFTCollectionDisplay(name: "bl0x", description: "Minting a Bl0x triggers the catalyst moment of a big bang scenario. Generating a treasure that is designed to relate specifically to its holder.", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: { "discord": MetadataViews.ExternalURL("https://t.co/iY7AhEumR9"), "twitter" : MetadataViews.ExternalURL("https://twitter.com/Bl0xNFT")})

			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: Bl0x.CollectionStoragePath,
				publicPath: Bl0x.CollectionPublicPath,
				providerPath: Bl0x.CollectionPrivatePath,
				publicCollection: Type<&Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(),
				publicLinkedType: Type<&Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(),
				providerLinkedType: Type<&Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(),
				createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Bl0x.createEmptyCollection()})

			case Type<MetadataViews.Rarity>(): 
			return MetadataViews.Rarity(score:nil, max:nil, description: self.getRarity()) 

			case Type<MetadataViews.Traits>():
				return self.getTraitsAsTraits()
			}
			return nil
		}

		pub fun increaseNounce() {
			self.nounce=self.nounce+1
		}

		pub fun getRarity() : String {
			var traitRarity : [String] = []
			for trait in self.getAllTraitsMetadata().values {
				traitRarity.append(trait.metadata["rarity"]!)
			}

			var rarity = ""
			for rarityLevel in Bl0x.rarities {
				if traitRarity.contains(rarityLevel) {
					rarity = rarityLevel
					break
				}
			}

			return rarity 
		}

		pub fun getTraitsAsTraits() : MetadataViews.Traits {
			let traits=self.getAllTraitsMetadata()

			let mvt : [MetadataViews.Trait] = []
			for trait in traits.keys{
				let traitValue = traits[trait]!
				mvt.append(MetadataViews.Trait(name:trait, value: traitValue.getName(), displayType: "String", rarity: MetadataViews.Rarity(
					score:nil, max:nil, description: traitValue.getRarity()
				)))
			}

			return MetadataViews.Traits(mvt)
		}

		pub fun getAllTraitsMetadataAsArray() : [{String : String}] {
			let traits = self.traits
			if self.serial == 885 {
				traits.remove(key: "Module")
			}

			if self.serial == 855 {
				traits["Module"] = 244

			}
			var traitMetadata : [{String : String}] = []
			for trait in traits.keys {
				let traitId = traits[trait]!

				traitMetadata.append(Bl0x.traits[traitId]!.metadata)
			}
			return traitMetadata
		}

		pub fun getAllTraitsMetadata() : {String : Trait} {

			let traits = self.traits
			if self.serial == 885 {
				traits.remove(key: "Module")
			}

			if self.serial == 855 {
				traits["Module"] = 244

			}
			var traitMetadata : {String : Trait} = {}
			for trait in traits.keys {
				let traitId = traits[trait]!
				traitMetadata[trait] = Bl0x.traits[traitId]!
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
			let bl0x = nft as! &NFT
			return bl0x as &AnyResource{ViewResolver.Resolver}
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
		recipient: &{NonFungibleToken.Receiver}, 
		serial:UInt64,
		rootHash:String,
		season:UInt64,
		traits: {String: UInt64}
	){
		pre {
			recipient.owner != nil : "Recipients NFT collection is not owned"
		}

		Bl0x.totalSupply = Bl0x.totalSupply + 1
		// create a new NFT
		var newNFT <- create NFT(
			serial:serial,
			rootHash:rootHash,
			season:season,
			traits: traits)

			//Always emit events on state changes! always contain human readable and machine readable information
			//TODO: discuss that fields we want in this event. Or do we prefer to use the richer deposit event, since this is really done in the backend
			//emit Minted(id:newNFT.id, address:recipient.owner!.address)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)

		}

		/// A trait contains information about a trait
		pub struct Trait {
			pub let id:UInt64
			pub let metadata : {String:String}

			init(id:UInt64, metadata:{String:String}) {
				pre {
					metadata.containsKey("rarity") : "metadata must contain rarity"
					metadata.containsKey("name") : "metadata must contain name"
				}
				self.id=id
				self.metadata=metadata
			}

			pub fun getName() : String{
				return self.metadata["name"]!
			}

			pub fun getRarity() : String{
				return self.metadata["rarity"]!
			}
		}
		access(self) let traits : {UInt64: Trait}

		access(account) fun addTrait(_ trait:Trait) {
			self.traits[trait.id]=trait
		}

		pub fun getTraits() : {UInt64:Trait}{
			return self.traits
		}

		pub fun getTrait(_ id:UInt64) : Trait? {
			return self.traits[id]
		}

		access(account) fun addRoyaltycut(_ cutInfo: MetadataViews.Royalty) {
			var cutInfos = self.royalties 
			cutInfos.append(cutInfo)
			// for validation only
			let royalties = MetadataViews.Royalties(cutInfos)
			self.royalties.append(cutInfo)
		}

		init() {
			//Rarity (Is there a need to update this?)
			self.rarities = [
			"Mythic" ,
			"Legendary" ,
			"Epic" ,
			"Rare" ,
			"Uncommon" ,
			"Common" 
			]

			self.traits={}
			// Initialize the total supply
			self.totalSupply = 0

			// Set Royalty cuts in a transaction
			self.royalties = []

			// Set the named paths
			self.CollectionStoragePath = /storage/bl0xNFTs
			self.CollectionPublicPath = /public/bl0xNFTs
			self.CollectionPrivatePath = /private/bl0xNFTs

			self.account.save<@NonFungibleToken.Collection>(<- Bl0x.createEmptyCollection(), to: Bl0x.CollectionStoragePath)
			self.account.link<&Bl0x.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Bl0x.CollectionPublicPath,
				target: Bl0x.CollectionStoragePath
			)
			self.account.link<&Bl0x.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				Bl0x.CollectionPrivatePath,
				target: Bl0x.CollectionStoragePath
			)

			emit ContractInitialized()
		}
	}
