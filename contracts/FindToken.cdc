import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FindRewardToken from "../contracts/FindRewardToken.cdc"
import Clock from "../contracts/Clock.cdc"

pub contract FindToken : FungibleToken {

    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)

    pub event TokensMinted(amount: UFix64)
    pub event TokensBurned(amount: UFix64)
    pub event TokensRewarded(findName: String, address: Address, amount: UFix64, task: String)

    pub var totalSupply: UFix64
    pub let initialSupply: UFix64 
    pub let vaultStoragePath: StoragePath 
    pub let receiverPublicPath: PublicPath 
    pub let balancePublicPath: PublicPath 
    pub let providerPath: PrivatePath 
    pub let minterPath: StoragePath 
    pub let findRewardPath: PrivatePath 

    // Map tenantToken to custom task rewards 
    access(contract) let taskRewards: {String : UFix64}

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
                Type<FindRewardToken.FTVaultData>()
            ]
        }

        pub fun resolveView(_ view: Type) : AnyStruct? {
            switch view {
                case Type<FindRewardToken.FTVaultData>() :
                    return FindRewardToken.FTVaultData(
                            storagePath: FindToken.vaultStoragePath,
                            receiverPath: FindToken.receiverPublicPath,
                            balancePath: FindToken.balancePublicPath,
                            providerPath: FindToken.providerPath,
                            findRewardPath: FindToken.findRewardPath,
                            receiverType: Type<&FindToken.Vault{FungibleToken.Receiver}>(),
                            balanceType: Type<&FindToken.Vault{FungibleToken.Balance}>(),
                            providerType: Type<&FindToken.Vault{FungibleToken.Provider}>(),
                            findRewardType: Type<&FindToken.Vault{FindRewardToken.FindReward}>(),
                            createEmptyVault: FindToken.createEmptyVaultFN()
                        )
                default : 
                    return nil 
            }
        }

        pub fun reward(name: String, receiver: &{FungibleToken.Receiver}, task: String) {
            if FindToken.taskRewards[task] == nil {
                return 
            }

            let amount = FindToken.taskRewards[task]! 

            if amount == 0.0 {
                return 
            }

            let vault <- self.withdraw(amount: amount)
            let address = receiver.owner!.address
            emit TokensRewarded(findName: name, address: address, amount: amount, task: task)
            if !FindToken.claimRecords.containsKey(address) {
                FindToken.claimRecords[address] = {}
            }
            FindToken.claimRecords[address]!.insert(key: task, Clock.time())
            receiver.deposit(from: <- vault)
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
    }

    init(){
        self.totalSupply = 0.0
        self.initialSupply = 100000000.0

        self.vaultStoragePath = /storage/findTokenVault 
        self.receiverPublicPath = /public/findTokenReceiver 
        self.balancePublicPath = /public/findTokenBalance 
        self.providerPath = /private/findTokenProvider 
        self.minterPath = /storage/findTokenMinter
        self.findRewardPath = /private/findTokenReward
        self.taskRewards = {}
        self.claimRecords = {}

        let minter <- create Minter()
        let vault <- create Vault(balance: 0.0)

        vault.deposit(from: <- minter.mintTokens(self.initialSupply))

        self.account.save(<- vault, to: self.vaultStoragePath)
        self.account.link<&Vault{FungibleToken.Receiver}>(self.receiverPublicPath, target: self.vaultStoragePath)
        self.account.link<&Vault{FungibleToken.Balance}>(self.balancePublicPath, target: self.vaultStoragePath)
        self.account.link<&Vault{FungibleToken.Provider}>(self.providerPath, target: self.vaultStoragePath)
        self.account.link<&Vault{FindRewardToken.FindReward}>(self.findRewardPath, target: self.vaultStoragePath)
        
        self.account.save(<- minter, to: self.minterPath)

    }

}