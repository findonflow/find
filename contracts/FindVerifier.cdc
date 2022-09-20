import FLOAT from "../contracts/standard/FLOAT.cdc"

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







}