// SPDX-License-Identifier: MIT

/*
Welcome to the Wearables contract for Doodles2

A wearable is an equipment that can be equipped  to a Doodle2
*/

import NonFungibleToken from "../standard/NonFungibleToken.cdc"
import FungibleToken from "../standard/FungibleToken.cdc"
import MetadataViews from "../standard/MetadataViews.cdc"
import Templates from "./Templates.cdc"
import FindUtils from "../FindUtils.cdc"

pub contract Wearables: NonFungibleToken {

	//Holds the total supply of wearables ever minted
	pub var totalSupply: UInt64

	pub event ContractInitialized()

	//emitted when a NFT is withdrawn as defined in the NFT standard
	pub event Withdraw(id: UInt64, from: Address?)

	//emitted when a NFT is deposited as defined in the NFT standard
	pub event Deposit(id: UInt64, to: Address?)

	//emitted when an Wearable is minted either as part of dooplication or later as part of batch minting, note that context and its fields will vary according to when/how it was minted
	pub event Minted(id:UInt64, address:Address, name: String, thumbnail:String, set: String, position: String, template: String, tags:[String], templateId:UInt64, context: {String : String})

	//standard paths in the nft metadata standard
	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath


	// SETS

	// sets is a registry that is stored in the contract for ease of reuse and also to be able to count the mints of a set an retire it
	pub event SetRegistered(id:UInt64, name:String)
	pub event SetRetired(id:UInt64)

	//a registry of sets to group Wearables
	pub let sets: {UInt64 : Set}

	//the definition of a set, a data structure that is Retriable and Editionable
	pub struct Set : Templates.Retirable, Templates.Editionable, Templates.RoyaltyHolder {
		pub let id:UInt64
		pub let name: String
		pub var active:Bool
		pub let royalties: [Templates.Royalty]
		pub let creator : String
		access(self) let extra: {String : AnyStruct}

		init(id:UInt64, name:String, creator: String, royalties: [Templates.Royalty]) {
			self.id=id
			self.name=name
			self.active=true
			self.royalties=royalties
			self.creator=creator
			self.extra={}
		}

		pub fun getCreator() : String {
			return self.creator
		}


		pub fun getClassifier() : String{
			return "set"
		}

		pub fun getCounterSuffix() : String {
			return self.name
		}

		pub fun getContract() : String {
			return "wearable"
		}
	}

	access(account) fun addSet(_ set: Wearables.Set) {
		pre{
			!self.sets.containsKey(set.id) : "Set is already registered. Id : ".concat(set.id.toString())
		}
		emit SetRegistered(id:set.id, name:set.name)
		self.sets[set.id] = set
	}

	access(account) fun retireSet(_ id:UInt64) {
		pre{
			self.sets.containsKey(id) : "Set does not exist. Id : ".concat(id.toString())
		}
		emit SetRetired(id:id)
		self.sets[id]!.enable(false)
	}

	// POSITION
	// a concept that tells where on a Doodle2 a wearable can be equipped.

	pub event PositionRegistered(id:UInt64, name:String, classifiers:[String])
	pub event PositionRetired(id:UInt64)

	pub let positions: {UInt64 : Position}

	//the definition of a position, a data structure that is Retriable and Editionable
	pub struct Position : Templates.Retirable, Templates.Editionable{
		pub let id:UInt64
		pub let name: String
		pub let classifiers: [String]
		pub var active:Bool
		access(self) let extra: {String : AnyStruct}

		init(id:UInt64, name:String) {
			self.id=id
			self.name=name
			self.classifiers=[]
			self.active=true
			self.extra={}
		}

		pub fun getName(_ index: Int) :String {
			if self.classifiers.length==0 {
				return self.name
			}

			let classifier=self.classifiers[index]
			return self.name.concat("_").concat(classifier)
		}

		pub fun getPositionCount() :Int{
			let length=self.classifiers.length
			if length==0 {
				return 1
			}
			return length
		}

		pub fun getClassifier() :String {
			return "position"
		}

		pub fun getCounterSuffix() : String {
			return self.name
		}

		pub fun getContract() : String {
			return "wearable"
		}
	}

	access(account) fun addPosition(_ p: Wearables.Position) {
		pre{
			!self.positions.containsKey(p.id) : "Position is already registered. Id : ".concat(p.id.toString())
		}
		emit PositionRegistered(id:p.id, name:p.name, classifiers:p.classifiers)
		self.positions[p.id] = p
	}

	access(account) fun retirePosition(_ id:UInt64) {
		pre{
			self.positions.containsKey(id) : "Position does not exist. Id : ".concat(id.toString())
		}
		emit PositionRetired(id:id)
		self.positions[id]!.enable(false)
	}

	// TEMPLATE
	// a template is a preregistered set of values that a Wearable can get when it is minted, it is then copied into the NFT for provenance

	//these events are there to track changes internally for registers that are needed to make this contract work
	pub event TemplateRegistered(id:UInt64, set: UInt64, position: UInt64, name: String, tags:[String])
	pub event TemplateRetired(id:UInt64)

	//a registry of templates that defines how a Wearable can be minted
	pub let templates: {UInt64 : Template}

	//the definition of a template, a data structure that is Retriable and Editionable
	pub struct Template : Templates.Retirable, Templates.Editionable {
		pub let id:UInt64
		pub let name: String
		pub let set: UInt64
		pub let position: UInt64
		pub let tags: [Tag]
		pub let thumbnail: MetadataViews.Media
		pub let image: MetadataViews.Media
		pub var active: Bool
		pub let hidden: Bool
		pub let plural: Bool
		access(self) let extra: {String : AnyStruct}

		init(id:UInt64, set: UInt64, position: UInt64, name: String, tags:[Tag], thumbnail: MetadataViews.Media, image: MetadataViews.Media, hidden: Bool, plural: Bool) {
			self.id=id
			self.set=set
			self.position=position
			self.name=name

			//the first tag should be prefixed to template name for the name of the wearable, the other tags are for labling
			self.tags=tags
			self.thumbnail=thumbnail
			self.image=image
			self.active=true
			self.plural=plural
			self.hidden=hidden
			self.extra={}
		}

		pub fun getTags() : [String] {
			let t : [String] = []
			for tag in self.tags {
				t.append(tag.getCounterSuffix())
			}
			return t
		}

		pub fun getPlural() : Bool {
			return self.plural
		}

		pub fun getHidden() : Bool {
				return self.hidden
		}

		pub fun getIdentifier() : String {
			return self.name
		}

		pub fun getClassifier() :String {
			return "template"
		}

		// Trim is not a unique identifier here
		pub fun getCounterSuffix() : String {
			return self.name
		}

		pub fun getContract() : String {
			return "wearable"
		}

		pub fun getPositionName(_ index:Int) : String {
			return Wearables.positions[self.position]!.getName(index)
		}

		pub fun getPosition() : Wearables.Position {
			return Wearables.positions[self.position]!
		}

		pub fun getSetName() : String {
			return Wearables.sets[self.set]!.name
		}

		pub fun getSet() : Wearables.Set {
			return Wearables.sets[self.set]!
		}

		pub fun getRoyalties() : [MetadataViews.Royalty] {
			return Wearables.sets[self.set]!.getRoyalties()
		}

		access(contract) fun createTagEditionInfo(_ edition: [UInt64]?) : [Templates.EditionInfo] {
			let editions : [Templates.EditionInfo] = []
			for i, t in self.tags {
				var ediNumber : UInt64? = nil
				if let e = edition {
					ediNumber = e[i]
				}
				editions.append(t.createEditionInfo(ediNumber))
			}
			return editions
		}
	}

	//A tag is a label for a Wearable, they can have many tags associated with them
	pub struct Tag : Templates.Editionable {
		pub let value : String
		access(self) let extra: {String : AnyStruct}

		init(value: String) {
			self.value=value
			self.extra={}
		}

		pub fun getValue() : String {
			return self.value
		}

		pub fun getCounterSuffix() : String {
			return self.value
		}

		// e.g. set , position
		pub fun getClassifier() : String {
			return "tag_".concat(self.value)
		}
		// e.g. character, wearable
		pub fun getContract() : String {
			return "wearable"
		}
	}

	access(account) fun addTemplate(_ t: Wearables.Template) {
		pre{
			self.sets.containsKey(t.set) : "Set does not exist. Name : ".concat(t.set.toString())
			self.positions.containsKey(t.position) : "Position does not exist. Name : ".concat(t.position.toString())
			!self.templates.containsKey(t.id) : "Template is already registered. Id : ".concat(t.id.toString())
		}
		emit TemplateRegistered(id: t.id, set: t.set, position: t.position, name: t.name, tags: t.getTags())
		self.templates[t.id] = t
	}

	access(account) fun retireTemplate(_ id:UInt64) {
		pre{
			self.templates.containsKey(id) : "Template does not exist. Name : ".concat(id.toString())
		}
		emit TemplateRetired(id: id)
		self.templates[id]!.enable(false)
	}

	// NFT
	// the NFT resource that is a Wearable.

	// A resource on flow https://developers.flow.com/cadence/language/resources is kind of like a struct just with way stronger semantics and rules around security

	pub resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver {

		//the unique id of a NFT, Wearables uses UUID so this id is unique across _all_ resources on flow
		pub let id:UInt64

		//The template that this Werable was made as
		pub let template: Template

		//a list of edition info used to present counters for the various types of data
		pub let editions: [Templates.EditionInfo]

		//stores who has interacted with this wearable, that
		pub let interactions: [Pointer]

		//internal counter to count how many times a wearable has been deposited.
		access(account) var nounce:UInt64

		//the royalties defined in this werable
		pub let royalties: MetadataViews.Royalties

		pub let context: { String: String}
		//stores extra data in case we need it for later iterations since we cannot add data
		pub let extra: {String : AnyStruct}

		init(
			template: Template,
			editions: [Templates.EditionInfo],
			context: {String:String}
		) {
			self.template=template
			self.interactions=[]
			self.nounce=0
			self.id=self.uuid
			self.royalties=MetadataViews.Royalties(template.getRoyalties())
			self.context=context
			self.extra={}
			self.editions=editions
		}

		pub fun getContext() : {String:String} {
			return self.context
		}

		pub fun getViews(): [Type] {
			return  [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.Traits>(),
			Type<MetadataViews.Editions>(),
			Type<Wearables.Metadata>()
			]
		}

		pub fun getTemplateActive() : Bool {
			let t = Wearables.templates[self.template.id]!
			return t.active
		}

		pub fun getPositionActive() : Bool {
			let p = self.template.getPosition()
			return p.active
		}

		pub fun getSetActive() : Bool {
			let s = self.template.getSet()
			return s.active
		}

		pub fun getActive(_ classifier: String) : Bool {
			switch classifier {

				case "wearable" :
					return self.getTemplateActive()

				case "template" :
					return self.getTemplateActive()

				case "position" :
					return self.getPositionActive()

				case "set" :
					return self.getSetActive()
			}
			return true
		}

		pub fun getLastInteraction() : Pointer? {
			if self.interactions.length == 0 {
				return nil
			}
			return self.interactions[self.interactions.length - 1]
		}

		access(account) fun equipped(owner: Address, characterId: UInt64) {
			if let lastInteraction = self.getLastInteraction() {
				if !lastInteraction.isNewInteraction(owner: owner, characterId: characterId) {
					return
				}
			}
			let interaction = Pointer(id: self.id, characterId: characterId, address: owner)
			self.interactions.append(interaction)
		}

		//the thumbnail is a png but the image is a SVG, it was decided after deployment that the svg is what we will use for thumbnail and ignore the image
		pub fun getThumbnail() : {MetadataViews.File} {
				let ipfsFile =self.template.image.file as! MetadataViews.IPFSFile
				let httpFile= MetadataViews.HTTPFile(url:"https://wcnft.mypinata.cloud/ipfs/".concat(ipfsFile.cid))
				return httpFile
		}

		pub fun getThumbnailUrl() : String{
			return self.getThumbnail().uri()
		}


		pub fun getName() : String {
			if self.template.tags.length == 0 {
				return self.template.name
			}
			let firstTag = self.template.tags[0].value
			let name=firstTag.concat(" ").concat(self.template.name)
			return name
		}


		pub fun getDescription() : String {
			var plural=self.template.getPlural()

			var first="This"
			var second="is"
			if plural {
				first="These"
				second="are"
			}

			return first.concat(" ").concat(self.getName()).concat(" ").concat(second).concat(" from the Doodles ").concat(self.template.getSetName()).concat(" collection.")

		}

		pub fun resolveView(_ view: Type): AnyStruct? {
			let description= self.getDescription()

			switch view {
			case Type<MetadataViews.Display>():
						return MetadataViews.Display(
					name: self.getName(),
					description: description,
					thumbnail: self.getThumbnail(),
				)

			case Type<MetadataViews.ExternalURL>():

				var networkPrefix=""
				if Wearables.account.address.toString() ==  "0x1e0493ee604e7598" {
					networkPrefix="test."
				}
				return MetadataViews.ExternalURL("https://".concat(networkPrefix).concat("find.xyz/").concat(self.owner!.address.toString()).concat("/collection/main/Wearables/").concat(self.id.toString()))

			case Type<MetadataViews.Royalties>():
				return self.royalties

			case Type<MetadataViews.NFTCollectionDisplay>():
				let externalURL = MetadataViews.ExternalURL("https://doodles.app")
				let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://wearable.xyz/assets/home/Wearablelogo.webp"), mediaType: "image")
				let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_banners/1535883931777892352/1661105339/1500x500"), mediaType: "image")
				return MetadataViews.NFTCollectionDisplay(name: "wearable", description: "Minting a Wearable triggers the catalyst moment of a big bang scenario. Generating a treasure that is designed to relate specifically to its holder.", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: { "discord": MetadataViews.ExternalURL("https://t.co/iY7AhEumR9"), "twitter" : MetadataViews.ExternalURL("https://twitter.com/WearableNFT")})

			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: Wearables.CollectionStoragePath,
				publicPath: Wearables.CollectionPublicPath,
				providerPath: Wearables.CollectionPrivatePath,
				publicCollection: Type<&Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(),
				publicLinkedType: Type<&Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(),
				providerLinkedType: Type<&Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(),
				createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Wearables.createEmptyCollection()})

			case Type<MetadataViews.Editions>() :

				let edition=self.editions[0]
				let active = self.getActive(edition.name)
				let editions : [MetadataViews.Edition] =[
					edition.getAsMetadataEdition(active)
				]
				return MetadataViews.Editions(editions)
			case Type<MetadataViews.Traits>():
				return MetadataViews.Traits(self.getAllTraitsMetadata())

			case Type<Wearables.Metadata>():
				return Metadata(templateId: self.template.id, setId:self.template.set, positionId: self.template.position)
			}

			return nil
		}

		access(account) fun increaseNounce() {
			self.nounce=self.nounce+1
		}

		pub fun getAllTraitsMetadata() : [MetadataViews.Trait] {
			var rarity : MetadataViews.Rarity? = nil

			let traits : [MetadataViews.Trait]= []

			traits.append(MetadataViews.Trait(
				name: "name",
				value: self.getName(),
					displayType: "string",
				rarity: rarity
			))

			traits.append(MetadataViews.Trait(
				name: "template",
				value: self.template.name,
					displayType: "string",
				rarity: rarity
			))

			traits.append(MetadataViews.Trait(
				name: "position",
				value: self.template.getPosition().name,
					displayType: "string",
				rarity: rarity
			))

			traits.append(MetadataViews.Trait(
				name: "set",
				value: self.template.getSetName(),
				displayType: "string",
				rarity: rarity
			))
			traits.append( MetadataViews.Trait(
					name: "set_creator",
					value: self.template.getSet().getCreator(),
					displayType: "string",
					rarity: rarity
				)
			)
			let edition=self.editions[0]
			let active = self.getActive(edition.name)
			var editionStatus="retired"
			if active {
				editionStatus="active"
			}
			traits.append( MetadataViews.Trait(
					name: "wearable_status",
					value: editionStatus,
					displayType: "string",
					rarity: rarity
				)
			)

			if self.interactions.length == 0 {
				traits.append(MetadataViews.Trait(name: "condition", value: "mint", displayType:"string", rarity:nil))
			}
			// Add tags as traits
			let tags = self.template.tags
			for tag in tags {
				traits.append(MetadataViews.Trait(name: "tag", value: tag.value, displayType:"string", rarity:nil))
			}

			let ctx = self.getContext()
			for key in ctx.keys{
				let traitKey ="context_".concat(key)
				traits.append(MetadataViews.Trait(name:traitKey, value: ctx[key], displayType:"string", rarity:nil))
			}
			traits.append(MetadataViews.Trait(name:"license", value:"https://doodles.app/terms", displayType:"string", rarity:nil))
			return traits
		}
	}

	//A metadata for technical information that is not useful as traits
	pub struct Metadata {
		pub let templateId:UInt64
		pub let setId:UInt64
		pub let positionId:UInt64

		init(templateId:UInt64, setId:UInt64, positionId:UInt64) {
			self.templateId=templateId
			self.setId=setId
			self.positionId=positionId
		}
	}

	// POINTER

	// a struct to store who has interacted with a wearable
	pub struct Pointer {
		pub let id: UInt64
		pub let characterId: UInt64
		pub let address: Address
		access(self) let extra: {String : AnyStruct}
		init(id: UInt64 , characterId: UInt64 , address: Address )  {
			self.id = id
			self.characterId = characterId
			self.address = address
			self.extra = {}
		}

		pub fun isNewInteraction(owner: Address, characterId: UInt64) : Bool {
			return self.address == owner && self.characterId == characterId
		}
	}




	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, ViewResolver.ResolverCollection  {
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

		// deposit moves an NFT into this collection
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			let id: UInt64 = token.id

			token.increaseNounce()
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
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		//a borrow method for the generic view resolver pattern
		pub fun borrowViewResolver(id: UInt64): &AnyResource{ViewResolver.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let wearable = nft as! &NFT
			return wearable
		}

		//This function is here so that other accounts in the doodles ecosystem can borrow it to perform cross-contract interactions. like bumping the equipped counter
		access(account) fun borrowWearableNFT(id: UInt64) : &Wearables.NFT {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let wearable = nft as! &NFT
			return wearable
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//The distinction between sending in a reference and sending in a capability is that when you send in a reference it cannot be stored. So it can only be used in this method
	//while a capability can be stored and used later. So in this case using a reference is the right choice, but it needs to be owned so that you can have a good event
	access(account) fun mintNFT(
		recipient: &{NonFungibleToken.Receiver},
		template: UInt64,
		context: {String:String}
	){
		pre {
			recipient.owner != nil : "Recipients NFT collection is not owned"
			self.templates.containsKey(template) : "Template does not exist. Id : ".concat(template.toString())
		}

		Wearables.totalSupply = Wearables.totalSupply + 1
		let template = Wearables.borrowTemplate(template)
		let set = Wearables.borrowSet(template.set)
		let position =  Wearables.borrowPosition(template.position)

		assert(set.active, message: "Set Retired : ".concat(set.name))
		assert(position.active, message: "Position Retired : ".concat(position.name))
		assert(template.active, message: "Template Retired : ".concat(template.name))

		let tagEditions = template.createTagEditionInfo(nil)

		let editions=[
			Templates.createEditionInfoManually(name:"wearable", counter:"template_".concat(template.id.toString()), edition:nil),
		  	template.createEditionInfo(nil),
			position.createEditionInfo(nil),
			set.createEditionInfo(nil)
		]

		editions.appendAll(tagEditions)

		// create a new NFT
		var newNFT <- create NFT(
			template: Wearables.templates[template.id]!,
			editions:editions,
			context: context
		)


			//add wearable name, tags and display image
			emit Minted(id:newNFT.id, address:recipient.owner!.address, name: newNFT.getName(), thumbnail: newNFT.getThumbnailUrl(), set: set.name, position: position.name, template: template.name, tags: template.getTags(), templateId:template.id, context: context)
		recipient.deposit(token: <-newNFT)

	}

	// This code is not active at this point but is here for later
	// TODO: also send in wearable edition and see mintNFT for info
	// minteditionNFT mints a new NFT with a manual input in edition
	// and deposit it in the recipients collection using their collection reference
	access(account) fun mintEditionNFT(
		recipient: &{NonFungibleToken.Receiver},
		template: UInt64,
		setEdition: UInt64,
		positionEdition: UInt64,
		templateEdition: UInt64,
		taggedTemplateEdition: UInt64,
		tagEditions: [UInt64],
		context: {String:String}
	){
		pre {
			recipient.owner != nil : "Recipients NFT collection is not owned"
			self.templates.containsKey(template) : "Template does not exist. Id : ".concat(template.toString())
		}

		Wearables.totalSupply = Wearables.totalSupply + 1
		let template = Wearables.borrowTemplate(template)
		let set = Wearables.borrowSet(template.set)
		let position =  Wearables.borrowPosition(template.position)

		// This will only be ran by admins, do we need to assert here?
		// assert(set.active, message: "Set Retired : ".concat(set.name))
		// assert(position.active, message: "Position Retired : ".concat(position.name))
		// assert(template.active, message: "Template Retired : ".concat(template.name))

		let tagEditions = template.createTagEditionInfo(tagEditions)


		let editions=[
			Templates.createEditionInfoManually(name:"wearable", counter:"template_".concat(template.id.toString()), edition:taggedTemplateEdition),
			template.createEditionInfo(templateEdition),
			position.createEditionInfo(positionEdition),
			set.createEditionInfo(setEdition)
		]

		editions.appendAll(tagEditions)

		// create a new NFT
		var newNFT <- create NFT(
			template: Wearables.templates[template.id]!,
			editions:editions,
			context: context
		)


		emit Minted(id:newNFT.id, address:recipient.owner!.address, name: newNFT.getName(), thumbnail: newNFT.getThumbnailUrl(), set: set.name, position: position.name, template: template.name, tags: template.getTags(), templateId:template.id, context: context)
		recipient.deposit(token: <-newNFT)

	}

	access(account) fun borrowSet(_ id: UInt64) : &Wearables.Set {
		pre{
			self.sets.containsKey(id) : "Set does not exist. Id : ".concat(id.toString())
		}
		return &Wearables.sets[id]! as &Wearables.Set
	}

	access(account) fun borrowPosition(_ id: UInt64) : &Wearables.Position {
		pre{
			self.positions.containsKey(id) : "Position does not exist. Id : ".concat(id.toString())
		}
		return &Wearables.positions[id]! as &Wearables.Position
	}

	access(account) fun borrowTemplate(_ id: UInt64) : &Wearables.Template {
		pre{
			self.templates.containsKey(id) : "Template does not exist. Id : ".concat(id.toString())
		}
		return &Wearables.templates[id]! as &Wearables.Template
	}

	//Below here are internal resources that is not really relevant to the public

	//internal struct to use for batch minting that points to a specific wearable
	pub struct WearableMintData {
		pub let template: UInt64
		pub let setEdition: UInt64
		pub let positionEdition: UInt64
		pub let templateEdition: UInt64
		pub let taggedTemplateEdition: UInt64
		pub let tagEditions: [UInt64]
		pub let extra: {String : AnyStruct}

		init(
			template: UInt64,
			setEdition: UInt64,
			positionEdition: UInt64,
			templateEdition: UInt64,
			taggedTemplateEdition: UInt64,
			tagEditions: [UInt64],
		) {
			self.template = template
			self.setEdition = setEdition
			self.positionEdition = positionEdition
			self.templateEdition = templateEdition
			self.taggedTemplateEdition = taggedTemplateEdition
			self.tagEditions = tagEditions
			self.extra = {}
		}
	}

	// This is not in use anymore. Use WearableMintData
	//cadence does not allow us to remove this
	pub struct MintData {
		pub let template: UInt64
		pub let setEdition: UInt64
		pub let positionEdition: UInt64
		pub let templateEdition: UInt64
		pub let tagEditions: [UInt64]

		init(
		) {
			self.template = 0
			self.setEdition = 0
			self.positionEdition = 0
			self.templateEdition = 0
			self.tagEditions = [0]
		}
	}

	//setting up the inital state of all the paths and registries
	init() {
		self.totalSupply = 0

		self.sets = {}
		self.positions = {}
		self.templates = {}
		// Set the named paths
		self.CollectionStoragePath = /storage/wearables
		self.CollectionPublicPath = /public/wearables
		self.CollectionPrivatePath = /private/wearables

		self.account.save<@NonFungibleToken.Collection>(<- Wearables.createEmptyCollection(), to: Wearables.CollectionStoragePath)
		self.account.link<&Wearables.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
			Wearables.CollectionPublicPath,
			target: Wearables.CollectionStoragePath
		)
		self.account.link<&Wearables.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
			Wearables.CollectionPrivatePath,
			target: Wearables.CollectionStoragePath
		)

		emit ContractInitialized()
	}
}
