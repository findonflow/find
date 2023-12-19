import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Clock from "../contracts/Clock.cdc"

pub contract FindToken : FungibleToken {

    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)
    access(all) event TokensDeposited(amount: UFix64, to: Address?)

    access(all) event TokensMinted(amount: UFix64)
    access(all) event TokensBurned(amount: UFix64)
    access(all) event TokenRewardMultiplier(multiplier: UFix64)

    access(all) let tokenAlias: String
    access(all) var totalSupply: UFix64
    access(all) let initialSupply: UFix64 

    
    access(all) let vaultStoragePath: StoragePath 
    access(all) let receiverPublicPath: PublicPath 
    access(all) let balancePublicPath: PublicPath 
    access(all) let providerPath: PrivatePath 
    access(all) let minterPath: StoragePath 
    access(all) let findRewardPath: PrivatePath 

    access(all) resource Vault : FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, FindViews.VaultViews {

        access(all) var balance: UFix64 
        
        init(balance: UFix64) {
            self.balance=balance
        }

        destroy(){
            FindToken.totalSupply = FindToken.totalSupply - self.balance
            emit TokensBurned(amount: self.balance)
        }

        access(all) withdraw(amount: UFix64) : @FungibleToken.Vault {
            self.balance = self.balance - amount 
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        access(all) deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @Vault 
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0 
            destroy vault
        }

        access(all) getViews() : [Type] {
            return [
                Type<FindViews.FTVaultData>() , 
                Type<&FindToken.Vault{FungibleToken.Receiver}>() ,
                Type<&FindToken.Vault{FungibleToken.Balance}>() , 
                Type<&FindToken.Vault{FindViews.VaultViews}>() 
            ]
        }

        access(all) resolveView(_ view: Type) : AnyStruct? {
            switch view {
                case Type<FindViews.FTVaultData>() :
                    return FindViews.FTVaultData(
                            tokenAlias: FindToken.tokenAlias,
                            storagePath: FindToken.vaultStoragePath,
                            receiverPath: FindToken.receiverPublicPath,
                            balancePath: FindToken.balancePublicPath,
                            providerPath: FindToken.providerPath,
                            vaultType: FindToken.getVaultType(),
                            receiverType: Type<&FindToken.Vault{FungibleToken.Receiver, FindViews.VaultViews}>(),
                            balanceType: Type<&FindToken.Vault{FungibleToken.Balance, FindViews.VaultViews}>(),
                            providerType: Type<&FindToken.Vault{FungibleToken.Provider, FindViews.VaultViews}>(),
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

    }

    access(all) createEmptyVault() : @FungibleToken.Vault {
        return <- create FindToken.Vault(balance: 0.0)
    }

    access(all) createEmptyVaultFN() : (() : @FungibleToken.Vault) {
        return fun () : @FungibleToken.Vault {
            return <- FindToken.createEmptyVault()
        }
    }

    access(all) resource Minter {
        access(all) mintTokens(_ amount: UFix64) : @FungibleToken.Vault {
            if amount == 0.0 {
                panic("Amount minted must be greater than zero")
            }
            FindToken.totalSupply = FindToken.totalSupply + amount 
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }
    }

    access(all) getBalanceCapability(address: Address) : Capability<&{FungibleToken.Balance}> {
        return getAccount(address).getCapability<&{FungibleToken.Balance}>(FindToken.balancePublicPath)
    }

    access(all) getReceiverCapability(address: Address) : Capability<&{FungibleToken.Receiver}> {
        return getAccount(address).getCapability<&{FungibleToken.Receiver}>(FindToken.receiverPublicPath)
    }

    access(all) getVaultType() : Type {
        return Type<@Vault>()
    }

    init(){
        self.tokenAlias = "FIND"
        self.totalSupply = 0.0
        self.initialSupply = 100000000.0

        self.vaultStoragePath = /storage/findTokenVault 
        self.receiverPublicPath = /public/findTokenReceiver 
        self.balancePublicPath = /public/findTokenBalance 
        self.providerPath = /private/findTokenProvider 
        self.minterPath = /storage/findTokenMinter

        let minter <- create Minter()
        let vault <- create Vault(balance: 0.0)

        vault.deposit(from: <- minter.mintTokens(self.initialSupply))

        self.account.storage.save(<- vault, to: self.vaultStoragePath)
        self.account.link<&Vault{FungibleToken.Receiver, FindViews.VaultViews}>(self.receiverPublicPath, target: self.vaultStoragePath)
        self.account.link<&Vault{FungibleToken.Balance, FindViews.VaultViews}>(self.balancePublicPath, target: self.vaultStoragePath)
        self.account.link<&Vault{FungibleToken.Provider, FindViews.VaultViews}>(self.providerPath, target: self.vaultStoragePath)
        
        self.account.storage.save(<- minter, to: self.minterPath)

        emit TokensInitialized(initialSupply: self.initialSupply)

        // Extra Field (to be deleted)
        self.findRewardPath = /private/findTokenReward
    }

}