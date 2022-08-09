pub contract FTRegistry {

    /* Event */
    pub event ContractInitialized()
    pub event FTInfoRegistered(alias: String, typeIdentifier: String)
    pub event FTInfoRemoved(alias: String, typeIdentifier: String)

    /* Variables */
    // Mapping of {Type Identifier : FT Info Struct}
    access(contract) var fungibleTokenList : {String : FTInfo}

    access(contract) var aliasMap : {String : String}

    /* Struct */
    pub struct FTInfo {
        pub let alias : String
        pub let type : Type
        pub let typeIdentifier : String
        // Whether it is stable coin or other type of coins. 
        pub let tag : [String ] 
        pub let icon : String?
        pub let receiverPath : PublicPath
        pub let receiverPathIdentifier : String
        pub let balancePath : PublicPath
        pub let balancePathIdentifier : String
        pub let vaultPath : StoragePath
        pub let vaultPathIdentifier : String

        init(alias : String, type: Type, typeIdentifier: String, tag:[String], icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath) {
            self.alias = alias
            self.type = type
            self.typeIdentifier = typeIdentifier
            self.tag = tag
            self.icon = icon
            self.receiverPath = receiverPath
            self.receiverPathIdentifier = receiverPath.toString().slice(from: "/public/".length, upTo: receiverPath.toString().length)
            self.balancePath = balancePath
            self.balancePathIdentifier = balancePath.toString().slice(from: "/public/".length, upTo: balancePath.toString().length)
            self.vaultPath = vaultPath
            self.vaultPathIdentifier = vaultPath.toString().slice(from: "/storage/".length, upTo: vaultPath.toString().length)
        }

    } 

    /* getters */
    pub fun getFTInfoByTypeIdentifier(_ typeIdentifier: String) : FTInfo? {
        return FTRegistry.fungibleTokenList[typeIdentifier]
    }

	pub fun getFTInfoByAlias(_ alias: String) : FTInfo? {
		  if let identifier = FTRegistry.aliasMap[alias] {
				return FTRegistry.fungibleTokenList[identifier]
			}
			return nil
    }

    pub fun getFTInfo(_ input: String) : FTInfo? {
        if let info = self.getFTInfoByAlias(input) {
            return info
        }
        if let info = self.getFTInfoByTypeIdentifier(input) {
            return info
        }
        return nil 
    }

    pub fun getTypeIdentifier(_ alias: String) : String? {
        return FTRegistry.aliasMap[alias]
    }

    pub fun getFTInfoAll() : {String : FTInfo} {
        return FTRegistry.fungibleTokenList
    }

    pub fun getSupportedFTAlias() : [String] {
        return FTRegistry.aliasMap.keys
    }

    pub fun getSupportedFTTypeIdentifier() : [String] {
        return FTRegistry.aliasMap.values
    }

    /* setters */
    access(account) fun setFTInfo(alias: String, type: Type, tag: [String], icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath) {
        if FTRegistry.fungibleTokenList.containsKey(type.identifier) {
            panic("This FungibleToken Register already exist. Type Identifier : ".concat(type.identifier))
        }
        let typeIdentifier : String = type.identifier
        FTRegistry.fungibleTokenList[typeIdentifier] = FTInfo(alias: alias,
                                                              type: type,
                                                              typeIdentifier: typeIdentifier,
                                                              tag : tag,
                                                              icon: icon,
                                                              receiverPath: receiverPath,
                                                              balancePath: balancePath,
                                                              vaultPath: vaultPath)
        
        FTRegistry.aliasMap[alias] = typeIdentifier
        emit FTInfoRegistered(alias: alias, typeIdentifier: typeIdentifier)
    }

    access(account) fun removeFTInfoByTypeIdentifier(_ typeIdentifier: String) : FTInfo {
        let info = FTRegistry.fungibleTokenList.remove(key: typeIdentifier) ?? panic("Cannot find this Fungible Token Registry. Type : ".concat(typeIdentifier))
        FTRegistry.aliasMap.remove(key: info.alias)
        emit FTInfoRemoved(alias:info!.alias, typeIdentifier: info!.typeIdentifier)
        return info 
    }

    access(account) fun removeFTInfoByAlias(_ alias: String) : FTInfo {
        let typeIdentifier = self.getTypeIdentifier(alias) ?? panic("Cannot find type identifier from this alias. Alias : ".concat(alias))
        return self.removeFTInfoByTypeIdentifier(typeIdentifier)
    }

    init() {
        self.fungibleTokenList = {}
        self.aliasMap = {}
    }
}
