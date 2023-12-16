import FungibleToken from "../standard/FungibleToken.cdc"
import NonFungibleToken from "../standard/NonFungibleToken.cdc"
import FlowToken from "../standard/FlowToken.cdc"
import FlovatarComponentTemplate from "./FlovatarComponentTemplate.cdc"
import MetadataViews from "../standard/MetadataViews.cdc"

/*

 This contract defines the Flovatar Component NFT and the Collection to manage them.
 Components are like the building blocks (lego bricks) of the final Flovatar (body, mouth, hair, eyes, etc.) and they can be traded as normal NFTs.
 Components are linked to a specific Template that will ultimately contain the SVG and all the other metadata

 */

pub contract FlovatarComponent: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // Counter for all the Components ever minted
    pub var totalSupply: UInt64

    // Standard events that will be emitted
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, templateId: UInt64, mint: UInt64)
    pub event Destroyed(id: UInt64, templateId: UInt64)

    // The public interface provides all the basic informations about
    // the Component and also the Template ID associated with it.
    pub resource interface Public {
        pub let id: UInt64
        pub let templateId: UInt64
        pub let mint: UInt64
        pub fun getTemplate(): FlovatarComponentTemplate.ComponentTemplateData
        pub fun getSvg(): String
        pub fun getCategory(): String
        pub fun getSeries(): UInt32
        pub fun getRarity(): String
        pub fun isBooster(rarity: String): Bool
        pub fun checkCategorySeries(category: String, series: UInt32): Bool

        //these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        pub let name: String
        pub let description: String
        pub let schema: String?
    }


    // The NFT resource that implements the Public interface as well
    pub resource NFT: NonFungibleToken.INFT, Public, ViewResolver.Resolver {
        pub let id: UInt64
        pub let templateId: UInt64
        pub let mint: UInt64
        pub let name: String
        pub let description: String
        pub let schema: String?

        // Initiates the NFT from a Template ID.
        init(templateId: UInt64) {

            FlovatarComponent.totalSupply = FlovatarComponent.totalSupply + UInt64(1)

            let componentTemplate = FlovatarComponentTemplate.getComponentTemplate(id: templateId)!

            self.id = FlovatarComponent.totalSupply
            self.templateId = templateId
            self.mint = FlovatarComponentTemplate.getTotalMintedComponents(id: templateId)! + UInt64(1)
            self.name = componentTemplate.name
            self.description = componentTemplate.description
            self.schema = nil

            // Increments the counter and stores the timestamp
            FlovatarComponentTemplate.setTotalMintedComponents(id: templateId, value: self.mint)
            FlovatarComponentTemplate.setLastComponentMintedAt(id: templateId, value: getCurrentBlock().timestamp)
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        // Returns the Template associated to the current Component
        pub fun getTemplate(): FlovatarComponentTemplate.ComponentTemplateData {
            return FlovatarComponentTemplate.getComponentTemplate(id: self.templateId)!
        }

        // Gets the SVG from the parent Template
        pub fun getSvg(): String {
            return self.getTemplate().svg!
        }

        // Gets the category from the parent Template
        pub fun getCategory(): String {
            return self.getTemplate().category
        }

        // Gets the series number from the parent Template
        pub fun getSeries(): UInt32 {
            return self.getTemplate().series
        }

        // Gets the rarity from the parent Template
        pub fun getRarity(): String {
            return self.getTemplate().rarity
        }

        // Check the boost and rarity from the parent Template
        pub fun isBooster(rarity: String): Bool {
            let template = self.getTemplate()
            return template.category == "boost" && template.rarity == rarity
        }

        //Check the category and series from the parent Template
        pub fun checkCategorySeries(category: String, series: UInt32): Bool {
            let template = self.getTemplate()
            return template.category == category && template.series == series
        }

        // Emit a Destroyed event when it will be burned to create a Flovatar
        // This will help to keep track of how many Components are still
        // available on the market.
        destroy() {
            emit Destroyed(id: self.id, templateId: self.templateId)
        }

        pub fun getViews() : [Type] {
            var views : [Type]=[]
            views.append(Type<MetadataViews.NFTCollectionData>())
            views.append(Type<MetadataViews.NFTCollectionDisplay>())
            views.append(Type<MetadataViews.Display>())
            views.append(Type<MetadataViews.Royalties>())
            views.append(Type<MetadataViews.Edition>())
            views.append(Type<MetadataViews.ExternalURL>())
            views.append(Type<MetadataViews.Serial>())
            views.append(Type<MetadataViews.Traits>())
            return views
        }

        pub fun resolveView(_ type: Type): AnyStruct? {

            if type == Type<MetadataViews.ExternalURL>() {
                let address = self.owner?.address
                let url = (address == nil) ? "https://flovatar.com/builder/" : "https://flovatar.com/components/".concat(self.id.toString()).concat("/").concat(address!.toString())
                return MetadataViews.ExternalURL("https://flovatar.com/builder/")
            }

            if type == Type<MetadataViews.Royalties>() {
                let royalties : [MetadataViews.Royalty] = []
                royalties.append(MetadataViews.Royalty(receiver: FlovatarComponent.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver), cut: 0.05, description: "Flovatar Royalty"))
                return MetadataViews.Royalties(cutInfos: royalties)
            }

            if type == Type<MetadataViews.Serial>() {
                return MetadataViews.Serial(self.id)
            }

            if type ==  Type<MetadataViews.Editions>() {
                let componentTemplate: FlovatarComponentTemplate.ComponentTemplateData = self.getTemplate()

                let editionInfo = MetadataViews.Edition(name: "Flovatar Component", number: self.mint, max: componentTemplate.maxMintableComponents)
                let editionList: [MetadataViews.Edition] = [editionInfo]
                return MetadataViews.Editions(
                    editionList
                )
            }

            if type == Type<MetadataViews.NFTCollectionDisplay>() {
                let mediaSquare = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://images.flovatar.com/logo.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
                let mediaBanner = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://images.flovatar.com/logo-horizontal.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Flovatar Component",
                    description: "Flovatar is pioneering a new way to unleash community creativity in Web3 by allowing users to be co-creators of their prized NFTs, instead of just being passive collectors.",
                    externalURL: MetadataViews.ExternalURL("https://flovatar.com"),
                    squareImage: mediaSquare,
                    bannerImage: mediaBanner,
                    socials: {
                        "discord": MetadataViews.ExternalURL("https://discord.gg/flovatar"),
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/flovatar"),
                        "instagram": MetadataViews.ExternalURL("https://instagram.com/flovatar_nft"),
                        "tiktok": MetadataViews.ExternalURL("https://www.tiktok.com/@flovatar")
                    }
                )
            }


            if type == Type<MetadataViews.Display>() {
                return MetadataViews.Display(
                    name: self.name,
                    description: self.description,
                    thumbnail: MetadataViews.HTTPFile(
                        url: "https://flovatar.com/api/image/template/".concat(self.templateId.toString())
                    )
                )
            }

            if type == Type<MetadataViews.Traits>() {
                let traits: [MetadataViews.Trait] = []

                let template = self.getTemplate()
                let trait = MetadataViews.Trait(name: template.category, value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                traits.append(trait)

                return MetadataViews.Traits(traits)
            }

            if type == Type<MetadataViews.Rarity>() {
                let template = self.getTemplate()
                return MetadataViews.Rarity(score: nil, max: nil, description: template.rarity)
            }

            if type == Type<MetadataViews.NFTCollectionData>() {
                return MetadataViews.NFTCollectionData(
                storagePath: FlovatarComponent.CollectionStoragePath,
                publicPath: FlovatarComponent.CollectionPublicPath,
                providerPath: /private/FlovatarComponentCollection,
                publicCollection: Type<&FlovatarComponent.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, FlovatarComponent.CollectionPublic}>(),
                publicLinkedType: Type<&FlovatarComponent.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, FlovatarComponent.CollectionPublic}>(),
                providerLinkedType: Type<&FlovatarComponent.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, FlovatarComponent.CollectionPublic}>(),
                createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- FlovatarComponent.createEmptyCollection()}
                )
            }
            return nil
        }
    }

    // Standard NFT collectionPublic interface that can also borrowComponent as the correct type
    pub resource interface CollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowComponent(id: UInt64): &FlovatarComponent.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Component reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Main Collection to manage all the Components NFT
    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection {
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

            return <- token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @FlovatarComponent.NFT

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
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowComponent returns a borrowed reference to a FlovatarComponent
        // so that the caller can read data and call methods from it.
        pub fun borrowComponent(id: UInt64): &FlovatarComponent.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &FlovatarComponent.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{ViewResolver.Resolver} {
            pre {
                self.ownedNFTs[id] != nil : "NFT does not exist"
            }
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let componentNFT = nft as! &FlovatarComponent.NFT
            return componentNFT as &AnyResource{ViewResolver.Resolver}
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // This struct is used to send a data representation of the Components
    // when retrieved using the contract helper methods outside the collection.
    pub struct ComponentData {
        pub let id: UInt64
        pub let templateId: UInt64
        pub let mint: UInt64
        pub let name: String
        pub let description: String
        pub let category: String
        pub let rarity: String
        pub let color: String

        init(id: UInt64, templateId: UInt64, mint: UInt64) {
            self.id = id
            self.templateId = templateId
            self.mint = mint
            let componentTemplate = FlovatarComponentTemplate.getComponentTemplate(id: templateId)!
            self.name = componentTemplate.name
            self.description = componentTemplate.description
            self.category = componentTemplate.category
            self.rarity = componentTemplate.rarity
            self.color = componentTemplate.color
        }
    }

    // Get the SVG of a specific Component from an account and the ID
    pub fun getSvgForComponent(address: Address, componentId: UInt64) : String? {
        let account = getAccount(address)
        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponent.CollectionPublic}>()  {
            return componentCollection.borrowComponent(id: componentId)!.getSvg()
        }
        return nil
    }

    // Get a specific Component from an account and the ID as ComponentData
    pub fun getComponent(address: Address, componentId: UInt64) : ComponentData? {
        let account = getAccount(address)
        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponent.CollectionPublic}>()  {
            if let component = componentCollection.borrowComponent(id: componentId) {
                return ComponentData(
                    id: componentId,
                    templateId: component!.templateId,
                    mint: component!.mint
                )
            }
        }
        return nil
    }

    // Get an array of all the components in a specific account as ComponentData
    pub fun getComponents(address: Address) : [ComponentData] {

        var componentData: [ComponentData] = []
        let account = getAccount(address)

        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarComponent.CollectionPublic}>()  {
            for id in componentCollection.getIDs() {
                var component = componentCollection.borrowComponent(id: id)
                componentData.append(ComponentData(
                    id: id,
                    templateId: component!.templateId,
                    mint: component!.mint
                    ))
            }
        }
        return componentData
    }

    // This method can only be called from another contract in the same account.
    // In FlovatarComponent case it is called from the Flovatar Admin that is used
    // to administer the components.
    // The only parameter is the parent Template ID and it will return a Component NFT resource
    access(account) fun createComponent(templateId: UInt64) : @FlovatarComponent.NFT {

        let componentTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: templateId)!
        let totalMintedComponents: UInt64 = FlovatarComponentTemplate.getTotalMintedComponents(id: templateId)!

        // Makes sure that the original minting limit set for each Template has not been reached
        if(totalMintedComponents >= componentTemplate.maxMintableComponents) {
            panic("Reached maximum mintable components for this type")
        }

        var newNFT <- create NFT(templateId: templateId)
        emit Created(id: newNFT.id, templateId: templateId, mint: newNFT.mint)

        return <- newNFT
    }

    // This function will batch create multiple Components and pass them back as a Collection
    access(account) fun batchCreateComponents(templateId: UInt64, quantity: UInt64): @Collection {
        let newCollection <- create Collection()

        var i: UInt64 = 0
        while i < quantity {
            newCollection.deposit(token: <-self.createComponent(templateId: templateId))
            i = i + UInt64(1)
        }

        return <-newCollection
    }

	init() {
        self.CollectionPublicPath = /public/FlovatarComponentCollection
        self.CollectionStoragePath = /storage/FlovatarComponentCollection

        // Initialize the total supply
        self.totalSupply = UInt64(0)

        self.account.save<@NonFungibleToken.Collection>(<- FlovatarComponent.createEmptyCollection(), to: FlovatarComponent.CollectionStoragePath)
        self.account.link<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath)

        emit ContractInitialized()
	}
}

