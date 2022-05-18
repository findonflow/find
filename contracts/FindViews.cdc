import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

pub contract FindViews {

    // A view to expose the information needed to showcase this NFT's collection
    pub struct NFTCollectionDisplay {
        pub let name: String
        pub let description: String
        pub let externalURL: MetadataViews.ExternalURL
        pub let squareImage: MetadataViews.Media
        pub let bannerImage: MetadataViews.Media
        // Social links to reach this collection's social homepages.
        // Possible keys may be "instagram", "twitter", "discord", etc.
        pub let socials: {String: MetadataViews.ExternalURL}

        init(name: String, description: String, externalURL: MetadataViews.ExternalURL, squareImage: MetadataViews.Media, bannerImage: MetadataViews.Media, socials: {String: MetadataViews.ExternalURL}) {
            self.name = name
            self.description = description
            self.externalURL = externalURL
            self.squareImage = squareImage
            self.bannerImage = bannerImage
			self.socials = socials 
        }
    }

    pub struct NFTCollectionData {
        pub let storagePath: StoragePath
        pub let publicPath: PublicPath
        pub let providerPath: PrivatePath
        pub let publicCollection: Type
        pub let publicLinkedType: Type
        pub let providerLinkedType: Type
        pub let createEmptyCollection: ((): @NonFungibleToken.Collection)

        init(
            storagePath: StoragePath,
            publicPath: PublicPath,
            providerPath: PrivatePath,
            publicCollection: Type,
            publicLinkedType: Type,
            providerLinkedType: Type,
            createEmptyCollectionFunction: ((): @NonFungibleToken.Collection)
        ) {
            pre {
                publicLinkedType.isSubtype(of: Type<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>()): "Public type must include NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, and MetadataViews.ResolverCollection interfaces."
                providerLinkedType.isSubtype(of: Type<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>()): "Provider type must include NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, and MetadataViews.ResolverCollection interface."
            }
            self.storagePath=storagePath
            self.publicPath=publicPath
            self.providerPath = providerPath
            self.publicCollection=publicCollection
            self.publicLinkedType=publicLinkedType
            self.providerLinkedType = providerLinkedType
            self.createEmptyCollection=createEmptyCollectionFunction
        }
    }

	pub struct Tag {
		access(self) let tag : {String : String} 

		init(tag: {String : String}) {
			self.tag = tag 
		}

		pub fun getTag() : {String : String} {
			return self.tag
		}
	}

	pub struct Scalar {
		access(self) let scalar : {String : UFix64} 

		init(scalar: {String : UFix64}) {
			self.scalar = scalar 
		}

		pub fun getScalar() : {String : UFix64} {
			return self.scalar
		}
	}

	pub struct Identity{
		pub let id:UInt64
		pub let uuid: UInt64
		pub let type:Type
		pub let typeIdentifier:String
		pub let discriminator: String

		init(id:UInt64, uuid:UInt64, type:Type, discriminator:String) {
			self.id=id
			self.uuid=uuid
			self.type=type
			self.typeIdentifier=type.identifier
			self.discriminator=discriminator
		}
	}

	pub struct Files {
		pub let media : {String: &{MetadataViews.File}}

		init(_ items: {String: &{MetadataViews.File}}) {
			self.media=items
		}
	}

	pub struct OnChainFile : MetadataViews.File{
		pub let content: String
		pub let mediaType: String
		pub let protocol: String

		init(content:String, mediaType: String) {
			self.content=content
			self.protocol="onChain"
			self.mediaType=mediaType
		}

		pub fun uri(): String {
			return self.content
		}
	}

	pub struct SharedMedia : MetadataViews.File {
		pub let mediaType: String
		pub let pointer: ViewReadPointer
		pub let protocol: String

		init(pointer: ViewReadPointer, mediaType: String) {
			self.pointer=pointer
			self.mediaType=mediaType
			self.protocol="shared"

			if !pointer.getViews().contains(Type<OnChainFile>()) {
				panic("Cannot create shared media if the pointer does not contain StringMedia")
			}
		}

		pub fun uri(): String {
			let media = self.pointer.resolveView(Type<OnChainFile>()) 
			if media == nil {
				return ""
			}
			return (media as! OnChainFile).uri()
		}

	}

	// This is an example taken from Versus
	pub struct CreativeWork {
		pub let artist: String
		pub let name: String
		pub let description: String
		pub let type: String

		init(artist: String, name: String, description: String, type: String) {
			self.artist=artist
			self.name=name
			self.description=description
			self.type=type
		}
	}

	pub struct Edition {
		pub let editionNumber: UInt64
		pub let totalInEdition: UInt64

		init(serialNumber:UInt64, totalInEdition:UInt64){
			self.editionNumber=serialNumber
			self.totalInEdition=totalInEdition
		}
	}


	// Would this work for rarity? Hoodlums, flovatar, Basicbeasts? comments?
	pub struct Rarity{
		pub let rarity: UFix64
		pub let rarityName: String
		pub let parts: {String: RarityPart}

		init(rarity: UFix64, rarityName: String, parts:{String:RarityPart}) {
			self.rarity=rarity
			self.rarityName=rarityName
			self.parts=parts
		}
	}

	pub struct RarityPart{

		pub let rarity: UFix64
		pub let rarityName: String
		pub let name: String

		init(rarity: UFix64, rarityName: String, name:String) {

			self.rarity=rarity
			self.rarityName=rarityName
			self.name=name
		}

	}

	//Could this work to mark that something is for sale?
	pub struct ForSale{
		pub let types: [Type] //these are the types of FT that this token can be sold as
		pub let price: UFix64

		init(types: [Type], price: UFix64) {
			self.types=types
			self.price=price
		}
	}

	/// A basic pointer that can resolve data and get owner/id/uuid and gype
	pub struct interface Pointer {
		pub let id: UInt64
		pub fun resolveView(_ type: Type) : AnyStruct?
		pub fun getUUID() :UInt64
		pub fun getViews() : [Type]
		pub fun owner() : Address 
		pub fun valid() : Bool 
		pub fun getItemType() : Type 
		pub fun getViewResolver() : &AnyResource{MetadataViews.Resolver}
	}

	//An interface to say that this pointer can withdraw
	pub struct interface AuthPointer {
		pub fun withdraw() : @AnyResource
	}

	pub struct ViewReadPointer : Pointer {
		access(self) let cap: Capability<&{MetadataViews.ResolverCollection}>
		pub let id: UInt64

		init(cap: Capability<&{MetadataViews.ResolverCollection}>, id: UInt64) {
			self.cap=cap
			self.id=id
		}

		pub fun resolveView(_ type: Type) : AnyStruct? {
			return self.getViewResolver().resolveView(type)
		}

		pub fun getUUID() :UInt64{
			return self.getViewResolver().uuid
		}

		pub fun getViews() : [Type]{
			return self.getViewResolver().getViews()
		}

		pub fun owner() : Address {
			return self.cap.address
		}


		pub fun valid() : Bool {
			if !self.cap.borrow()!.getIDs().contains(self.id) {
				return false
			}
			return true
		}

		pub fun getItemType() : Type {
			return self.getViewResolver().getType()
		}

		pub fun getViewResolver() : &AnyResource{MetadataViews.Resolver} {
			return self.cap.borrow()!.borrowViewResolver(id: self.id)
		}

	}

	pub struct AuthNFTPointer : Pointer, AuthPointer{
		access(self) let cap: Capability<&{MetadataViews.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		pub let id: UInt64
		pub let nounce: UInt64

		init(cap: Capability<&{MetadataViews.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, id: UInt64) {
			self.cap=cap
			self.id=id

			let viewResolver=self.cap.borrow()!.borrowViewResolver(id: self.id)

			let nounceType= Type<FindViews.Nounce>()
			if viewResolver.getViews().contains(nounceType) {
				let nounce= viewResolver.resolveView(nounceType)! as! FindViews.Nounce
				self.nounce=nounce.nounce
			} else {
				self.nounce=0
			}
		}

		pub fun getViewResolver() : &AnyResource{MetadataViews.Resolver} {
			return self.cap.borrow()!.borrowViewResolver(id: self.id)
		}

		pub fun resolveView(_ type: Type) : AnyStruct? {
			return self.getViewResolver().resolveView(type)
		}

		pub fun getUUID() :UInt64{
			return self.getViewResolver().uuid
		}

		pub fun getViews() : [Type]{
			return self.getViewResolver().getViews()
		}

		//TODO: Should require to expose display to be valid
		pub fun valid() : Bool {
			if !self.cap.borrow()!.getIDs().contains(self.id) {
				return false
			}

			let viewResolver=self.getViewResolver()

			let nounceType= Type<FindViews.Nounce>()
			if viewResolver.getViews().contains(nounceType) {
				let nounce= viewResolver.resolveView(nounceType)! as! FindViews.Nounce
				return nounce.nounce==self.nounce
			}
			return true
		}

		pub fun withdraw() :@NonFungibleToken.NFT {
			return <- self.cap.borrow()!.withdraw(withdrawID: self.id)
		}

		pub fun deposit(_ nft: @NonFungibleToken.NFT){
			self.cap.borrow()!.deposit(token: <- nft)
		}

		pub fun owner() : Address {
			return self.cap.address
		}
		pub fun getItemType() : Type {
			return self.getViewResolver().getType()
		}
	}

	pub fun createViewReadPointer(address:Address, path:PublicPath, id:UInt64) : ViewReadPointer {
		let cap=	getAccount(address).getCapability<&{MetadataViews.ResolverCollection}>(path)
		let pointer= FindViews.ViewReadPointer(cap: cap, id: id)
		return pointer
	}

	pub struct Nounce {
		pub let nounce: UInt64

		init(_ nounce: UInt64) {
			self.nounce=nounce
		}
	}


	pub fun typeToPathIdentifier(_ type:Type) : String {
		let identifier=type.identifier

		var i=0
		var newIdentifier=""
		while i < identifier.length {

			let item= identifier.slice(from: i, upTo: i+1) 
			if item=="." {
				newIdentifier=newIdentifier.concat("_")
			} else {
				newIdentifier=newIdentifier.concat(item)
			}
			i=i+1
		}
		return newIdentifier
	}

}
