import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FindRewardToken from "../contracts/FindRewardToken.cdc"
import Clock from "../contracts/Clock.cdc"

pub contract FindToken : FungibleToken {

    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)

    pub event TokensMinted(amount: UFix64)
    pub event TokensBurned(amount: UFix64)
    pub event TokenRewardMultiplier(multiplier: UFix64)

    pub let tokenAlias: String
    pub var totalSupply: UFix64
    pub let initialSupply: UFix64 

    
    pub let vaultStoragePath: StoragePath 
    pub let receiverPublicPath: PublicPath 
    pub let balancePublicPath: PublicPath 
    pub let providerPath: PrivatePath 
    pub let minterPath: StoragePath 
    pub let findRewardPath: PrivatePath 


    /***********************************************************
    Implementation on Token Contract for being reward token
    ***********************************************************/
    // Map tenantToken to custom task rewards 
    access(contract) let taskRewards: {String : UFix64}

    // Multiplier 
    pub var taskRewardsMultiplier: UFix64

    // Map address : {Task : Latest Claim TimeStamp}
    access(contract) let claimRecords: {Address : {String : UFix64}}

    pub resource Vault : FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, FindRewardToken.VaultViews , FindRewardToken.FindReward {

        pub var balance: UFix64 
        
        init(balance: UFix64) {
            self.balance=balance
        }

        destroy(){
            FindToken.totalSupply = FindToken.totalSupply - self.balance
            emit TokensBurned(amount: self.balance)
        }

        pub fun withdraw(amount: UFix64) : @FungibleToken.Vault {
            self.balance = self.balance - amount 
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @Vault 
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0 
            destroy vault
        }

        pub fun getViews() : [Type] {
            return [
                Type<FindRewardToken.FTVaultData>() , 
                Type<&FindToken.Vault{FungibleToken.Receiver}>() ,
                Type<&FindToken.Vault{FungibleToken.Balance}>() , 
                Type<&FindToken.Vault{FindRewardToken.VaultViews}>() 
            ]
        }

        pub fun resolveView(_ view: Type) : AnyStruct? {
            switch view {
                case Type<FindRewardToken.FTVaultData>() :
                    return FindRewardToken.FTVaultData(
                            tokenAlias: FindToken.tokenAlias,
                            storagePath: FindToken.vaultStoragePath,
                            receiverPath: FindToken.receiverPublicPath,
                            balancePath: FindToken.balancePublicPath,
                            providerPath: FindToken.providerPath,
                            findRewardPath: FindToken.findRewardPath,
                            vaultType: FindToken.getVaultType(),
                            receiverType: Type<&FindToken.Vault{FungibleToken.Receiver, FindRewardToken.VaultViews}>(),
                            balanceType: Type<&FindToken.Vault{FungibleToken.Balance, FindRewardToken.VaultViews}>(),
                            providerType: Type<&FindToken.Vault{FungibleToken.Provider, FindRewardToken.VaultViews}>(),
                            findRewardType: Type<&FindToken.Vault{FindRewardToken.FindReward, FindRewardToken.VaultViews}>(),
                            createEmptyVault: FindToken.createEmptyVaultFN()
                        )
                
                case Type<&FindToken.Vault{FungibleToken.Receiver}>() :
                    return (&self as &{FungibleToken.Receiver}?)!

                case Type<&FindToken.Vault{FungibleToken.Balance}>() :
                    return (&self as &{FungibleToken.Balance}?)!

                default : 
                    return nil 
            }
        }

        /***********************************************************
        Implementation on Token Contract for being reward token
        ***********************************************************/
        // The name here is just for emitting events for token contract
        pub fun reward(receiver: Address, task: String) : UFix64? {
            if FindToken.taskRewards[task] == nil {
                return nil
            }

            let amount = FindToken.taskRewards[task]! * FindToken.taskRewardsMultiplier

            if amount == 0.0 {
                return nil
            }

            if !FindToken.claimRecords.containsKey(receiver) {
                FindToken.claimRecords[receiver] = {}
            }
            FindToken.claimRecords[receiver]!.insert(key: task, Clock.time())
            return amount
        }

    }

    pub fun createEmptyVault() : @FungibleToken.Vault {
        return <- create FindToken.Vault(balance: 0.0)
    }

    pub fun createEmptyVaultFN() : (() : @FungibleToken.Vault) {
        return fun () : @FungibleToken.Vault {
            return <- FindToken.createEmptyVault()
        }
    }

    pub resource Minter {
        pub fun mintTokens(_ amount: UFix64) : @FungibleToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
            }
            FindToken.totalSupply = FindToken.totalSupply + amount 
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        pub fun setRewardMultiplier(_ multiplier: UFix64) {
            pre{
                multiplier > 0.0 : "Multiplier cannot be less than 0.0"
            }
            FindToken.taskRewardsMultiplier = multiplier
            emit TokenRewardMultiplier(multiplier: multiplier)
        }
    }

    pub fun getBalanceCapability(address: Address) : Capability<&{FungibleToken.Balance}> {
        return getAccount(address).getCapability<&{FungibleToken.Balance}>(FindToken.balancePublicPath)
    }

    pub fun getReceiverCapability(address: Address) : Capability<&{FungibleToken.Receiver}> {
        return getAccount(address).getCapability<&{FungibleToken.Receiver}>(FindToken.receiverPublicPath)
    }

    pub fun getVaultType() : Type {
        return Type<@Vault>()
    }

    init(){
        self.tokenAlias = "FindToken"
        self.totalSupply = 0.0
        self.initialSupply = 100000000.0

        self.vaultStoragePath = /storage/findTokenVault 
        self.receiverPublicPath = /public/findTokenReceiver 
        self.balancePublicPath = /public/findTokenBalance 
        self.providerPath = /private/findTokenProvider 
        self.minterPath = /storage/findTokenMinter
        self.claimRecords = {}

        let minter <- create Minter()
        let vault <- create Vault(balance: 0.0)

        /***********************************************************
        Implementation on Token Contract for being reward token
        ***********************************************************/
        self.taskRewardsMultiplier = 1.0
        emit TokenRewardMultiplier(multiplier: 1.0)
        self.findRewardPath = /private/findTokenReward
        self.taskRewards = FindRewardToken.getDefaultTaskRewards()

        vault.deposit(from: <- minter.mintTokens(self.initialSupply))

        self.account.save(<- vault, to: self.vaultStoragePath)
        self.account.link<&Vault{FungibleToken.Receiver, FindRewardToken.VaultViews}>(self.receiverPublicPath, target: self.vaultStoragePath)
        self.account.link<&Vault{FungibleToken.Balance, FindRewardToken.VaultViews}>(self.balancePublicPath, target: self.vaultStoragePath)
        self.account.link<&Vault{FungibleToken.Provider, FindRewardToken.VaultViews}>(self.providerPath, target: self.vaultStoragePath)
        self.account.link<&Vault{FindRewardToken.FindReward, FindRewardToken.VaultViews, FungibleToken.Provider}>(self.findRewardPath, target: self.vaultStoragePath)
        
        self.account.save(<- minter, to: self.minterPath)

        FindRewardToken.addTenantRewardToken(tenant: FindToken.account.address, cap: FindToken.account.getCapability<&Vault{FindRewardToken.FindReward, FindRewardToken.VaultViews, FungibleToken.Provider}>(self.findRewardPath))
        emit TokensInitialized(initialSupply: self.initialSupply)
    }

}