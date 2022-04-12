import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"

pub contract NFTRegistry {

    /* Event */
    pub event ContractInitialized()
    pub event NFTInfoRegistered(name: String, typeIdentifier: String)
    pub event NFTInfoRemoved(name: String, typeIdentifier: String)

    /* Variables */
    // Mapping of {Type Identifier : NFT Info Struct}
    access(contract) var nonFungibleTokenList : {String : NFTInfo}

    // Mapping of {Name : Type Identifier}
    access(contract) var namingMap : {String : String}

    /* Struct */
    pub struct NFTInfo {
        pub let name : String
        // Pass in @Collection type
        pub let type : Type              
        pub let typeIdentifier : String
        pub let icon : String?
        pub let providerPath : PrivatePath
        // Must implement {MetadataViews.ResolverCollection}
        pub let publicPath : PublicPath
        pub let storagePath : StoragePath
        // Pass in arrays of allowed Token Vault, nil => support  all types of FTs
        pub let allowedFTTypes : [Type]?  
        // Pass in the Contract Address
        pub let address : Address

        init(name: String, type: Type, typeIdentifier: String, icon: String?, providerPath: PrivatePath, publicPath: PublicPath, storagePath: StoragePath, allowedFTTypes: [Type]?, address: Address) {
            self.name = name
            self.type = type
            self.typeIdentifier = typeIdentifier
            self.icon = icon
            self.providerPath = providerPath
            self.publicPath = publicPath
            self.storagePath = storagePath
            self.allowedFTTypes = allowedFTTypes
            self.address = address
        }

    } 

    /* getters */
    pub fun getNFTInfo(typeIdentifier: String) : NFTInfo? {
        return NFTRegistry.nonFungibleTokenList[typeIdentifier]
    }

    pub fun getTypeIdentifier(name: String) : String? {
        return NFTRegistry.namingMap[name]
    }

    pub fun getNFTInfoAll() : {String : NFTInfo} {
        return NFTRegistry.nonFungibleTokenList
    }

    /* setters */
    access(account) fun setNFTInfo(name: String, type: Type, icon: String?, providerPath: PrivatePath, publicPath: PublicPath, storagePath: StoragePath, allowedFTTypes: [Type]?, address: Address) {
        pre{
            !NFTRegistry.nonFungibleTokenList.containsKey(type.identifier) : "This NonFungibleToken Register already exist"
        }
        let typeIdentifier : String = type.identifier
        NFTRegistry.nonFungibleTokenList[typeIdentifier] = NFTInfo(name: name,
                                                                   type: type,
                                                                   typeIdentifier: typeIdentifier,
                                                                   icon: icon,
                                                                   providerPath: providerPath,
                                                                   publicPath: publicPath,
                                                                   storagePath: storagePath,
                                                                   allowedFTTypes: allowedFTTypes,
                                                                   address: address)
        
        NFTRegistry.namingMap[name] = typeIdentifier
        emit NFTInfoRegistered(name: name, typeIdentifier: typeIdentifier)
    }

    access(account) fun removeNFTInfo(typeIdentifier: String) : NFTInfo? {
        let info = NFTRegistry.nonFungibleTokenList.remove(key: typeIdentifier) ?? panic("Cannot find this NonFungibleToken Registry.")
        NFTRegistry.namingMap.remove(key: info.name)
        emit NFTInfoRemoved(name:info!.name, typeIdentifier: info!.typeIdentifier)
        return info 
    }

    init() {
        self.nonFungibleTokenList = {}
        self.namingMap = {}
    }


}