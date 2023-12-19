import FungibleToken from "../standard/FungibleToken.cdc"
import NonFungibleToken from "../standard/NonFungibleToken.cdc"
import FlowToken from "../standard/FlowToken.cdc"
import FlovatarComponentTemplate from "./FlovatarComponentTemplate.cdc"
import FlovatarComponent from "./FlovatarComponent.cdc"
import FlovatarPack from "./FlovatarPack.cdc"
import MetadataViews from "../standard/MetadataViews.cdc"

/*

 The contract that defines the Flovatar NFT and a Collection to manage them

Base components that will be used to generate the unique combination of the Flovatar
'body', 'hair', 'facialhair', 'eyes', 'nose', 'mouth', 'clothing'

Extra components that can be added in a second moment
'accessory', 'hat', eyeglass', 'background'


This contract contains also the Admin resource that can be used to manage and generate all the other ones (Components, Templates, Packs).

 */

pub contract Flovatar: NonFungibleToken {

    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    // These will be used in the Marketplace to pay out
    // royalties to the creator and to the marketplace
    access(account) var royaltyCut: UFix64
    access(account) var marketplaceCut: UFix64

    // Here we keep track of all the Flovatar unique combinations and names
    // that people will generate to make sure that there are no duplicates
    access(all) var totalSupply: UInt64
    access(contract) let mintedCombinations: {String: Bool}
    access(contract) let mintedNames: {String: Bool}

    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Created(id: UInt64, metadata: Metadata)
    access(all) event Updated(id: UInt64)
    access(all) event NameSet(id: UInt64, name: String)


    access(all) struct Royalties{
        access(all) let royalty: [Royalty]
        init(royalty: [Royalty]) {
            self.royalty=royalty
        }
    }

    access(all) enum RoyaltyType: UInt8{
        access(all) case fixed
        access(all) case percentage
    }

    access(all) struct Royalty{
        access(all) let wallet:Capability<&{FungibleToken.Receiver}>
        access(all) let cut: UFix64

        //can be percentage
        access(all) let type: RoyaltyType

        init(wallet:Capability<&{FungibleToken.Receiver}>, cut: UFix64, type: RoyaltyType ){
            self.wallet=wallet
            self.cut=cut
            self.type=type
        }
    }


    // This Metadata struct contains all the most important informations about the Flovatar
    access(all) struct Metadata {
        access(all) let mint: UInt64
        access(all) let series: UInt32
        access(all) let svg: String
        access(all) let combination: String
        access(all) let creatorAddress: Address
        access(self) let components: {String: UInt64}
        access(all) let rareCount: UInt8
        access(all) let epicCount: UInt8
        access(all) let legendaryCount: UInt8


        init(
            mint: UInt64,
            series: UInt32,
            svg: String,
            combination: String,
            creatorAddress: Address,
            components: {String: UInt64},
            rareCount: UInt8,
            epicCount: UInt8,
            legendaryCount: UInt8
        ) {
                self.mint = mint
                self.series = series
                self.svg = svg
                self.combination = combination
                self.creatorAddress = creatorAddress
                self.components = components
                self.rareCount = rareCount
                self.epicCount = epicCount
                self.legendaryCount = legendaryCount
        }
        access(all) getComponents(): {String: UInt64} {
            return self.components
        }
    }

    // The public interface can show metadata and the content for the Flovatar.
    // In addition to it, it provides methods to access the additional optional
    // components (accessory, hat, eyeglasses, background) for everyone.
    access(all) resource interface Public {
        access(all) let id: UInt64
        access(contract) let metadata: Metadata
        access(contract) let royalties: Royalties

        // these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        access(contract) var name: String
        access(all) let description: String
        access(all) let schema: String?

        access(all) getName(): String
        access(all) getAccessory(): UInt64?
        access(all) getHat(): UInt64?
        access(all) getEyeglasses(): UInt64?
        access(all) getBackground(): UInt64?

        access(all) getSvg(): String
        access(all) getMetadata(): Metadata
        access(all) getRoyalties(): Royalties
        access(all) getBio(): {String: String}
        access(all) getRarityScore(): UFix64
    }

    //The private interface can update the Accessory, Hat, Eyeglasses and Background
    //for the Flovatar and is accessible only to the owner of the NFT
    access(all) resource interface Private {
        access(all) setName(name: String): String
        access(all) setAccessory(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT?
        access(all) setHat(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT?
        access(all) setEyeglasses(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT?
        access(all) setBackground(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT?
        access(all) removeAccessory(): @FlovatarComponent.NFT?
        access(all) removeHat(): @FlovatarComponent.NFT?
        access(all) removeEyeglasses(): @FlovatarComponent.NFT?
        access(all) removeBackground(): @FlovatarComponent.NFT?
    }

    //The NFT resource that implements both Private and Public interfaces
    access(all) resource NFT: NonFungibleToken.INFT, Public, Private, ViewResolver.Resolver {
        access(all) let id: UInt64
        access(contract) let metadata: Metadata
        access(contract) let royalties: Royalties
        access(contract) var accessory: @FlovatarComponent.NFT?
        access(contract) var hat: @FlovatarComponent.NFT?
        access(contract) var eyeglasses: @FlovatarComponent.NFT?
        access(contract) var background: @FlovatarComponent.NFT?

        access(contract) var name: String
        access(all) let description: String
        access(all) let schema: String?
        access(self) let bio: {String: String}

        init(metadata: Metadata,
            royalties: Royalties) {
            Flovatar.totalSupply = Flovatar.totalSupply + UInt64(1)

            self.id = Flovatar.totalSupply
            self.metadata = metadata
            self.royalties = royalties
            self.accessory <- nil
            self.hat <- nil
            self.eyeglasses <- nil
            self.background <- nil

            self.schema = nil
            self.name = ""
            self.description = ""
            self.bio = {}
        }

        destroy() {
            destroy self.accessory
            destroy self.hat
            destroy self.eyeglasses
            destroy self.background
        }

        access(all) getID(): UInt64 {
            return self.id
        }

        access(all) getMetadata(): Metadata {
            return self.metadata
        }

        access(all) getRoyalties(): Royalties {
            return self.royalties
        }

        access(all) getBio(): {String: String} {
            return self.bio
        }

        access(all) getName(): String {
            return self.name
        }

        // This will allow to change the Name of the Flovatar only once.
        // It checks for the current name is empty, otherwise it will throw an error.
        access(all) setName(name: String): String {
            pre {
                // TODO: Make sure that the text of the name is sanitized
                //and that bad words are not accepted?
                name.length > 2 : "The name is too short"
                name.length < 32 : "The name is too long"
                self.name == "" : "The name has already been set"
            }

            // Makes sure that the name is available and not taken already
            if(Flovatar.checkNameAvailable(name: name) == false){
                panic("This name has already been taken")
            }

            // DISABLING THIS FUNCTIONALITY TO BE INTRODUCED AT A LATER DATE
            //self.name = name


            // Adds the name to the array to remember it
            //Flovatar.addMintedName(name: name)
            //emit NameSet(id: self.id, name: name)

            return self.name
        }

        access(all) getAccessory(): UInt64? {
            return self.accessory?.templateId
        }

        // This will allow to change the Accessory of the Flovatar any time.
        // It checks for the right category and series before executing.
        access(all) setAccessory(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT? {
            pre {
                component.getCategory() == "accessory" : "The component needs to be an accessory"
                component.getSeries() == self.metadata.series : "The accessory belongs to a different series"
            }

            emit Updated(id: self.id)

            let compNFT <- self.accessory <- component
            return <- compNFT
        }

        // This will allow to remove the Accessory of the Flovatar any time.
        access(all) removeAccessory(): @FlovatarComponent.NFT? {
            emit Updated(id: self.id)
            let compNFT <- self.accessory <- nil
            return <-compNFT
        }

        access(all) getHat(): UInt64? {
            return self.hat?.templateId
        }

        // This will allow to change the Hat of the Flovatar any time.
        // It checks for the right category and series before executing.
        access(all) setHat(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT? {
            pre {
                component.getCategory() == "hat" : "The component needs to be a hat"
                component.getSeries() == self.metadata.series : "The hat belongs to a different series"
            }

            emit Updated(id: self.id)

            let compNFT <- self.hat <- component
            return <-compNFT
        }

        // This will allow to remove the Hat of the Flovatar any time.
        access(all) removeHat(): @FlovatarComponent.NFT? {
            emit Updated(id: self.id)
            let compNFT <- self.hat <- nil
            return <-compNFT
        }

        access(all) getEyeglasses(): UInt64? {
            return self.eyeglasses?.templateId
        }

        // This will allow to change the Eyeglasses of the Flovatar any time.
        // It checks for the right category and series before executing.
        access(all) setEyeglasses(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT? {
            pre {
                component.getCategory() == "eyeglasses" : "The component needs to be a pair of eyeglasses"
                component.getSeries() == self.metadata.series : "The eyeglasses belongs to a different series"
            }

            emit Updated(id: self.id)

            let compNFT <- self.eyeglasses <-component
            return <-compNFT
        }

        // This will allow to remove the Eyeglasses of the Flovatar any time.
        access(all) removeEyeglasses(): @FlovatarComponent.NFT? {
            emit Updated(id: self.id)
            let compNFT <- self.eyeglasses <- nil
            return <-compNFT
        }

        access(all) getBackground(): UInt64? {
            return self.background?.templateId
        }

        // This will allow to change the Background of the Flovatar any time.
        // It checks for the right category and series before executing.
        access(all) setBackground(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT? {
            pre {
                component.getCategory() == "background" : "The component needs to be a background"
                component.getSeries() == self.metadata.series : "The accessory belongs to a different series"
            }

            emit Updated(id: self.id)

            let compNFT <- self.background <- component
            return <-compNFT
        }

        // This will allow to remove the Background of the Flovatar any time.
        access(all) removeBackground(): @FlovatarComponent.NFT? {
            emit Updated(id: self.id)
            let compNFT <- self.background <- nil
            return <-compNFT
        }

        // This function will return the full SVG of the Flovatar. It will take the
        // optional components (Accessory, Hat, Eyeglasses and Background) from their
        // original Template resources, while all the other unmutable components are
        // taken from the Metadata directly.
        access(all) getSvg(): String {
            var svg: String = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3000 3000' width='100%' height='100%'>"

            if let background = self.getBackground() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: background) {
                    svg = svg.concat(template.svg!)
                }
            }

            svg = svg.concat(self.metadata.svg)

            if let eyeglasses = self.getEyeglasses() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: eyeglasses) {
                    svg = svg.concat(template.svg!)
                }
            }

            if let hat = self.getHat() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: hat) {
                    svg = svg.concat(template.svg!)
                }
            }

            if let accessory = self.getAccessory() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: accessory) {
                    svg = svg.concat(template.svg!)
                }
            }

            svg = svg.concat("</svg>")

            return svg

        }

        access(all) getRarityScore(): UFix64{
            var rareCount: UInt8 = self.metadata.rareCount
            var epicCount: UInt8 = self.metadata.epicCount
            var legendaryCount: UInt8 = self.metadata.legendaryCount

            var totalBoosters: UInt8 = legendaryCount + epicCount + rareCount;
            let totalCommon: UInt8 = (totalBoosters > UInt8(6)) ? 0 : (UInt8(6) - totalBoosters);

            if(totalBoosters > UInt8(6)){
                if(rareCount > UInt8(0)) {
                    rareCount = rareCount - UInt8(1);
                } else if(epicCount > UInt8(0)) {
                    epicCount = epicCount - UInt8(1);
                } else if(legendaryCount > UInt8(0)) {
                    legendaryCount = legendaryCount - UInt8(1);
                }
            }

            let score: UInt64 = (UInt64(legendaryCount) * UInt64(125)) + (UInt64(epicCount) * UInt64(25)) + (UInt64(rareCount) * UInt64(5)) + UInt64(totalCommon);
            let min: UInt64 = 6;
            let max: UInt64 = 6 * 125;

            let scoreFix: UFix64 = UFix64(score - min) * UFix64(100.0) / UFix64(max - min) ;
            return scoreFix
        }

        access(all) getViews() : [Type] {
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
        access(all) resolveView(_ type: Type): AnyStruct? {

            if type == Type<MetadataViews.ExternalURL>() {
                return MetadataViews.ExternalURL("https://flovatar.com/flovatars/".concat(self.id.toString()))
            }

            if type == Type<MetadataViews.Royalties>() {
                let royalties : [MetadataViews.Royalty] = []
                var count: Int = 0
                for royalty in self.royalties.royalty {
                    royalties.append(MetadataViews.Royalty(recepient: royalty.wallet, cut: royalty.cut, description: "Flovatar Royalty ".concat(count.toString())))
                    count = count + Int(1)
                }
                return MetadataViews.Royalties(cutInfos: royalties)
            }

            if type == Type<MetadataViews.Serial>() {
                return MetadataViews.Serial(self.id)
            }

            if type ==  Type<MetadataViews.Editions>() {
                let editionInfo = MetadataViews.Edition(name: "Flovatar Series 1", number: self.id, max: UInt64(9999))
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
                    name: "Flovatar",
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
                    name: self.name == "" ? "Flovatar #".concat(self.id.toString()) : self.name,
                    description: self.description,
                    thumbnail: MetadataViews.HTTPFile(
                        url: "https://images.flovatar.com/flovatar/svg/".concat(self.id.toString()).concat(".svg")
                    )
                )
            }

            if type == Type<MetadataViews.Traits>() {
                let traits: [MetadataViews.Trait] = []
                let components: {String: UInt64} = self.metadata.getComponents()

                for k in components.keys {
                    if let template = FlovatarComponentTemplate.getComponentTemplate(id: components[k]!) {
                        let trait = MetadataViews.Trait(name: k, value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                        traits.append(trait)
                    }
                }
                if let accessory = self.getAccessory() {
                    if let template = FlovatarComponentTemplate.getComponentTemplate(id: accessory) {
                        let trait = MetadataViews.Trait(name: template.category, value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                        traits.append(trait)
                    }
                }
                if let background = self.getBackground() {
                    if let template = FlovatarComponentTemplate.getComponentTemplate(id: background) {
                        let trait = MetadataViews.Trait(name: template.category, value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                        traits.append(trait)
                    }
                }
                if let eyeglasses = self.getEyeglasses() {
                    if let template = FlovatarComponentTemplate.getComponentTemplate(id: eyeglasses) {
                        let trait = MetadataViews.Trait(name: template.category, value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                        traits.append(trait)
                    }
                }
                if let hat = self.getHat() {
                    if let template = FlovatarComponentTemplate.getComponentTemplate(id: hat) {
                        let trait = MetadataViews.Trait(name: template.category, value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                        traits.append(trait)
                    }
                }

                return MetadataViews.Traits(traits)
            }

            if type == Type<MetadataViews.Rarity>() {
                return MetadataViews.Rarity(score: self.getRarityScore(), max: 100.0, description: nil)
            }

            if type == Type<MetadataViews.NFTCollectionData>() {
                return MetadataViews.NFTCollectionData(
                storagePath: Flovatar.CollectionStoragePath,
                publicPath: Flovatar.CollectionPublicPath,
                providerPath: /private/FlovatarCollection,
                publicCollection: Type<&Flovatar.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Flovatar.CollectionPublic}>(),
                publicLinkedType: Type<&Flovatar.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Flovatar.CollectionPublic}>(),
                providerLinkedType: Type<&Flovatar.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Flovatar.CollectionPublic}>(),
                createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Flovatar.createEmptyCollection()}
                )
            }
            return nil
        }
    }


    // Standard NFT collectionPublic interface that can also borrowFlovatar as the correct type
    access(all) resource interface CollectionPublic {
        access(all) deposit(token: @NonFungibleToken.NFT)
        access(all) getIDs(): [UInt64]
        access(all) borrowNFT(id: UInt64): &NonFungibleToken.NFT
        access(all) borrowFlovatar(id: UInt64): &Flovatar.NFT{Flovatar.Public, ViewResolver.Resolver}? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Flovatar reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Main Collection to manage all the Flovatar NFT
    access(all) resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, ViewResolver.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        access(all) var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        access(all) withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <- token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        access(all) deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Flovatar.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        access(all) getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        access(all) borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowFlovatar returns a borrowed reference to a Flovatar
        // so that the caller can read data and call methods from it.
        access(all) borrowFlovatar(id: UInt64): &Flovatar.NFT{Flovatar.Public, ViewResolver.Resolver}? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                let flovatarNFT = ref as! &Flovatar.NFT
                return flovatarNFT as &Flovatar.NFT{Flovatar.Public, ViewResolver.Resolver}
            } else {
                return nil
            }
        }

        // borrowFlovatarPrivate returns a borrowed reference to a Flovatar using the Private interface
        // so that the caller can read data and call methods from it, like setting the optional components.
        access(all) borrowFlovatarPrivate(id: UInt64): &{Flovatar.Private}? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Flovatar.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }

        access(all) borrowViewResolver(id: UInt64): &AnyResource{ViewResolver.Resolver} {
            pre {
                self.ownedNFTs[id] != nil : "NFT does not exist"
            }
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let flovatarNFT = nft as! &Flovatar.NFT
            return flovatarNFT as &AnyResource{ViewResolver.Resolver}
        }
    }

    // public function that anyone can call to create a new empty collection
    access(all) createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // This struct is used to send a data representation of the Flovatars
    // when retrieved using the contract helper methods outside the collection.
    access(all) struct FlovatarData {
        access(all) let id: UInt64
        access(all) let name: String
        access(all) let metadata: Flovatar.Metadata
        access(all) let accessoryId: UInt64?
        access(all) let hatId: UInt64?
        access(all) let eyeglassesId: UInt64?
        access(all) let backgroundId: UInt64?
        access(all) let bio: {String: String}
        init(
            id: UInt64,
            name: String,
            metadata: Flovatar.Metadata,
            accessoryId: UInt64?,
            hatId: UInt64?,
            eyeglassesId: UInt64?,
            backgroundId: UInt64?,
            bio: {String: String}
            ) {
            self.id = id
            self.name = name
            self.metadata = metadata
            self.accessoryId = accessoryId
            self.hatId = hatId
            self.eyeglassesId = eyeglassesId
            self.backgroundId = backgroundId
            self.bio = bio
        }
    }


    // This function will look for a specific Flovatar on a user account and return a FlovatarData if found
    access(all) getFlovatar(address: Address, flovatarId: UInt64) : FlovatarData? {

        let account = getAccount(address)

        if let flovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
            if let flovatar = flovatarCollection.borrowFlovatar(id: flovatarId) {
                return FlovatarData(
                    id: flovatarId,
                    name: flovatar!.getName(),
                    metadata: flovatar!.getMetadata(),
                    accessoryId: flovatar!.getAccessory(),
                    hatId: flovatar!.getHat(),
                    eyeglassesId: flovatar!.getEyeglasses(),
                    backgroundId: flovatar!.getBackground(),
                    bio: flovatar!.getBio()
                )
            }
        }
        return nil
    }
    // This function will look for a specific Flovatar on a user account and return the Score
    access(all) getFlovatarRarityScore(address: Address, flovatarId: UInt64) : UFix64? {

        let account = getAccount(address)

        if let flovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
            if let flovatar = flovatarCollection.borrowFlovatar(id: flovatarId) {
                return flovatar.getRarityScore()
            }
        }
        return nil
    }

    // This function will return all Flovatars on a user account and return an array of FlovatarData
    access(all) getFlovatars(address: Address) : [FlovatarData] {

        var flovatarData: [FlovatarData] = []
        let account = getAccount(address)

        if let flovatarCollection = account.getCapability(self.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()  {
            for id in flovatarCollection.getIDs() {
                var flovatar = flovatarCollection.borrowFlovatar(id: id)
                let flovatarMetadata = flovatar!.getMetadata()
                let newMetadata = Metadata(
                            mint: flovatarMetadata.mint,
                            series: flovatarMetadata.series,
                            svg: "",
                            combination: flovatarMetadata.combination,
                            creatorAddress: flovatarMetadata.creatorAddress,
                            components: flovatarMetadata.getComponents(),
                            rareCount: flovatarMetadata.rareCount,
                            epicCount: flovatarMetadata.epicCount,
                            legendaryCount: flovatarMetadata.legendaryCount
                        )
                flovatarData.append(FlovatarData(
                    id: id,
                    name: flovatar!.getName(),
                    metadata: newMetadata,
                    accessoryId: flovatar!.getAccessory(),
                    hatId: flovatar!.getHat(),
                    eyeglassesId: flovatar!.getEyeglasses(),
                    backgroundId: flovatar!.getBackground(),
                    bio: flovatar!.getBio()
                    ))
            }
        }
        return flovatarData
    }


    // This returns all the previously minted combinations, so that duplicates won't be allowed
    access(all) getMintedCombinations() : [String] {
        return Flovatar.mintedCombinations.keys
    }
    // This returns all the previously minted names, so that duplicates won't be allowed
    access(all) getMintedNames() : [String] {
        return Flovatar.mintedNames.keys
    }

    // This function will add a minted combination to the array
    access(account) fun addMintedCombination(combination: String) {
        Flovatar.mintedCombinations.insert(key: combination, true)
    }
    // This function will add a new name to the array
    access(account) fun addMintedName(name: String) {
        Flovatar.mintedNames.insert(key: name, true)
    }

    // This helper function will generate a string from a list of components,
    // to be used as a sort of barcode to keep the inventory of the minted
    // Flovatars and to avoid duplicates
    access(all) getCombinationString(
        body: UInt64,
        hair: UInt64,
        facialHair: UInt64?,
        eyes: UInt64,
        nose: UInt64,
        mouth: UInt64,
        clothing: UInt64
    ) : String {
        let facialHairString = (facialHair != nil) ? facialHair!.toString() : "x"
        return "B".concat(body.toString()).concat("H").concat(hair.toString()).concat("F").concat(facialHairString).concat("E").concat(eyes.toString()).concat("N").concat(nose.toString()).concat("M").concat(mouth.toString()).concat("C").concat(clothing.toString())
    }

    // This function will get a list of component IDs and will check if the
    // generated string is unique or if someone already used it before.
    access(all) checkCombinationAvailable(
        body: UInt64,
        hair: UInt64,
        facialHair: UInt64?,
        eyes: UInt64,
        nose: UInt64,
        mouth: UInt64,
        clothing: UInt64
    ) : Bool {
        let combinationString = Flovatar.getCombinationString(
            body: body,
            hair: hair,
            facialHair: facialHair,
            eyes: eyes,
            nose: nose,
            mouth: mouth,
            clothing: clothing
        )
        return ! Flovatar.mintedCombinations.containsKey(combinationString)
    }

    // This will check if a specific Name has already been taken
    // and assigned to some Flovatar
    access(all) checkNameAvailable(name: String) : Bool {
        return name.length > 2 && name.length < 20 && ! Flovatar.mintedNames.containsKey(name)
    }


    // This is a public function that anyone can call to generate a new Flovatar
    // A list of components resources needs to be passed to executed.
    // It will check first for uniqueness of the combination + name and will then
    // generate the Flovatar and burn all the passed components.
    // The Spark NFT will entitle to use any common basic component (body, hair, etc.)
    // In order to use special rare components a boost of the same rarity will be needed
    // for each component used
    access(all) createFlovatar(
        spark: @FlovatarComponent.NFT,
        body: UInt64,
        hair: UInt64,
        facialHair: UInt64?,
        eyes: UInt64,
        nose: UInt64,
        mouth: UInt64,
        clothing: UInt64,
        accessory: @FlovatarComponent.NFT?,
        hat: @FlovatarComponent.NFT?,
        eyeglasses: @FlovatarComponent.NFT?,
        background: @FlovatarComponent.NFT?,
        rareBoost: @[FlovatarComponent.NFT],
        epicBoost: @[FlovatarComponent.NFT],
        legendaryBoost: @[FlovatarComponent.NFT],
        address: Address
    ) : @Flovatar.NFT {

        pre {
            // Make sure that the spark component belongs to the correct category
            spark.getCategory() == "spark" : "The spark component belongs to the wrong category"
        }

        let bodyTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: body)!
        let hairTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: hair)!
        let eyesTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: eyes)!
        let noseTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: nose)!
        let mouthTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: mouth)!
        let clothingTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: clothing)!


        // Make sure that all components belong to the correct category
        if(bodyTemplate.category != "body") { panic("The body component belongs to the wrong category") }
        if(hairTemplate.category != "hair") { panic("The hair component belongs to the wrong category") }
        if(eyesTemplate.category != "eyes") { panic("The eyes component belongs to the wrong category") }
        if(noseTemplate.category != "nose") { panic("The nose component belongs to the wrong category") }
        if(mouthTemplate.category != "mouth") { panic("The mouth component belongs to the wrong category") }
        if(clothingTemplate.category != "clothing") { panic("The clothing component belongs to the wrong category") }

        let sparkSeries = spark.getSeries();
        // Make sure that all the components belong to the same series like the spark
        if(bodyTemplate.series != sparkSeries) { panic("The body doesn't belong to the correct series") }
        if(hairTemplate.series != sparkSeries) { panic("The hair doesn't belong to the correct series") }
        if(eyesTemplate.series != sparkSeries) { panic("The eyes doesn't belong to the correct series") }
        if(noseTemplate.series != sparkSeries) { panic("The nose doesn't belong to the correct series") }
        if(mouthTemplate.series != sparkSeries) { panic("The mouth doesn't belong to the correct series") }
        if(clothingTemplate.series != sparkSeries) { panic("The clothing doesn't belong to the correct series") }

        // Make more checks for the additional components to check for the right category and uniqueness
        var facialHairTemplate: FlovatarComponentTemplate.ComponentTemplateData? = nil
        if(facialHair != nil){
            facialHairTemplate = FlovatarComponentTemplate.getComponentTemplate(id: facialHair!)
            if(facialHairTemplate?.category != "facialHair"){
                panic("The facial hair component belongs to the wrong category")
            }
            if(facialHairTemplate?.series != sparkSeries){
                panic("The facial hair doesn't belong to the correct series")
            }
        }


        if(accessory != nil){
            if(!(accessory?.checkCategorySeries(category: "accessory", series: sparkSeries)!)){
                panic("The accessory component belongs to the wrong category or the wrong series")
            }
        }

        if(hat != nil){
            if(!(hat?.checkCategorySeries(category: "hat", series: sparkSeries)!)){
                panic("The hat component belongs to the wrong category or the wrong series")
            }
        }

        if(eyeglasses != nil){
            if(!(eyeglasses?.checkCategorySeries(category: "eyeglasses", series: sparkSeries)!)){
                panic("The eyeglasses component belongs to the wrong category or the wrong series")
            }
        }

        if(background != nil){
            if(!(background?.checkCategorySeries(category: "background", series: sparkSeries)!)){
                panic("The background component belongs to the wrong category or the wrong series")
            }
        }


        //Make sure that all the Rarity Boosts are from the correct category
        var i: Int = 0
        while( i < rareBoost.length) {
            if(!rareBoost[i].isBooster(rarity: "rare")) {
                panic("The rare boost belongs to the wrong category")
            }
            if(rareBoost[i].getSeries() != sparkSeries) {
                panic("The rare boost doesn't belong to the correct series")
            }
            i = i + 1
        }
        i = 0
        while( i < epicBoost.length) {
            if(!epicBoost[i].isBooster(rarity: "epic")) {
                panic("The epic boost belongs to the wrong category")
            }
            if(epicBoost[i].getSeries() != sparkSeries) {
                panic("The epic boost doesn't belong to the correct series")
            }
            i = i + 1
        }
        i = 0
        while( i < legendaryBoost.length) {
            if(!legendaryBoost[i].isBooster(rarity: "legendary")) {
                panic("The legendary boost belongs to the wrong category")
            }
            if(legendaryBoost[i].getSeries() != sparkSeries) {
                panic("The legendary boost doesn't belong to the correct series")
            }
            i = i + 1
        }

        //Keep count of the necessary rarity boost for the selected templates
        var rareCount: UInt8 = 0
        var epicCount: UInt8 = 0
        var legendaryCount: UInt8 = 0

        if(bodyTemplate.rarity == "rare"){ rareCount = rareCount + 1 }
        if(hairTemplate.rarity == "rare"){ rareCount = rareCount + 1 }
        if(eyesTemplate.rarity == "rare"){ rareCount = rareCount + 1 }
        if(noseTemplate.rarity == "rare"){ rareCount = rareCount + 1 }
        if(mouthTemplate.rarity == "rare"){ rareCount = rareCount + 1 }
        if(clothingTemplate.rarity == "rare"){ rareCount = rareCount + 1 }

        if(bodyTemplate.rarity == "epic"){ epicCount = epicCount + 1 }
        if(hairTemplate.rarity == "epic"){ epicCount = epicCount + 1 }
        if(eyesTemplate.rarity == "epic"){ epicCount = epicCount + 1 }
        if(noseTemplate.rarity == "epic"){ epicCount = epicCount + 1 }
        if(mouthTemplate.rarity == "epic"){ epicCount = epicCount + 1 }
        if(clothingTemplate.rarity == "epic"){ epicCount = epicCount + 1 }

        if(bodyTemplate.rarity == "legendary"){ legendaryCount = legendaryCount + 1 }
        if(hairTemplate.rarity == "legendary"){ legendaryCount = legendaryCount + 1 }
        if(eyesTemplate.rarity == "legendary"){ legendaryCount = legendaryCount + 1 }
        if(noseTemplate.rarity == "legendary"){ legendaryCount = legendaryCount + 1 }
        if(mouthTemplate.rarity == "legendary"){ legendaryCount = legendaryCount + 1 }
        if(clothingTemplate.rarity == "legendary"){ legendaryCount = legendaryCount + 1 }


        if(facialHairTemplate != nil){
            if(facialHairTemplate?.rarity == "rare"){ rareCount = rareCount + 1}
            if(facialHairTemplate?.rarity == "epic"){ epicCount = epicCount + 1}
            if(facialHairTemplate?.rarity == "legendary"){ legendaryCount = legendaryCount + 1}
        }

        if(Int(rareCount) != rareBoost.length){
            panic("The rare boosts are not equal the ones needed")
        }
        if(Int(epicCount) != epicBoost.length){
            panic("The epic boosts are not equal the ones needed")
        }
        if(Int(legendaryCount) != legendaryBoost.length){
            panic("The epic boosts are not equal the ones needed")
        }




        // Generates the combination string to check for uniqueness.
        // This is like a barcode that defines exactly which components were used
        // to create the Flovatar
        let combinationString = Flovatar.getCombinationString(
            body: body,
            hair: hair,
            facialHair: facialHair,
            eyes: eyes,
            nose: nose,
            mouth: mouth,
            clothing: clothing)

        // Makes sure that the combination is available and not taken already
        if(Flovatar.mintedCombinations.containsKey(combinationString) == true) {
            panic("This combination has already been taken")
        }

        let facialHairSvg:String  = facialHairTemplate != nil ? facialHairTemplate?.svg! : ""
        let svg = (bodyTemplate.svg!).concat(clothingTemplate.svg!).concat(hairTemplate.svg!).concat(eyesTemplate.svg!).concat(noseTemplate.svg!).concat(mouthTemplate.svg!).concat(facialHairSvg)

        // TODO fix this with optional if possible. If I define it as UInt64?
        // instead of UInt64 it's throwing an error even if it's defined in Metadata struct
        let facialHairId: UInt64 = facialHair != nil ? facialHair! : 0

        // Creates the metadata for the new Flovatar
        let metadata = Metadata(
            mint: Flovatar.totalSupply + UInt64(1),
            series: spark.getSeries(),
            svg: svg,
            combination: combinationString,
            creatorAddress: address,
            components: {
                "body": body,
                "hair": hair,
                "facialHair": facialHairId,
                "eyes": eyes,
                "nose": nose,
                "mouth": mouth,
                "clothing": clothing
            },
            rareCount: rareCount,
            epicCount: epicCount,
            legendaryCount: legendaryCount
        )

        let royalties: [Royalty] = []

        let creatorAccount = getAccount(address)
        royalties.append(Royalty(
            wallet: creatorAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
            cut: Flovatar.getRoyaltyCut(),
            type: RoyaltyType.percentage
        ))

        royalties.append(Royalty(
            wallet: self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
            cut: Flovatar.getMarketplaceCut(),
            type: RoyaltyType.percentage
        ))

        // Mint the new Flovatar NFT by passing the metadata to it
        var newNFT <- create NFT(metadata: metadata, royalties: Royalties(royalty: royalties))

        // Adds the combination to the arrays to remember it
        Flovatar.addMintedCombination(combination: combinationString)


        // Checks for any additional optional component (accessory, hat,
        // eyeglasses, background) and assigns it to the Flovatar if present.
        if(accessory != nil){
            let temp <- newNFT.setAccessory(component: <-accessory!)
            destroy temp
        } else {
            destroy accessory
        }
        if(hat != nil){
            let temp <- newNFT.setHat(component: <-hat!)
            destroy temp
        } else {
            destroy hat
        }
        if(eyeglasses != nil){
            let temp <- newNFT.setEyeglasses(component: <-eyeglasses!)
            destroy temp
        } else {
            destroy eyeglasses
        }
        if(background != nil){
            let temp <- newNFT.setBackground(component: <-background!)
            destroy temp
        } else {
            destroy background
        }

        // Emits the Created event to notify about its existence
        emit Created(id: newNFT.id, metadata: metadata)

        // Destroy all the spark and the rarity boost since they are not needed anymore.

        destroy spark

        while(rareBoost.length > 0){
            let boost <- rareBoost.remove(at: 0)
            destroy boost
        }
        destroy rareBoost

        while(epicBoost.length > 0){
            let boost <- epicBoost.remove(at: 0)
            destroy boost
        }
        destroy epicBoost

        while(legendaryBoost.length > 0){
            let boost <- legendaryBoost.remove(at: 0)
            destroy boost
        }
        destroy legendaryBoost

        return <- newNFT
    }



    // These functions will return the current Royalty cuts for
    // both the Creator and the Marketplace.
    access(all) getRoyaltyCut(): UFix64{
        return self.royaltyCut
    }
    access(all) getMarketplaceCut(): UFix64{
        return self.marketplaceCut
    }
    // Only Admins will be able to call the set functions to
    // manage Royalties and Marketplace cuts.
    access(account) fun setRoyaltyCut(value: UFix64){
        self.royaltyCut = value
    }
    access(account) fun setMarketplaceCut(value: UFix64){
        self.marketplaceCut = value
    }




    // This is the main Admin resource that will allow the owner
    // to generate new Templates, Components and Packs
    access(all) resource Admin {

        //This will create a new FlovatarComponentTemplate that
        // contains all the SVG and basic informations to represent
        // a specific part of the Flovatar (body, hair, eyes, mouth, etc.)
        // More info in the FlovatarComponentTemplate.cdc file
        access(all) createComponentTemplate(
            name: String,
            category: String,
            color: String,
            description: String,
            svg: String,
            series: UInt32,
            maxMintableComponents: UInt64,
            rarity: String
        ) : @FlovatarComponentTemplate.ComponentTemplate {
            return <- FlovatarComponentTemplate.createComponentTemplate(
                name: name,
                category: category,
                color: color,
                description: description,
                svg: svg,
                series: series,
                maxMintableComponents: maxMintableComponents,
                rarity: rarity
            )
        }

        // This will mint a new Component based from a selected Template
        access(all) createComponent(templateId: UInt64) : @FlovatarComponent.NFT {
            return <- FlovatarComponent.createComponent(templateId: templateId)
        }
        // This will mint Components in batch and return a Collection instead of the single NFT
        access(all) batchCreateComponents(templateId: UInt64, quantity: UInt64) : @FlovatarComponent.Collection {
            return <- FlovatarComponent.batchCreateComponents(templateId: templateId, quantity: quantity)
        }

        // This function will generate a new Pack containing a set of components.
        // A random string is passed to manage permissions for the
        // purchase of it (more info on FlovatarPack.cdc).
        // Finally the sale price is set as well.
        access(all) createPack(
            components: @[FlovatarComponent.NFT],
            randomString: String,
            price: UFix64,
            sparkCount: UInt32,
            series: UInt32,
            name: String
        ) : @FlovatarPack.Pack {

            return <- FlovatarPack.createPack(
                components: <-components,
                randomString: randomString,
                price: price,
                sparkCount: sparkCount,
                series: series,
                name: name
            )
        }

        // With this function you can generate a new Admin resource
        // and pass it to another user if needed
        access(all) createNewAdmin(): @Admin {
            return <-create Admin()
        }

        // Helper functions to update the Royalty cut
        access(all) setRoyaltyCut(value: UFix64) {
            Flovatar.setRoyaltyCut(value: value)
        }

        // Helper functions to update the Marketplace cut
        access(all) setMarketplaceCut(value: UFix64) {
            Flovatar.setMarketplaceCut(value: value)
        }
    }





	init() {
        self.CollectionPublicPath = /public/FlovatarCollection
        self.CollectionStoragePath = /storage/FlovatarCollection
        self.AdminStoragePath = /storage/FlovatarAdmin

        // Initialize the total supply
        self.totalSupply = UInt64(0)
        self.mintedCombinations = {}
        self.mintedNames = {}

        // Set the default Royalty and Marketplace cuts
        self.royaltyCut = 0.01
        self.marketplaceCut = 0.05

        self.account.storage.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)
        self.account.link<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)

        // Put the Admin resource in storage
        self.account.storage.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
	}
}
