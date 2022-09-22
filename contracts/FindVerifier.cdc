import FLOAT from "../contracts/standard/FLOAT.cdc"
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

pub contract FindVerifier {

	pub struct interface Verifier {
		pub fun verify(_ param: {String : AnyStruct}) : Bool 
	}

	pub struct HasOneFLOAT : Verifier {
		pub let floatEventIds : [UInt64] 

		init(_ floatEventIds: [UInt64]) {
			self.floatEventIds = floatEventIds
		}

		pub fun verify(_ param: {String : AnyStruct}) : Bool {

			if self.floatEventIds.length == 0 {
				return true
			}

			let user : Address = param["address"]! as! Address 
			let float = getAccount(user).getCapability(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection{FLOAT.CollectionPublic}>() 

			if float == nil {
				return false
			}

			let floatsCollection=float!

			let ids = floatsCollection.getIDs()
			for id in ids {
				let nft: &FLOAT.NFT = floatsCollection.borrowFLOAT(id: id)!
				if self.floatEventIds.contains(nft.eventId) {
					return true
				}
			}
			return false
		}

	}

	pub struct HasAllFLOAT : Verifier {
		pub let floatEventIds : [UInt64] 

		init(_ floatEventIds : [UInt64]) {
			self.floatEventIds = floatEventIds
		}

		pub fun verify(_ param: {String : AnyStruct}) : Bool {

			if self.floatEventIds.length == 0 {
				return true
			}

			let user : Address = param["address"]! as! Address 
			let float = getAccount(user).getCapability(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection{FLOAT.CollectionPublic}>() 

			if float == nil {
				return false
			}

			let floatsCollection=float!

			let ids = floatsCollection.getIDs()
			let checked : [UInt64] = []
			for id in ids {
				let nft: &FLOAT.NFT = floatsCollection.borrowFLOAT(id: id)!
				if self.floatEventIds.contains(nft.eventId) && !checked.contains(nft.eventId) {
					checked.append(nft.eventId)
				}
			}
			
			if checked.length == self.floatEventIds.length {
				return true
			}
			return false
		}
	}

	pub struct HasWhiteLabel : Verifier {
		pub let addressList : [Address] 

		init(_ addressList: [Address]) {
			self.addressList = addressList
		}

		pub fun verify(_ param: {String : AnyStruct}) : Bool {
			let user : Address = param["address"]! as! Address 
			return self.addressList.contains(user)
		}
	}

	// Has Find Name 
	pub struct HasFINDName : Verifier {
		pub let findNames: [String] 

		init(_ findNames: [String]) {
			self.findNames = findNames
		}

		pub fun verify(_ param: {String : AnyStruct}) : Bool {

			if self.findNames.length == 0 {
				return true
			}

			let user : Address = param["address"]! as! Address 

			let cap = getAccount(user).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			if !cap.check() {
				return false
			}
			let ref = cap.borrow()!
			let names = ref.getLeases()

			var longerArray = self.findNames 
			var shorterArray = names

			if shorterArray.length > longerArray.length {
				longerArray = names
				shorterArray = self.findNames 
			}

			for name in shorterArray {
				if longerArray.contains(name) {
					return true
				}
			}

			return false
		}
	}

	// Has a no. of NFTs in given path 
	pub struct HasNFTsInPath {
		pub let path: PublicPath 
		pub let threshold: Int 

		init(path: PublicPath , threshold: Int ) {
			self.path = path 
			self.threshold = threshold
		}

		pub fun verify(_ param: {String : AnyStruct}) : Bool {
			if self.threshold == 0 {
				return true
			}

			let user : Address = param["address"]! as! Address 

			let cap = getAccount(user).getCapability<&{NonFungibleToken.CollectionPublic}>(self.path)
			if !cap.check() {
				let mvCap = getAccount(user).getCapability<&{MetadataViews.ResolverCollection}>(self.path)
				if !mvCap.check() {
					return false
				}
				return mvCap.borrow()!.getIDs().length >= self.threshold
			} 
			return cap.borrow()!.getIDs().length >= self.threshold
		}
	}

	// Has given NFTs in given path with rarity  (can cache this with uuid) 
	pub struct HasNFTWithRarities {
		pub let path: PublicPath 
		pub let rarities: [MetadataViews.Rarity]
		access(self) let rarityIdentifiers: [String]

		// leave this here for caching in case useful, but people might be able to change rarity
		access(self) let cache : {UInt64 : Bool}

		init(path: PublicPath , rarities: [MetadataViews.Rarity]) {
			self.path = path 
			self.rarities = rarities
			let rarityIdentifiers : [String] = [] 
			for r in rarities {
				let rI = r.description ?? "" 
				if r.score != nil {
					rI.concat(r.score!.toString())
				}
				if r.max != nil {
					rI.concat(r.max!.toString())
				}
				rarityIdentifiers.append(rI)
			}
			self.rarityIdentifiers = rarityIdentifiers 
			self.cache = {}
		}

		access(self) fun rarityToIdentifier(_ r: MetadataViews.Rarity) : String {
				let rI = r.description ?? "" 
				if r.score != nil {
					rI.concat(r.score!.toString())
				}
				if r.max != nil {
					rI.concat(r.max!.toString())
				}
				return rI
		}

		pub fun verify(_ param: {String : AnyStruct}) : Bool {
			if self.rarities.length == 0 {
				return true
			}

			let user : Address = param["address"]! as! Address 

			let mvCap = getAccount(user).getCapability<&{MetadataViews.ResolverCollection}>(self.path)
			if !mvCap.check() {
				return false
			}
			let ref = mvCap.borrow()!

			for id in ref.getIDs() {
				let resolver = ref.borrowViewResolver(id: id)
				if let r = MetadataViews.getRarity(resolver) {
					if self.rarityIdentifiers.contains(self.rarityToIdentifier(r)) {
						return true
					}
				}
			}
			return false
		}

	}




}