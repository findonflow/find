import FindThoughts from "../contracts/FindThoughts.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String) : [Thought] {
	let address = FIND.resolve(user)
	if address == nil {
		return []
	}
	let account = getAccount(address!) 
	let cap = account.getCapability<&{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath) 
	if !cap.check() {
		return []
	}
	let ref = cap.borrow()! 
	let thoughts : [Thought] = [] 
	for id in ref.getIDs() {
		let t = ref.borrowThoughtPublic(id) 
		thoughts.append(Thought(t))
	}
	return thoughts
}


pub struct Thought {
		pub let id: UInt64 
		pub let creator: Address 
		pub let creatorName: String? 
		pub var header: String 
		pub var body: String 
		pub let created: UFix64 
		pub var lastUpdated: UFix64?
		pub let medias: {String : String}
		pub let nft: [FindMarket.NFTInfo]
		pub var tags: [String]
		pub var reacted: {Address : String}
		pub var reactions: {String : Int}

	init(_ t: &{FindThoughts.ThoughtPublic}) {
			self.id = t.id 
			self.creator = t.creator 
			self.creatorName = FIND.reverseLookup(t.creator)
			self.header = t.header 
			self.body = t.body 
			self.created = t.created 
			self.lastUpdated = t.lastUpdated 
			let medias : {String : String} = {}
			for m in t.medias {
				medias[m.file.uri()] = m.mediaType
			}
			self.medias = medias 
			let nft : [FindMarket.NFTInfo] = [] 
			for n in t.nft {
				let vr = n.getViewResolver() 
				nft.append(FindMarket.NFTInfo(vr, id: n.id, detail: true))
			}
			self.nft = nft 
			self.tags = t.tags
			self.reacted = t.reacted
			self.reactions = t.reactions
		
	}
}

pub fun checkSameContract(collection: Type, nft: Type) : Bool {
	let colType = collection.identifier
	let croppedCol = colType.slice(from: 0 , upTo : colType.length - "collection".length)
	let nftType = nft.identifier
	let croppedNft = nftType.slice(from: 0 , upTo : nftType.length - "nft".length)
	if croppedCol == croppedNft {
		return true
	}
	return false
}
