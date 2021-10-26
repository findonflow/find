import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"

pub contract Artifact: NonFungibleToken {


	pub let ArtifactStoragePath: StoragePath
	pub let ArtifactPublicPath: PublicPath
	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)

	pub struct ViewInfo {
		access(contract) let typ: Type
		access(contract) let result: AnyStruct

		init(typ:Type, result:AnyStruct) {
			self.typ=typ
			self.result=result
		}
	}

	pub resource NFT: NonFungibleToken.INFT, TypedMetadata.ViewResolver {
		pub let id: UInt64
		access(contract) let schemas: {String : ViewInfo}
		access(contract) let name: String

		init(initID: UInt64, name: String, schemas: {String: ViewInfo}) {
			self.id = initID
			self.schemas=schemas
			self.name=name
		}

		pub fun getViews() : [Type] {
			var views : [Type]=[]
			for s in self.schemas.keys {
				views.append(self.schemas[s]!.typ)
			}
			return views
		}

		pub fun resolveView(_ type: Type): AnyStruct {
			return self.schemas[type.identifier]?.result
		}
	}

	pub resource interface CollectionPublic {
		pub fun deposit(token: @NonFungibleToken.NFT)
		pub fun getIDs(): [UInt64]
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic, TypedMetadata.ViewResolverCollection  {
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
			return &self.ownedNFTs[id] as &NonFungibleToken.NFT
		}

		pub fun borrowViewResolver(id: UInt64): &{TypedMetadata.ViewResolver} {
			if self.ownedNFTs[id] != nil {
				let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
				return ref as! &NFT
			} 
			panic("could not find NFT")
		}


		destroy() {
			destroy self.ownedNFTs
		}
	}


	access(account) fun mintNFT(name: String, schemas: [AnyStruct]) : @NFT {
		let views : {String: ViewInfo} = {}
		for s in schemas {
			views[s.getType().identifier]=ViewInfo(typ:s.getType(), result: s)
		}

		let nft <-  create NFT(initID: Artifact.totalSupply, name: name, schemas:views)
		Artifact.totalSupply = Artifact.totalSupply + 1
		return <-  nft
	}


	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	init() {
		// Initialize the total supply
		self.totalSupply = 0
		self.ArtifactPublicPath = /public/artifacts
		self.ArtifactStoragePath = /storage/artifacts

		emit ContractInitialized()
	}
}
