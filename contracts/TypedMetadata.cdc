import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

pub contract TypedMetadata {

	pub resource interface TypeConverter {
		//this is identifier for now but it should maybe be type
		pub fun convert(_ value:AnyStruct) : AnyStruct
		pub fun convertTo() : [Type]
		pub fun convertFrom() : Type
	}


	pub resource interface ViewResolverCollection {
		pub fun borrowViewResolver(id: UInt64): &{ViewResolver}
		pub fun deposit(token: @NonFungibleToken.NFT)
		pub fun getIDs(): [UInt64]
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
	}

	pub resource interface ViewResolver {
		pub fun getViews() : [Type] 
		pub fun resolveView(_ view:Type): AnyStruct
	}

	pub struct Royalties{
		pub let royalty: { String : Royalty}
		init(royalty: {String : Royalty}) {
			self.royalty=royalty
		}
	}

	// A struct for Rarity
	// A struct for Rarity Data parts like on flovatar
	// A Display struct for showing the name/thumbnail of something

	/*
	The idea here is that a platform can register all the types it supporst using the identifier of the type, it would be better if we could use Type as the key here
	*/
	pub struct Royalty{
		pub let wallets: { String : Capability<&{FungibleToken.Receiver}>  }
		pub let cut: UFix64

		//can be percentage
		pub let percentage: Bool
		pub let owner: Address

		//Not ideal that type cannot be dictionary key here so we use a identifier
		init(wallets:{ String: Capability<&{FungibleToken.Receiver}>}, cut: UFix64, percentage: Bool, owner: Address ){
			self.wallets=wallets
			self.cut=cut
			self.percentage=percentage
			self.owner=owner
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


	pub fun createPercentageRoyalty(user:Address, cut: UFix64) : Royalty {
		let userAccount=getAccount(user)
		let fusdReceiver = userAccount.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		let flowReceiver = userAccount.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		let walletDicts :{ String : Capability<&{FungibleToken.Receiver}> }= {}
		walletDicts[Type<@FUSD.Vault>().identifier]=fusdReceiver
		walletDicts[Type<@FlowToken.Vault>().identifier]=flowReceiver
		let userRoyalty = TypedMetadata.Royalty(wallets: walletDicts, cut: cut, percentage:true, owner:user)

		return userRoyalty
	}


}
