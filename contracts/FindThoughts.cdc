import FindViews from "./FindViews.cdc"
import FindMarket from "./FindMarket.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FINDNFTCatalog from "./FINDNFTCatalog.cdc"
import FIND from "./FIND.cdc"
import Clock from "./Clock.cdc"

access(all) contract FindThoughts {

	pub event Published(id: UInt64, creator: Address, creatorName: String?, header: String, message: String, medias: [String], nfts:[FindMarket.NFTInfo], tags: [String], quoteOwner: Address?, quoteId: UInt64?)
	pub event Edited(id: UInt64, creator: Address, creatorName: String?, header: String, message: String, medias: [String], hide: Bool, tags: [String])
	pub event Deleted(id: UInt64, creator: Address, creatorName: String?, header: String, message: String, medias: [String], tags: [String])
	pub event Reacted(id: UInt64, by: Address, byName: String?, creator: Address, creatorName: String?, header: String, reaction: String?, totalCount: {String : Int})

	pub let CollectionStoragePath : StoragePath 
	pub let CollectionPublicPath : PublicPath 
	pub let CollectionPrivatePath : PrivatePath 

	access(all) struct ThoughtPointer {
		pub let cap: Capability<&FindThoughts.Collection{FindThoughts.CollectionPublic}>
		pub let id: UInt64 

		init(creator: Address, id: UInt64) {
			let cap = getAccount(creator).getCapability<&FindThoughts.Collection{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath)
			if !cap.check() {
				panic("creator's find thought capability is not valid. Creator : ".concat(creator.toString()))
			}
			self.cap = cap
			self.id = id 
		}

		access(all) borrowThoughtPublic() : &{ThoughtPublic}? {
			if self.cap.check() {
				let ref = self.cap.borrow()!
				if ref.contains(self.id) {
					return ref.borrowThoughtPublic(self.id)
				}
			}
			return nil
		}

		access(all) valid() : Bool {
			if self.borrowThoughtPublic() != nil {
				return true
			}
			return false
		}

		access(all) owner() : Address {
			return self.cap.address
		}
	}

	pub resource interface ThoughtPublic {
		pub let id: UInt64 
		pub let creator: Address 
		pub var header: String 
		pub var body: String 
		pub let created: UFix64 
		pub var lastUpdated: UFix64?
		pub let medias: [MetadataViews.Media]
		pub let nft: [FindViews.ViewReadPointer]
		pub var tags: [String]
		pub var reacted: {Address : String}
		pub var reactions: {String : Int}

		access(contract) fun internal_react(user: Address, reaction: String?) 
		access(all) getQuotedThought() : ThoughtPointer? 
		access(all) getHide() : Bool
	}

	pub resource Thought : ThoughtPublic , ViewResolver.Resolver {
		pub let id: UInt64 
		pub let creator: Address 
		pub var header: String 
		pub var body: String 
		pub let created: UFix64 
		pub var lastUpdated: UFix64?
		pub var tags: [String]
		// user : Reactions
		pub var reacted: {Address : String}
		// Reactions : Counts
		pub var reactions: {String : Int}

		// only one image is enabled at the moment
		pub let medias: [MetadataViews.Media]

		// These are here only for future extension
		pub let nft: [FindViews.ViewReadPointer]
		access(self) let stringTags: {String : String} 
		access(self) let scalars: {String : UFix64} 
		access(self) let extras: {String : AnyStruct} 

		init(creator: Address , header: String , body: String , created: UFix64, tags: [String], medias: [MetadataViews.Media], nft: [FindViews.ViewReadPointer], quote: ThoughtPointer?, stringTags: {String : String}, scalars : {String : UFix64}, extras: {String : AnyStruct} ) {
			self.id = self.uuid 
			self.creator = creator
			self.header = header
			self.body = body
			self.created = created
			self.lastUpdated = nil
			self.tags = tags
			self.medias = medias

			self.nft = nft
			self.stringTags = stringTags
			self.scalars = scalars
			extras["quote"] = quote
			extras["hidden"] = false
			self.extras = extras

			self.reacted = {}
			self.reactions = {}
		}

		destroy(){
			let address = self.owner?.address
			let medias : [String] = []
			for m in self.medias {
				medias.append(m.file.uri())
			}
			
			var name : String? = nil 
			if address != nil {
				name = FIND.reverseLookup(address!)
			}
			emit Deleted(id: self.id, creator: self.creator, creatorName: FIND.reverseLookup(self.creator), header: self.header, message: self.body, medias: medias, tags: self.tags)
		}

		access(all) getQuotedThought() : ThoughtPointer? {
			if let r = self.extras["quote"] {
				return r as! ThoughtPointer
			}
			return nil
		}

		access(all) getHide() : Bool {
			if let r = self.extras["hidden"] {
				return r as! Bool
			}
			return false
		}

		access(all) hide(_ hide: Bool) {
			self.extras["hidden"] = hide
			let medias : [String] = []
			for m in self.medias {
				medias.append(m.file.uri())
			}
			emit Edited(id: self.id, creator: self.creator, creatorName: FIND.reverseLookup(self.creator), header: self.header, message: self.body, medias: medias, hide: hide, tags: self.tags)
		}

		access(all) edit(header: String , body: String, tags: [String]) {
			self.header = header 
			self.body = body 
			self.tags = tags 
			let address = self.owner!.address
			let medias : [String] = []
			for m in self.medias {
				medias.append(m.file.uri())
			}
			self.lastUpdated = Clock.time()
			emit Edited(id: self.id, creator: address, creatorName: FIND.reverseLookup(address), header: self.header, message: self.body, medias: medias, hide: self.getHide(), tags: self.tags)
		}

		// To withdraw reaction, pass in nil
		access(contract) fun internal_react(user: Address, reaction: String?) {
			let owner = self.owner!.address
			if let previousReaction = self.reacted[user] {
				// reaction here cannot be nil, therefore we can ! 
				self.reactions[previousReaction] = self.reactions[previousReaction]! - 1
				if self.reactions[previousReaction]! == 0 {
					self.reactions.remove(key: previousReaction)
				}
			} 

			self.reacted[user] = reaction
			
			if reaction != nil {
				var reacted = self.reactions[reaction!] ?? 0
				reacted = reacted + 1
				self.reactions[reaction!] = reacted
			}

			emit Reacted(id: self.id, by: user, byName: FIND.reverseLookup(user), creator: owner, creatorName: FIND.reverseLookup(owner), header: self.header, reaction: reaction, totalCount: self.reactions)
		}

        access(all) getViews(): [Type] {
			return [
				Type<MetadataViews.Display>()
			]
		}

		access(all) resolveView(_ type: Type) : AnyStruct? {
			switch type {
			
				case Type<MetadataViews.Display>(): 

					let content = self.body.concat("  -- FIND Thought by ").concat(FIND.reverseLookup(self.owner!.address) ?? self.owner!.address.toString())

					return MetadataViews.Display(
						name: self.header, 
						description: content,
						thumbnail: self.medias[0].file
					)

			}
			return nil
		}
	}

	pub resource interface CollectionPublic {
		access(all) contains(_ id: UInt64) : Bool 
		access(all) getIDs() : [UInt64]
		access(all) borrowThoughtPublic(_ id: UInt64) : &FindThoughts.Thought{FindThoughts.ThoughtPublic} 
	}

	pub resource Collection : CollectionPublic, ViewResolver.ResolverCollection {
		access(self) let ownedThoughts : @{UInt64 : FindThoughts.Thought}

		access(self) let sequence : [UInt64] 

		init() {
			self.ownedThoughts <- {}
			self.sequence = []
		}

		destroy() {
			destroy self.ownedThoughts
		}

		access(all) contains(_ id: UInt64) : Bool {
			return self.ownedThoughts.containsKey(id)
		}

		access(all) getIDs() : [UInt64] {
			return self.ownedThoughts.keys
		}

		access(all) borrow(_ id: UInt64) : &FindThoughts.Thought {
			pre{
				self.ownedThoughts.containsKey(id) : "Cannot borrow Thought with ID : ".concat(id.toString())
			}
			return (&self.ownedThoughts[id] as &FindThoughts.Thought?)!
		}

		access(all) borrowThoughtPublic(_ id: UInt64) : &FindThoughts.Thought{FindThoughts.ThoughtPublic} {
			pre{
				self.ownedThoughts.containsKey(id) : "Cannot borrow Thought with ID : ".concat(id.toString())
			}
			return (&self.ownedThoughts[id] as &FindThoughts.Thought?)!
		}

        access(all) borrowViewResolver(id: UInt64): &{ViewResolver.Resolver} {
			pre{
				self.ownedThoughts.containsKey(id) : "Cannot borrow Thought with ID : ".concat(id.toString())
			}
			return (&self.ownedThoughts[id] as &FindThoughts.Thought?)!
		}

		// TODO : Restructure this to take structs , and declare the structs in Trxn.  And identify IPFS and url
		// So take pointer, thought pointer and media
		access(all) access(all)lish(header: String , body: String , tags: [String], media: MetadataViews.Media?, nftPointer: FindViews.ViewReadPointer?, quote: FindThoughts.ThoughtPointer?) {
			let medias : [MetadataViews.Media] = []
			let m : [String] = []
			if media != nil {
				medias.append(media!)
				m.append(media!.file.uri())
			}
			let address = self.owner!.address

			let nfts : [FindMarket.NFTInfo] = []
			let extra : {String : AnyStruct} = {}
			if nftPointer != nil {
				let rv = nftPointer!.getViewResolver()
				nfts.append(FindMarket.NFTInfo(rv, id: nftPointer!.id, detail: true))
			}

			let thought <- create Thought(creator: address, header: header , body: body , created: Clock.time(), tags: tags, medias: medias, nft: [], quote: quote, stringTags: {}, scalars : {}, extras: extra)

			self.sequence.append(thought.uuid)

			let creatorName = FIND.reverseLookup(address)

			emit Published(id: thought.id ,creator: address, creatorName: creatorName , header: header, message: body, medias: m, nfts: nfts, tags: tags, quoteOwner: quote?.owner(), quoteId: quote?.id)

			self.ownedThoughts[thought.uuid] <-! thought
		}

		access(all) delete(_ id: UInt64) {
			pre{
				self.ownedThoughts.containsKey(id) : "Does not contains Thought with ID : ".concat(id.toString())
			}

			let thought <- self.ownedThoughts.remove(key: id)!
			self.sequence.remove(at: self.sequence.firstIndex(of: id)!)

			let address = self.owner!.address
			destroy thought
		}

		access(all) react(user: Address, id: UInt64, reaction: String?) {
			let cap = FindThoughts.getFindThoughtsCapability(user)
			let ref = cap.borrow() ?? panic("Cannot borrow reference to Find Thoughts Collection from user : ".concat(user.toString()))

			let thought = ref.borrowThoughtPublic(id)
			thought.internal_react(user: self.owner!.address, reaction: reaction)
		}

		access(all) hide(id: UInt64, hide: Bool) {
			let thought = self.borrow(id)
			thought.hide(hide)
		}

	}

	access(all) createEmptyCollection() : @FindThoughts.Collection {
		return <- create Collection()
	}

	access(all) getFindThoughtsCapability(_ user: Address) : Capability<&FindThoughts.Collection{FindThoughts.CollectionPublic}> {
		return getAccount(user).getCapability<&FindThoughts.Collection{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath)
	}

	init(){
		self.CollectionStoragePath = /storage/FindThoughts 
		self.CollectionPublicPath = /public/FindThoughts 
		self.CollectionPrivatePath = /private/FindThoughts 
	}

}
 
 