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

    pub let vaultStoragePath: StoragePath 
    pub let receiverPublicPath: PublicPath 
    pub let balancePublicPath: PublicPath 
    pub let providerPath: PrivatePath 
    pub let findRewardPath: PrivatePath 

    // Map tenantToken to custom task rewards 
    access(contract) let taskRewards: {String : UFix64}

    // Map address : {Task : Latest Claim TimeStamp}
    access(contract) let claimRecords: {Address : {String : UFix64}}

    pub resource Vault : FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, FindRewardToken.FindReward {

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

        pub fun reward(name: String, receiver: &{FungibleToken.Receiver}, task: String) {
            pre{
                FindToken.taskRewards.containsKey(task) : "This task is not set up for rewards."
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

    pub resource Minter {
        pub var allowedAmount: UFix64 

        pub fun mintTokens(amount: UFix64) : @Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            FindToken.totalSupply = FindToken.totalSupply + amount 
            
        }
    }

    init(){
        self.totalSupply = 0.0
        self.vaultStoragePath = /storage/findTokenVault 
        self.receiverPublicPath = /public/findTokenReceiver 
        self.balancePublicPath = /public/findTokenBalance 
        self.providerPath = /private/findTokenProvider 
        self.findRewardPath = /private/findTokenReward
        self.taskRewards = {}
        self.claimRecords = {}
    }

}