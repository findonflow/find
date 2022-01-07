import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

pub contract TypedMetadata {

	/// A struct interface for Royalty agreed upon by @dete, @rheaplex, @bjartek 
	pub struct interface Royalty {

		/// if nil cannot pay this type
		/// if not nill withdraw that from main vault and put it into distributeRoyalty 
		pub fun calculateRoyalty(type:Type, amount:UFix64) : UFix64?

		/// call this with a vault containing the amount given in calculate royalty and it will be distributed accordingly
		pub fun distributeRoyalty(vault: @FungibleToken.Vault) 

		/// generate a string that represents all the royalties this NFT has for display purposes
		/// This really needs a Type as well to be able to display royalty properly
		pub fun displayRoyalty() : String?  

	}

	// TODO: Should this contain links to your NFT in the originating/source solution? An simple Dictionary of String:String would do
	pub struct Display{
		pub let name: String
		pub let thumbnail: String
		pub let thumbnailMediaType:String
		pub let source: Identity
		pub let sourceURI: String

		init(name:String, thumbnail: String, thumbnailMediaType:String,source:Identity, sourceURI:String) {
			self.source=source
			self.sourceURI=sourceURI
			self.name=name
			self.thumbnail=thumbnail
			self.thumbnailMediaType=thumbnailMediaType
		}
	}

	pub struct Identity{
		pub let id:UInt64
		pub let uuid: UInt64
		pub let type:Type
		pub let discriminator: String

		init(id:UInt64, uuid:UInt64, type:Type, discriminator:String) {
			self.id=id
			self.uuid=uuid
			self.type=type
			self.discriminator=discriminator
		}
	}

	pub struct interface Media {
		pub fun data() : String
		pub let mediaType: String
		pub let protocol: String

	}

	pub struct Medias {
		pub let media : {String:  &{Media}}

		init(_ items: {String: &{Media}}) {
			self.media=items
		}
	}


	/// IPFS specify media that holds the CID as a field
	pub struct IPFSMedia : Media {
	  pub let mediaType: String
		pub let protocol: String
		pub let cid:String

		init(cid:String, mediaType: String) {
			self.cid=cid
			self.protocol="ipfs"
			self.mediaType=mediaType
		}

		pub fun data() : String {
			return self.cid

		}
	}

	/// This is media that is kept as a String onChain. Most often used with SharedMedia that allow you to share this across multiple NFTS
	pub struct StringMedia : Media{
		pub let content: String
		pub let mediaType: String
		pub let protocol: String

		init(content:String, mediaType: String) {
			self.content=content
			self.protocol="onChain"
			self.mediaType=mediaType
		}

		pub fun data(): String {
			return self.content
		}
	}


	/// Generic Media representation that allow you to represent any kind of media you like
	pub struct GenericMedia : Media{
		pub let content: String
		pub let mediaType: String
		pub let protocol: String

		init(content:String, mediaType: String, protocol:String) {
			self.content=content
			self.protocol=protocol
			self.mediaType=mediaType
		}

		pub fun data(): String {
			return self.content
		}
	}

	pub struct SharedMedia : Media {
		pub let mediaType: String
		pub let pointer: ViewReadPointer

		init(pointer: ViewReadPointer, mediaType: String) {
			self.pointer=pointer
			self.mediaType=mediaType

			if !pointer.getViews().contains(Type<StringMedia>()) {
				panic("Cannot create shared media if the pointer does not contain StringMedia")
			}
		}

		pub fun data(): String {
			let result = self.pointer.resolveView(Type<StringMedia>()) 
			if result== nil {
				return ""
			}
			return result as String
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

	//Simple struct signaling that this is editioned
	pub struct Editioned {
		pub let edition: UInt64
		pub let maxEdition: UInt64

		init(edition:UInt64, maxEdition:UInt64){
			self.edition=edition
			self.maxEdition=maxEdition
		}
	}


	// Would this work for rarity? Hoodlums, flovatar, Basicbeasts? comments?
	pub struct Rarity{
		pub let rarity: UFix64
		pub let rarityName: String
		pub let parts: {String: RarityPart}

		init(rarity: UFix64, rarityName: String, parts:{String:RarityPart}) {
			//TODO: pre that rarity cannot be above 100.0
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

	pub struct ViewReadPointer{
		pub let collection: Capability<&{MetadataViews.ResolverCollection}>
		pub let id: UInt64
		pub let views: [Type]

		init(collection: Capability<&{MetadataViews.ResolverCollection}>, id: UInt64, views: [Type]) {
			self.collection=collection
			self.id=id
			self.views=views
		}

		pub fun resolveView(_ type: Type) : AnyStruct? {
			return self.collection.borrow()!.borrowViewResolver(id: self.id).resolveView(type)
		}

		pub fun getViews() : [Type]{
			return self.views
		}
	}


	//TODO NFTAuthPointer?
}
