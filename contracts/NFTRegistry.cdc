import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"

pub contract NFTRegistry {

    /* Event */
    pub event ContractInitialized()
    pub event NFTInfoRegistered(alias: String, typeIdentifier: String)
    pub event NFTInfoRemoved(alias: String, typeIdentifier: String)

    /* Variables */
    // Mapping of {Type Identifier : NFT Info Struct}
    access(contract) var nonFungibleTokenList : {String : NFTInfo}

    // Mapping of {Alias : Type Identifier}
    access(contract) var aliasMap : {String : String}

    /* Struct */
    pub struct NFTInfo {
        pub let alias : String
        // Pass in @NFT type
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

        init(alias: String, type: Type, typeIdentifier: String, icon: String?, providerPath: PrivatePath, publicPath: PublicPath, storagePath: StoragePath, allowedFTTypes: [Type]?, address: Address) {
            self.alias = alias
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
    pub fun getNFTInfoByTypeIdentifier(_ typeIdentifier: String) : NFTInfo? {
        return NFTRegistry.nonFungibleTokenList[typeIdentifier]
    }

	pub fun getNFTInfoByAlias(_ alias: String) : NFTInfo? {
		  if let identifier = NFTRegistry.aliasMap[alias] {
				return NFTRegistry.nonFungibleTokenList[identifier]
			}
			return nil
    }

    pub fun getTypeIdentifier(_ alias: String) : String? {
        return NFTRegistry.aliasMap[alias]
    }

    pub fun getNFTInfoAll() : {String : NFTInfo} {
        return NFTRegistry.nonFungibleTokenList
    }

    /* setters */
    access(account) fun setNFTInfo(alias: String, type: Type, icon: String?, providerPath: PrivatePath, publicPath: PublicPath, storagePath: StoragePath, allowedFTTypes: [Type]?, address: Address) {
        pre{
            !NFTRegistry.nonFungibleTokenList.containsKey(type.identifier) : "This NonFungibleToken Register already exist"
        }
        let typeIdentifier : String = type.identifier
        NFTRegistry.nonFungibleTokenList[typeIdentifier] = NFTInfo(alias: alias,
                                                                   type: type,
                                                                   typeIdentifier: typeIdentifier,
                                                                   icon: icon,
                                                                   providerPath: providerPath,
                                                                   publicPath: publicPath,
                                                                   storagePath: storagePath,
                                                                   allowedFTTypes: allowedFTTypes,
                                                                   address: address)
        
        NFTRegistry.aliasMap[alias] = typeIdentifier
        emit NFTInfoRegistered(alias: alias, typeIdentifier: typeIdentifier)
    }

    access(account) fun removeNFTInfoByTypeIdentifier(_ typeIdentifier: String) : NFTInfo {
        let info = NFTRegistry.nonFungibleTokenList.remove(key: typeIdentifier) ?? panic("Cannot find this NonFungibleToken Registry.")
        NFTRegistry.aliasMap.remove(key: info.alias)
        emit NFTInfoRemoved(alias:info!.alias, typeIdentifier: info!.typeIdentifier)
        return info 
    }

    access(account) fun removeNFTInfoByAlias(_ alias: String) : NFTInfo {
        let typeIdentifier = self.getTypeIdentifier(alias) ?? panic("Cannot find type identifier from this alias.")
        return self.removeNFTInfoByTypeIdentifier(typeIdentifier)
    }

    init() {
        self.nonFungibleTokenList = {}
        self.aliasMap = {}
    }


}
