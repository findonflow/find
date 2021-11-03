import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

pub contract TypedMetadata {

	pub resource interface ViewResolverCollection {
		pub fun borrowViewResolver(id: UInt64): &{ViewResolver}
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
	}

 	pub resource interface ViewResolver {
		pub fun getViews() : [Type] 
		pub fun resolveView(_ view:Type): AnyStruct? 
	}

	pub struct Royalties{
		pub let royalty: { String : Royalty}
		init(royalty: {String : Royalty}) {
			self.royalty=royalty
		}
	}

	pub struct Royalty{
		pub let wallet:Capability<&{FungibleToken.Receiver}> 
		pub let cut: UFix64

		//can be percentage
		pub let percentage: Bool
		pub let walletType: Type
		pub let walletName: String
		pub let owner: Address

		init(wallet:Capability<&{FungibleToken.Receiver}>, cut: UFix64, type:Type, percentage: Bool ){
			self.wallet=wallet
			self.cut=cut
			self.percentage=percentage
			self.walletType=type
			self.walletName=type.identifier
			self.owner=wallet.address
		}
	}

	pub struct Medias {
		pub let media : {String:  Media}

		init(_ items: {String: Media}) {
			self.media=items
		}
  }

	pub struct Media {
		pub let data: String
		pub let contentType: String
		pub let protocol: String

		init(data:String, contentType: String, protocol: String) {
			self.data=data
			self.protocol=protocol
			self.contentType=contentType
		}
	}

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

	pub struct Editioned {
		pub let edition: UInt64
		pub let maxEdition: UInt64

		init(edition:UInt64, maxEdition:UInt64){
			self.edition=edition
			self.maxEdition=maxEdition
		}
	}

}
