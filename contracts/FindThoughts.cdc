import FindViews from "./FindViews.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FINDNFTCatalog from "./FINDNFTCatalog.cdc"
import FIND from "./FIND.cdc"
import Clock from "./Clock.cdc"

pub contract FindThoughts {

	pub event Published(id: UInt64, creator: Address, creatorName: String?, header: String, message: String, medias: [String], tags: [String])
	pub event Edited(id: UInt64, creator: Address, creatorName: String?, header: String, message: String, medias: [String], tags: [String])
	pub event Deleted(id: UInt64, creator: Address, creatorName: String?, header: String, message: String, medias: [String], tags: [String])
	pub event Reacted(id: UInt64, by: Address, byName: String?, creator: Address, creatorName: String?, header: String, reaction: String?, totalCount: {String : Int})

	pub let CollectionStoragePath : StoragePath 
	pub let CollectionPublicPath : PublicPath 
	pub let CollectionPrivatePath : PrivatePath 

	pub struct FindThoughtPointer {
		pub let creator: Address 
		pub let id: UInt64 

		init(creator: Address, id: UInt64) {
			self.creator = creator 
			self.id = id 
		}

		pub fun borrowThoughtPublic() : &{ThoughtPublic}? {
			let cap = getAccount(self.creator).getCapability<&FindThoughts.Collection{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath)
			if cap.check() {
				let ref = cap.borrow()!
				if ref.contains(self.id) {
					return ref.borrowThoughtPublic(self.id)
				}
			}
			return nil
		}

		pub fun valid() : Bool {
			if self.borrowThoughtPublic() != nil {
				return true
			}
			return false
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
		pub fun getQuotedThought() : FindThoughtPointer? 
	}

	pub resource Thought : ThoughtPublic , MetadataViews.Resolver {
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

		init(creator: Address , header: String , body: String , created: UFix64, tags: [String], medias: [MetadataViews.Media], nft: [FindViews.ViewReadPointer], quote: FindThoughtPointer?, stringTags: {String : String}, scalars : {String : UFix64}, extras: {String : AnyStruct} ) {
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
			self.extras = extras
			extras["quote"] = quote

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

		pub fun getQuotedThought() : FindThoughtPointer? {
			if let r = self.extras["quote"] {
				return r as! FindThoughtPointer
			}
			return nil
		}

		pub fun edit(header: String , body: String, tags: [String]) {
			self.header = header 
			self.body = body 
			self.tags = tags 
			let address = self.owner!.address
			let medias : [String] = []
			for m in self.medias {
				medias.append(m.file.uri())
			}
			self.lastUpdated = Clock.time()
			emit Edited(id: self.id, creator: address, creatorName: FIND.reverseLookup(address), header: self.header, message: self.body, medias: medias, tags: self.tags)
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

        pub fun getViews(): [Type] {
			return [
				Type<MetadataViews.Display>()
			]
		}

		pub fun resolveView(_ type: Type) : AnyStruct? {
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
		pub fun contains(_ id: UInt64) : Bool 
		pub fun getIDs() : [UInt64]
		pub fun borrowThoughtPublic(_ id: UInt64) : &FindThoughts.Thought{FindThoughts.ThoughtPublic} 
	}

	pub resource Collection : CollectionPublic, MetadataViews.ResolverCollection {
		access(self) let ownedThoughts : @{UInt64 : FindThoughts.Thought}

		access(self) let sequence : [UInt64] 

		init() {
			self.ownedThoughts <- {}
			self.sequence = []
		}

		destroy() {
			destroy self.ownedThoughts
		}

		pub fun contains(_ id: UInt64) : Bool {
			return self.ownedThoughts.containsKey(id)
		}

		pub fun getIDs() : [UInt64] {
			return self.ownedThoughts.keys
		}

		pub fun borrow(_ id: UInt64) : &FindThoughts.Thought {
			pre{
				self.ownedThoughts.containsKey(id) : "Cannot borrow Thought with ID : ".concat(id.toString())
			}
			return (&self.ownedThoughts[id] as &FindThoughts.Thought?)!
		}

		pub fun borrowThoughtPublic(_ id: UInt64) : &FindThoughts.Thought{FindThoughts.ThoughtPublic} {
			pre{
				self.ownedThoughts.containsKey(id) : "Cannot borrow Thought with ID : ".concat(id.toString())
			}
			return (&self.ownedThoughts[id] as &FindThoughts.Thought?)!
		}

        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
			pre{
				self.ownedThoughts.containsKey(id) : "Cannot borrow Thought with ID : ".concat(id.toString())
			}
			return (&self.ownedThoughts[id] as &FindThoughts.Thought?)!
		}

		pub fun publish(header: String , body: String , tags: [String], mediaHash: String?, mediaType: String?, quoteNFTOwner: Address?, quoteNFTType: String?, quoteNFTId: UInt64?, quoteCreator: Address?, quoteId: UInt64?) {
			let medias : [MetadataViews.Media] = []
			if mediaHash != nil {
				let media = MetadataViews.Media(file: MetadataViews.IPFSFile(cid:mediaHash!, path: nil), mediaType: mediaType!)
				medias.append(media)
			}
			let address = self.owner!.address

			var nft : FindViews.ViewReadPointer? = nil 
			if quoteNFTOwner != nil {
				let path = FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: quoteNFTType!)?.publicPath ?? panic("This nft type is not supported by NFT Catalog. Type : ".concat(quoteNFTType!))
				let cap = getAccount(quoteNFTOwner!).getCapability<&{MetadataViews.ResolverCollection}>(path)
				nft = FindViews.ViewReadPointer(cap: cap, id: quoteNFTId!)
			}

			// If nft is not nil, we try to get the thumbnail and store it.  
			if nft != nil {
				medias.append(MetadataViews.Media(file: nft!.getDisplay().thumbnail, mediaType: "image")) // assume that it is image for all thumbnail
			}

			var thoughtPointer : FindThoughtPointer? = nil
			if quoteCreator != nil {
				thoughtPointer = FindThoughtPointer(creator: quoteCreator!, id: quoteId!)
			}
			let thought <- create Thought(creator: address, header: header , body: body , created: Clock.time(), tags: tags, medias: medias, nft: [], quote: thoughtPointer, stringTags: {}, scalars : {}, extras: {})

			self.sequence.append(thought.uuid)

			let creatorName = FIND.reverseLookup(address)
			let m : [String] = []
			for media in medias {
				m.append(media.file.uri())
			}
			emit Published(id: thought.id ,creator: address, creatorName: creatorName , header: header, message: body, medias: m, tags: tags)

			self.ownedThoughts[thought.uuid] <-! thought
		}

		pub fun delete(_ id: UInt64) {
			pre{
				self.ownedThoughts.containsKey(id) : "Does not contains Thought with ID : ".concat(id.toString())
			}

			let thought <- self.ownedThoughts.remove(key: id)!
			self.sequence.remove(at: self.sequence.firstIndex(of: id)!)

			let address = self.owner!.address
			destroy thought
		}

		pub fun react(user: Address, id: UInt64, reaction: String?) {
			let cap = FindThoughts.getFindThoughtsCapability(user)
			let ref = cap.borrow() ?? panic("Cannot borrow reference to Find Thoughts Collection from user : ".concat(user.toString()))

			let thought = ref.borrowThoughtPublic(id)
			thought.internal_react(user: self.owner!.address, reaction: reaction)
		}

	}

	pub fun createEmptyCollection() : @FindThoughts.Collection {
		return <- create Collection()
	}

	pub fun getFindThoughtsCapability(_ user: Address) : Capability<&FindThoughts.Collection{FindThoughts.CollectionPublic}> {
		return getAccount(user).getCapability<&FindThoughts.Collection{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath)
	}

	init(){
		self.CollectionStoragePath = /storage/FindThoughts 
		self.CollectionPublicPath = /public/FindThoughts 
		self.CollectionPrivatePath = /private/FindThoughts 
	}

}
 
