import FungibleToken from "../contracts/standard/FungibleToken.cdc"

pub contract FindRewardToken {

    // Map tenantToken to custom task rewards 
    access(contract) let defaultTaskRewards:  {String : UFix64}
    access(contract) let tenantTokenCapabilities: {Address : Capability<&{FindReward}>}

    pub resource interface VaultViews {
        pub var balance: UFix64 

        pub fun getViews() : [Type]
        pub fun resolveView(_ view: Type): AnyStruct?
    }

    pub struct FTVaultData {
        pub let storagePath: StoragePath
        pub let receiverPath: PublicPath
        pub let balancePath: PublicPath
        pub let providerPath: PrivatePath
        pub let findRewardPath: PrivatePath?
        pub let receiverType: Type
        pub let balanceType: Type
        pub let providerType: Type
        pub let findRewardType: Type?
        pub let createEmptyVault: ((): @FungibleToken.Vault)

        init(
            storagePath: StoragePath,
            receiverPath: PublicPath,
            balancePath: PublicPath,
            providerPath: PrivatePath,
            findRewardPath: PrivatePath?,
            receiverType: Type,
            balanceType: Type,
            providerType: Type,
            findRewardType: Type?,
            createEmptyVault: ((): @FungibleToken.Vault)
        ) {
            pre {
                receiverType.isSubtype(of: Type<&{FungibleToken.Receiver}>()): "Receiver type must include FungibleToken.Receiver interfaces."
                balanceType.isSubtype(of: Type<&{FungibleToken.Balance}>()): "Balance type must include FungibleToken.Balance interfaces."
                providerType.isSubtype(of: Type<&{FungibleToken.Provider}>()): "Provider type must include FungibleToken.Provider interface."
                findRewardType == nil || findRewardType!.isSubtype(of: Type<&{FindRewardToken.FindReward}>()): "FindReward type must include FindRewardToken.FindReward interface."
            }
            self.storagePath=storagePath
            self.receiverPath=receiverPath
            self.balancePath=balancePath
            self.providerPath = providerPath
            self.findRewardPath = findRewardPath
            self.receiverType=receiverType
            self.balanceType=balanceType
            self.providerType = providerType
            self.findRewardType = findRewardType
            self.createEmptyVault=createEmptyVault
        }
    }

    pub resource interface FindReward {
        pub fun reward(name: String, receiver: &{FungibleToken.Receiver}, task: String, emitEvent:((String, Address, UFix64, String) : Void)) 
    } 

    access(account) fun addTenantRewardToken(tenant: Address, cap: Capability<&{FindReward}>) {
        pre{
            self.tenantTokenCapabilities[tenant] == nil : "This tenant token has already registered."
        }
        self.tenantTokenCapabilities[tenant] = cap
    }

    access(account) fun removeTenantRewardToken(tenant: Address, cap: Capability<&{FindReward}>) {
        pre{
            self.tenantTokenCapabilities[tenant] != nil : "This tenant token has not yet registered."
        }
        self.tenantTokenCapabilities.remove(key: tenant)
    }

    init(){
        self.defaultTaskRewards = {
            "FindName_Sale_List" : 1.0, 
            "FindName_Sale_Buy" : 1.0
        } 
        self.tenantTokenCapabilities = {}
    }

}