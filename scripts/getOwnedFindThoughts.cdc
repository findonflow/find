import FindThoughts from "../contracts/FindThoughts.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(address: Address) : [Thought] {
	let thoughts : [Thought] = [] 


		let account = getAccount(address) 
		let cap = account.getCapability<&{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath) 
		if !cap.check() {
			return []
		}
		let ref = cap.borrow()! 
		for id in ref.getIDs() {
			let t = ref.borrowThoughtPublic(id) 
			thoughts.append(getThought(t, withQuote: true))
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
	pub var header: String?
	pub var body: String?
	pub let created: UFix64? 
	pub var lastUpdated: UFix64?
	pub let medias: {String : String}
	pub let nft: [FindMarket.NFTInfo]
	pub var tags: [String]
	pub var reacted: {String : [User]}
	pub var reactions: {String : Int}
	pub var reactedUsers: {String : [String]}
	pub var quotedThought: Thought?
	pub var hidden: Bool?

	init(id: UInt64 , creator: Address , creatorName: String? , creatorProfileName: String? , creatorAvatar: String? , header: String? , body: String? , created: UFix64? , lastUpdated: UFix64?, medias: {String : String}, nft: [FindMarket.NFTInfo], tags: [String], reacted: {String : [User]}, reactions: {String : Int}, reactedUsers: {String : [String]}, quotedThought: Thought?, hidden: Bool?) {
		self.id = id
		self.creator = creator
		self.creatorName = creatorName
		self.creatorProfileName = creatorProfileName
		self.creatorAvatar = creatorAvatar
		self.header = header
		self.body = body
		self.created = created
		self.lastUpdated = lastUpdated
		self.medias = medias
		self.nft = nft
		self.tags = tags
		self.reacted = reacted
		self.reactions = reactions
		self.reactedUsers = reactedUsers
		self.quotedThought = quotedThought
		self.hidden = hidden
	}
}

pub fun getThought(_ t: &{FindThoughts.ThoughtPublic}, withQuote: Bool) : Thought {

		var creatorProfileName : String? = nil
		var creatorAvatar : String? = nil 
		let profileCap = getAccount(t.creator).getCapability<&{Profile.Public}>(Profile.publicPath)
		if profileCap.check() {
			creatorProfileName = profileCap.borrow()!.getName()
			creatorAvatar = profileCap.borrow()!.getAvatar()
		}

		let medias : {String : String} = {}
		for m in t.medias {
			medias[m.file.uri()] = m.mediaType
		}

		let nft : [FindMarket.NFTInfo] = [] 
		for n in t.nft {
			let vr = n.getViewResolver() 
			nft.append(FindMarket.NFTInfo(vr, id: n.id, detail: true))
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

		var quotedThought : Thought? = nil 
		if withQuote {
			if let p = t.getQuotedThought() {
				if let ref = p.borrowThoughtPublic() {
					quotedThought = getThought(ref, withQuote: false)
				} else {
					let creator = p.owner()
					var qCreatorProfileName : String? = nil
					var qCreatorAvatar : String? = nil 
					let qProfileCap = getAccount(creator).getCapability<&{Profile.Public}>(Profile.publicPath)
					if qProfileCap.check() {
						qCreatorProfileName = qProfileCap.borrow()!.getName()
						qCreatorAvatar = qProfileCap.borrow()!.getAvatar()
					}

					quotedThought = Thought(
						id: p.id , 
						creator: creator  , 
						creatorName: FIND.reverseLookup(creator) , 
						creatorProfileName: qCreatorProfileName , 
						creatorAvatar: qCreatorAvatar, 
						header: nil, 
						body: nil , 
						created: nil, 
						lastUpdated: nil, 
						medias: {}, 
						nft: [], 
						tags: [], 
						reacted: {}, 
						reactions: {}, 
						reactedUsers: {},
						quotedThought: nil, 
						hidden: false
					)	
				}
			}
		}

		return Thought(
			id: t.id , 
			creator: t.creator  , 
			creatorName: FIND.reverseLookup(t.creator) , 
			creatorProfileName: creatorProfileName , 
			creatorAvatar: creatorAvatar, 
			header: t.header , 
			body: t.body , 
			created: t.created, 
			lastUpdated: t.lastUpdated, 
			medias: medias, 
			nft: nft, 
			tags: t.tags, 
			reacted: reacted, 
			reactions: t.reactions, 
			reactedUsers: reactedUsers,
			quotedThought: quotedThought, 
			hidden: t.getHide()
		)

}
