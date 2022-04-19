import FungibleToken from "./standard/FungibleToken.cdc"

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
        pub(set) var alias : String
        pub(set) var type : Type
        pub(set) var typeIdentifier : String
        pub(set) var icon : String?
        pub(set) var receiverPath : PublicPath
        pub(set) var balancePath : PublicPath
        pub(set) var vaultPath : StoragePath

        init(alias : String, type: Type, typeIdentifier: String, icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath) {
            self.alias = alias
            self.type = type
            self.typeIdentifier = typeIdentifier
            self.icon = icon
            self.receiverPath = receiverPath
            self.balancePath = balancePath
            self.vaultPath = vaultPath
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

    pub fun getTypeIdentifier(_ alias: String) : String? {
        return FTRegistry.aliasMap[alias]
    }

    pub fun getFTInfoAll() : {String : FTInfo} {
        return FTRegistry.fungibleTokenList
    }

    /* setters */
    access(account) fun setFTInfo(alias: String, type: Type, icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath) {
        pre{
            !FTRegistry.fungibleTokenList.containsKey(type.identifier) : "This FungibleToken Register already exist"
        }
        let typeIdentifier : String = type.identifier
        FTRegistry.fungibleTokenList[typeIdentifier] = FTInfo(alias: alias,
                                                              type: type,
                                                              typeIdentifier: typeIdentifier,
                                                              icon: icon,
                                                              receiverPath: receiverPath,
                                                              balancePath: balancePath,
                                                              vaultPath: vaultPath)
        
        FTRegistry.aliasMap[alias] = typeIdentifier
        emit FTInfoRegistered(alias: alias, typeIdentifier: typeIdentifier)
    }

    access(account) fun removeFTInfoByTypeIdentifier(_ typeIdentifier: String) : FTInfo {
        let info = FTRegistry.fungibleTokenList.remove(key: typeIdentifier) ?? panic("Cannot find this Fungible Token Registry.")
        FTRegistry.aliasMap.remove(key: info.alias)
        emit FTInfoRemoved(alias:info!.alias, typeIdentifier: info!.typeIdentifier)
        return info 
    }

    access(account) fun removeFTInfoByAlias(_ alias: String) : FTInfo {
        let typeIdentifier = self.getTypeIdentifier(alias) ?? panic("Cannot find type identifier from this alias.")
        return self.removeFTInfoByTypeIdentifier(typeIdentifier)
    }

    init() {
        self.fungibleTokenList = {}
        self.aliasMap = {}
    }
}
