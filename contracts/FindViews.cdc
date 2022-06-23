import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

pub contract FindViews {

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

	pub struct Files {
		pub let media : {String: &{MetadataViews.File}}

		init(_ items: {String: &{MetadataViews.File}}) {
			self.media=items
		}
	}

	/// Medias is an optional view for collections that issue objects with multiple Media sources in it
    ///
    pub struct Medias {

        /// An arbitrary-sized list for any number of Media items
        pub let items: [MetadataViews.Media]

        init(_ items: [MetadataViews.Media]) {
            self.items = items
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

			if pointer.resolveView(Type<OnChainFile>()) == nil {
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

		//There are just convenience functions for shared views in the standard
		pub fun getRoyalty() : MetadataViews.Royalties
		pub fun getTotalRoyaltiesCut() : UFix64

		//Requred views 
		pub fun getDisplay() : MetadataViews.Display
		pub fun getNFTCollectionData() : MetadataViews.NFTCollectionData

	}

	//An interface to say that this pointer can withdraw
	pub struct interface AuthPointer {
		pub fun withdraw() : @AnyResource
	}

	pub struct ViewReadPointer : Pointer {
		access(self) let cap: Capability<&{MetadataViews.ResolverCollection}>
		pub let id: UInt64 
		pub let uuid: UInt64 
		pub let itemType: Type 

		init(cap: Capability<&{MetadataViews.ResolverCollection}>, id: UInt64) {
			self.cap=cap
			self.id=id

			if !self.cap.check() {
				panic("The capability is not valid.")
			}
			let viewResolver=self.cap.borrow()!.borrowViewResolver(id: self.id)
			let display = FindViews.getDisplay(viewResolver) ?? panic("MetadataViews Display View is not implemented on this NFT.")
			let nftCollectionData = FindViews.getNFTCollectionData(viewResolver) ?? panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
			self.uuid=viewResolver.uuid
			self.itemType=viewResolver.getType()
		}

		pub fun resolveView(_ type: Type) : AnyStruct? {
			return self.getViewResolver().resolveView(type)
		}

		pub fun getUUID() :UInt64{
			return self.uuid
		}

		pub fun getViews() : [Type]{
			return self.getViewResolver().getViews()
		}

		pub fun owner() : Address {
			return self.cap.address
		}

		pub fun getTotalRoyaltiesCut() :UFix64 {
			var total=0.0
			for royalty in self.getRoyalty().getRoyalties() {
				total = total + royalty.cut
			}
			return total
		}

		pub fun getRoyalty() : MetadataViews.Royalties {
			if let royaltiesView = self.resolveView(Type<MetadataViews.Royalties>()) {
				if let v = royaltiesView as? MetadataViews.Royalties {
					return v
				}
			}
			return MetadataViews.Royalties([])
		}

		pub fun valid() : Bool {
			if !self.cap.borrow()!.getIDs().contains(self.id) {
				return false
			}
			return true
		}

		pub fun getItemType() : Type {
			return self.itemType
		}

		pub fun getViewResolver() : &AnyResource{MetadataViews.Resolver} {
			return self.cap.borrow()?.borrowViewResolver(id: self.id) ?? panic("The capability of view pointer is not linked.")
		}

		pub fun getDisplay() : MetadataViews.Display {
			if let royaltiesView = self.resolveView(Type<MetadataViews.Display>()) {
				if let v = royaltiesView as? MetadataViews.Display {
					return v
				}
			}
			panic("MetadataViews Display View is not implemented on this NFT.")
		}

		pub fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
			if let collectionView = self.resolveView(Type<MetadataViews.NFTCollectionData>()) {
				if let v = collectionView as? MetadataViews.NFTCollectionData {
					return v
				}
			}
			panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
		}

	}


	pub fun getNounce(_ viewResolver: &{MetadataViews.Resolver}) : UInt64 {
		if let nounce = viewResolver.resolveView(Type<FindViews.Nounce>()) {
			if let v = nounce as? FindViews.Nounce {
				return v.nounce
			}
		}
		return 0
	}

	pub fun getNFTCollectionDisplay(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.NFTCollectionDisplay? {
		if let view = viewResolver.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) {
			if let v = view as? MetadataViews.NFTCollectionDisplay {
				return v
			}
		}
		return nil
	}


	pub fun getRarity(_ viewResolver: &{MetadataViews.Resolver}) : FindViews.Rarity? {
		if let view = viewResolver.resolveView(Type<FindViews.Rarity>()) {
			if let v = view as? FindViews.Rarity {
				return v
			}
		}
		return nil
	}

	pub fun getTags(_ viewResolver: &{MetadataViews.Resolver}) : FindViews.Tag? {
		if let view = viewResolver.resolveView(Type<FindViews.Tag>()) {
			if let v = view as? FindViews.Tag {
				return v
			}
		}
		return nil
	}

	pub fun getScalar(_ viewResolver: &{MetadataViews.Resolver}) : FindViews.Scalar? {
		if let view = viewResolver.resolveView(Type<FindViews.Scalar>()) {
			if let v = view as? FindViews.Scalar {
				return v
			}
		}
		return nil
	}

	pub fun getDisplay(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.Display? {
		if let view = viewResolver.resolveView(Type<MetadataViews.Display>()) {
			if let v = view as? MetadataViews.Display {
				return v
			}
		}
		return nil
	}

	pub fun getEditions(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.Editions? {
		if let view = viewResolver.resolveView(Type<MetadataViews.Editions>()) {
			if let v = view as? MetadataViews.Editions {
				return v
			}
		}
		return nil
	}

	pub fun getExternalURL(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.ExternalURL? {
		if let view = viewResolver.resolveView(Type<MetadataViews.ExternalURL>()) {
			if let v = view as? MetadataViews.ExternalURL {
				return v
			}
		}
		return nil
	}

	pub fun getNFTCollectionData(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.NFTCollectionData? {
		if let view = viewResolver.resolveView(Type<MetadataViews.NFTCollectionData>()) {
			if let v = view as? MetadataViews.NFTCollectionData {
				return v
			}
		}
		return nil
	}

	pub fun getMedias(_ viewResolver: &{MetadataViews.Resolver}) : FindViews.Medias? {
		if let view = viewResolver.resolveView(Type<FindViews.Medias>()) {
			if let v = view as? FindViews.Medias {
				return v
			}
		}
		return nil
	}

	pub fun getMedia(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.Media? {
		if let view = viewResolver.resolveView(Type<MetadataViews.Media>()) {
			if let v = view as? MetadataViews.Media {
				return v
			}
		}
		return nil
	}

	pub struct AuthNFTPointer : Pointer, AuthPointer{
		access(self) let cap: Capability<&{MetadataViews.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		pub let id: UInt64
		pub let nounce: UInt64
		pub let uuid: UInt64 
		pub let itemType: Type

		init(cap: Capability<&{MetadataViews.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, id: UInt64) {
			self.cap=cap
			self.id=id

			if !self.cap.check() {
				panic("The capability is not valid.")
			}

			let viewResolver=self.cap.borrow()!.borrowViewResolver(id: self.id)
			let display = FindViews.getDisplay(viewResolver) ?? panic("MetadataViews Display View is not implemented on this NFT.")
			let nftCollectionData = FindViews.getNFTCollectionData(viewResolver) ?? panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
			self.nounce=FindViews.getNounce(viewResolver)
			self.uuid=viewResolver.uuid
			self.itemType=viewResolver.getType()
		}

		pub fun getViewResolver() : &AnyResource{MetadataViews.Resolver} {
			return self.cap.borrow()?.borrowViewResolver(id: self.id) ?? panic("The capability of view pointer is not linked.")
		}

		pub fun resolveView(_ type: Type) : AnyStruct? {
			return self.getViewResolver().resolveView(type)
		}

		pub fun getUUID() :UInt64{
			return self.uuid
		}

		pub fun getViews() : [Type]{
			return self.getViewResolver().getViews()
		}

		pub fun valid() : Bool {
			if !self.cap.borrow()!.getIDs().contains(self.id) {
				return false
			}

			let viewResolver=self.getViewResolver()

			if let nounce = viewResolver.resolveView(Type<FindViews.Nounce>()) {
				if let v = nounce as? FindViews.Nounce {
					return v.nounce==self.nounce
				}
			}
			return true
		}

		pub fun getTotalRoyaltiesCut() :UFix64 {
			var total=0.0
			for royalty in self.getRoyalty().getRoyalties() {
				total = total + royalty.cut
			}
			return total
		}

		pub fun getRoyalty() : MetadataViews.Royalties {
			if let royaltiesView = self.resolveView(Type<MetadataViews.Royalties>()) {
				if let v = royaltiesView as? MetadataViews.Royalties {
					return v
				}
			}
			return MetadataViews.Royalties([])
		}

		pub fun getDisplay() : MetadataViews.Display {
			if let royaltiesView = self.resolveView(Type<MetadataViews.Display>()) {
				if let v = royaltiesView as? MetadataViews.Display {
					return v
				}
			}
			panic("MetadataViews Display View is not implemented on this NFT.")
		}

		pub fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
			if let royaltiesView = self.resolveView(Type<MetadataViews.NFTCollectionData>()) {
				if let v = royaltiesView as? MetadataViews.NFTCollectionData {
					return v
				}
			}
			panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
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
			return self.itemType
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
}
