import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

pub contract FindViews {

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
			let display = MetadataViews.getDisplay(viewResolver) ?? panic("MetadataViews Display View is not implemented on this NFT.")
			let nftCollectionData = MetadataViews.getNFTCollectionData(viewResolver) ?? panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
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
			if let v = MetadataViews.getRoyalties(self.getViewResolver()) {
				return v
			}
			return MetadataViews.Royalties([])
		}

		pub fun valid() : Bool {
			if !self.cap.check() || !self.cap.borrow()!.getIDs().contains(self.id) {
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
			if let v = MetadataViews.getDisplay(self.getViewResolver()) {
				return v
			}
			panic("MetadataViews Display View is not implemented on this NFT.")
		}

		pub fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
			if let v = MetadataViews.getNFTCollectionData(self.getViewResolver()) {
				return v
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
			let display = MetadataViews.getDisplay(viewResolver) ?? panic("MetadataViews Display View is not implemented on this NFT.")
			let nftCollectionData = MetadataViews.getNFTCollectionData(viewResolver) ?? panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
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
			if !self.cap.check() || !self.cap.borrow()!.getIDs().contains(self.id) {
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
			if let v = MetadataViews.getRoyalties(self.getViewResolver()) {
				return v
			}
			return MetadataViews.Royalties([])
		}

		pub fun getDisplay() : MetadataViews.Display {
			if let v = MetadataViews.getDisplay(self.getViewResolver()) {
				return v
			}
			panic("MetadataViews Display View is not implemented on this NFT.")
		}

		pub fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
			if let v = MetadataViews.getNFTCollectionData(self.getViewResolver()) {
				return v
			}
			panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
		}

		pub fun withdraw() :@NonFungibleToken.NFT {
			if !self.cap.check() {
				panic("The pointer capability is invalid.")
			}
			return <- self.cap.borrow()!.withdraw(withdrawID: self.id)
		}

		pub fun deposit(_ nft: @NonFungibleToken.NFT){
			pre{
				self.cap.check() : "The pointer capablity is invalid."
			}
            if !self.cap.check(){
                panic("The pointer capablity is invalid.")
            }
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

	pub struct SoulBound {

		pub let message: String

		init(_ message:String) {
			self.message=message

		}
	}
}
