import FindViews from "./FindViews.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FIND from "./FIND.cdc"
import Clock from "./Clock.cdc"

pub contract FindThoughts {

	pub event Published(from: Address, name: String?, header: String, message: String, medias: [String], tags: [String])
	pub event Edited(from: Address, name: String?, header: String, message: String, medias: [String], tags: [String])
	pub event Deleted(from: Address, name: String?, header: String, message: String, medias: [String], tags: [String])
	pub event Reacted(by: Address, byName: String?, owner: Address, name: String?, header: String, reaction: String?, totalCount: {String : Int})

	pub let CollectionStoragePath : StoragePath 
	pub let CollectionPublicPath : PublicPath 
	pub let CollectionPrivatePath : PrivatePath 

	pub resource interface ThoughtPublic {
		pub let id: UInt64 
		pub var header: String 
		pub var body: String 
		pub let created: UFix64 
		pub var lastUpdated: UFix64?
		pub let medias: [MetadataViews.Media]
		pub let nft: [FindViews.ViewReadPointer]
		pub var tags: [String]
		pub var reacted: {Address : String}
		pub var reactions: {String : Int}

		access(contract) fun internal_react(user: Address, reaction: String) 
	}

	pub resource Thought : ThoughtPublic , MetadataViews.Resolver {
		pub let id: UInt64 
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
		pub let stringTags: {String : String} 
		pub let scalars: {String : UFix64} 
		pub let extras: {String : AnyStruct} 

		init(header: String , body: String , created: UFix64, tags: [String], medias: [MetadataViews.Media], nft: [FindViews.ViewReadPointer], stringTags: {String : String}, scalars : {String : UFix64}, extras: {String : AnyStruct} ) {
			self.id = self.uuid 
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

			self.reacted = {}
			self.reactions = {}
		}

		destroy(){
			let address = self.owner!.address
			let medias : [String] = []
			for m in self.medias {
				medias.append(m.file.uri())
			}
			emit Deleted(from: address, name: FIND.reverseLookup(address), header: self.header, message: self.body, medias: medias, tags: self.tags)
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
			emit Edited(from: address, name: FIND.reverseLookup(address), header: self.header, message: self.body, medias: medias, tags: self.tags)
		}

		// To withdraw reaction, pass in empty string ""
		access(contract) fun internal_react(user: Address, reaction: String) {
			let owner = self.owner!.address
			if let previousReaction = self.reacted[user] {
				// reaction here cannot be nil
				self.reactions[previousReaction] = self.reactions[previousReaction]! - 1
				if self.reactions[previousReaction]! == 0 {
					self.reactions.remove(key: previousReaction)
				}
			} 

			if reaction != "" {
				self.reacted[user] = reaction
				var reacted = self.reactions[reaction] ?? 0
				reacted = reacted + 1
				self.reactions[reaction] = reacted
			}
			var r : String? = reaction 
			if r == "" {
				r = nil
			}
			emit Reacted(by: user, byName: FIND.reverseLookup(user), owner: owner, name: FIND.reverseLookup(owner), header: self.header, reaction: r, totalCount: self.reactions)
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

		pub fun publish(header: String , body: String , created: UInt64, tags: [String], media: MetadataViews.Media) {
			let thought <- create Thought(header: header , body: body , created: Clock.time(), tags: tags, medias: [media], nft: [], stringTags: {}, scalars : {}, extras: {})

			self.sequence.append(thought.uuid)

			let address = self.owner!.address
			emit Published(from: address, name: FIND.reverseLookup(address), header: header, message: body, medias: [media.file.uri()], tags: tags)

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

		pub fun react(user: Address, id: UInt64, reaction: String) {
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
 
