import FindThoughts from "../contracts/FindThoughts.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(addresses: [Address], ids: [UInt64]) : [Thought] {
	let thoughts : [Thought] = [] 

	for i, address in addresses {
		let account = getAccount(address) 
		let cap = account.getCapability<&{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath) 
		if !cap.check() {
			continue
		}
		let ref = cap.borrow()! 
		let t = ref.borrowThoughtPublic(ids[i]) 
		var profile : &{Profile.Public}? = nil 
		let profileCap = getAccount(address).getCapability<&{Profile.Public}>(Profile.publicPath)
		if profileCap.check() {
			profile = profileCap.borrow()!
		}
		thoughts.append(Thought(t, profile: profile))
		
	}
	return thoughts
}

pub struct User {
	pub var name: String?
	pub let address: Address 
	pub let findName: String? 
	pub var avatar: String? 
	pub let reaction: String

	init(address: Address, reaction: String){
		self.name = nil
		self.findName = FIND.reverseLookup(address)
		self.avatar = nil
		self.reaction = reaction
		self.address = address 
		let profileCap = getAccount(address).getCapability<&{Profile.Public}>(Profile.publicPath)
		if profileCap.check() {
			let p = profileCap.borrow()!
			self.name = p.getName()
			self.avatar = p.getAvatar()
		}	
	}
}

pub struct Thought {
	pub let id: UInt64 
	pub let creator: Address 
	pub let creatorName: String? 
	pub var creatorProfileName: String? 
	pub var creatorAvatar: String? 
	pub var header: String 
	pub var body: String 
	pub let created: UFix64 
	pub var lastUpdated: UFix64?
	pub let medias: {String : String}
	pub let nft: [FindMarket.NFTInfo]
	pub var tags: [String]
	pub var reacted: {String : [User]}
	pub var reactions: {String : Int}
	pub var reactedUsers: {String : [String]}

	init(_ t: &{FindThoughts.ThoughtPublic}, profile: &{Profile.Public}?) {
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
		self.reactions = t.reactions
		self.creatorProfileName = nil
		self.creatorAvatar = nil 
		if profile != nil {
			self.creatorProfileName = profile!.getName()
			self.creatorAvatar = profile!.getAvatar()
		}
		let reacted : {String : [User]} = {}
		let reactedUsers : {String :[String]} = {}
		for user in t.reacted.keys {
			let reaction = t.reacted[user]!
			let allReacted = reacted[reaction] ?? []
			let u = User(address: user, reaction: reaction)
			allReacted.append(u)
			reacted[reaction] = allReacted

			let preReactedUser = reactedUsers[reaction] ?? []
			preReactedUser.append(u.name ?? u.address.toString())
			reactedUsers[reaction] = preReactedUser
		}
		self.reacted = reacted
		self.reactedUsers = reactedUsers
	}
}
