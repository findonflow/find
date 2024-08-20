import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"
import "Flovatar"
import "FlovatarComponent"

/*
 A standard marketplace contract with Royalties management and hardcoded against Flovatar and Components.

 This contract is based on the Versus Auction contract created by Bjartek and Alchemist
 https://github.com/versus-flow/auction-flow-contract

*/

access(all) contract FlovatarMarketplace {

    access(all) let CollectionPublicPath: PublicPath
    access(all) let CollectionStoragePath: StoragePath

    // The Vault of the Marketplace where it will receive the cuts on each sale
    access(all) let marketplaceWallet: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

    // Event that is emitted when a new NFT is put up for sale
    access(all) event FlovatarForSale(id: UInt64, price: UFix64, address: Address)
    access(all) event FlovatarComponentForSale(id: UInt64, price: UFix64, address: Address)

    // Event that is emitted when the price of an NFT changes
    access(all) event FlovatarPriceChanged(id: UInt64, newPrice: UFix64, address: Address)
    access(all) event FlovatarComponentPriceChanged(id: UInt64, newPrice: UFix64, address: Address)

    // Event that is emitted when a token is purchased
    access(all) event FlovatarPurchased(id: UInt64, price: UFix64, from: Address, to: Address)
    access(all) event FlovatarComponentPurchased(id: UInt64, price: UFix64, from: Address, to: Address)

    // Event that is emitted when a royalty has been paid
    access(all) event RoyaltyPaid(id: UInt64, amount: UFix64, to: Address, name: String)

    // Event that is emitted when a seller withdraws their NFT from the sale
    access(all) event FlovatarSaleWithdrawn(tokenId: UInt64, address: Address)
    access(all) event FlovatarComponentSaleWithdrawn(tokenId: UInt64, address: Address)

    // Interface that users will access(all)lish for their Sale collection
    // that only exposes the methods that are supposed to be public
    access(all) resource interface SalePublic {
        access(all) purchaseFlovatar(tokenId: UInt64, recipientCap: Capability<&{Flovatar.CollectionPublic}>, buyTokens: @FungibleToken.Vault)
        access(all) purchaseFlovatarComponent(tokenId: UInt64, recipientCap: Capability<&{FlovatarComponent.CollectionPublic}>, buyTokens: @FungibleToken.Vault)
        access(all) getFlovatarPrice(tokenId: UInt64): UFix64?
        access(all) getFlovatarComponentPrice(tokenId: UInt64): UFix64?
        access(all) getFlovatarIDs(): [UInt64]
        access(all) getFlovatarComponentIDs(): [UInt64]
        access(all) getFlovatar(tokenId: UInt64): &{Flovatar.Public}?
        access(all) getFlovatarComponent(tokenId: UInt64): &{FlovatarComponent.Public}?
    }

    // NFT Collection object that allows a user to put their NFT up for sale
    // where others can send fungible tokens to purchase it
    access(all) resource SaleCollection: SalePublic {

        // Dictionary of the NFTs that the user is putting up for sale
        access(contract) let flovatarForSale: @{UInt64: Flovatar.NFT}
        access(contract) let flovatarComponentForSale: @{UInt64: FlovatarComponent.NFT}

        // Dictionary of the prices for each NFT by ID
        access(contract) let flovatarPrices: {UInt64: UFix64}
        access(contract) let flovatarComponentPrices: {UInt64: UFix64}

        // The fungible token vault of the owner of this sale.
        // When someone buys a token, this resource can deposit
        // tokens into their account.
        access(account) let ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>

        init (vault: Capability<&AnyResource{FungibleToken.Receiver}>) {
            self.flovatarForSale <- {}
            self.flovatarComponentForSale <- {}
            self.ownerVault = vault
            self.flovatarPrices = {}
            self.flovatarComponentPrices = {}
        }

        // Gives the owner the opportunity to remove a Flovatar sale from the collection
        access(all) withdrawFlovatar(tokenId: UInt64): @Flovatar.NFT {
            // remove the price
            self.flovatarPrices.remove(key: tokenId)
            // remove and return the token
            let token <- self.flovatarForSale.remove(key: tokenId) ?? panic("missing NFT")

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarSaleWithdrawn(tokenId: tokenId, address: vaultRef.owner!.address)
            return <-token
        }

        // Gives the owner the opportunity to remove a Component sale from the collection
        access(all) withdrawFlovatarComponent(tokenId: UInt64): @FlovatarComponent.NFT {
            // remove the price
            self.flovatarComponentPrices.remove(key: tokenId)
            // remove and return the token
            let token <- self.flovatarComponentForSale.remove(key: tokenId) ?? panic("missing NFT")

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarComponentSaleWithdrawn(tokenId: tokenId, address: vaultRef.owner!.address)
            return <-token
        }

        // Lists a Flovatar NFT for sale in this collection
        access(all) listFlovatarForSale(token: @Flovatar.NFT, price: UFix64) {
            let id = token.id

            // store the price in the price array
            self.flovatarPrices[id] = price

            // put the NFT into the the forSale dictionary
            let oldToken <- self.flovatarForSale[id] <- token
            destroy oldToken

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarForSale(id: id, price: price, address: vaultRef.owner!.address)
        }

        // Lists a Component NFT for sale in this collection
        access(all) listFlovatarComponentForSale(token: @FlovatarComponent.NFT, price: UFix64) {
            let id = token.id

            // store the price in the price array
            self.flovatarComponentPrices[id] = price

            // put the NFT into the the forSale dictionary
            let oldToken <- self.flovatarComponentForSale[id] <- token
            destroy oldToken

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarComponentForSale(id: id, price: price, address: vaultRef.owner!.address)
        }

        // Changes the price of a Flovatar that is currently for sale
        access(all) changeFlovatarPrice(tokenId: UInt64, newPrice: UFix64) {
            self.flovatarPrices[tokenId] = newPrice

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarPriceChanged(id: tokenId, newPrice: newPrice, address: vaultRef.owner!.address)
        }
        // Changes the price of a Component that is currently for sale
        access(all) changeFlovatarComponentPrice(tokenId: UInt64, newPrice: UFix64) {
            self.flovatarComponentPrices[tokenId] = newPrice

            let vaultRef = self.ownerVault.borrow()
                ?? panic("Could not borrow reference to owner token vault")
            emit FlovatarComponentPriceChanged(id: tokenId, newPrice: newPrice, address: vaultRef.owner!.address)
        }

        // Lets a user send tokens to purchase a Flovatar that is for sale
        access(all) purchaseFlovatar(tokenId: UInt64, recipientCap: Capability<&{Flovatar.CollectionPublic}>, buyTokens: @FungibleToken.Vault) {
            pre {
                self.flovatarForSale[tokenId] != nil && self.flovatarPrices[tokenId] != nil:
                    "No token matching this ID for sale!"
                buyTokens.balance >= (self.flovatarPrices[tokenId] ?? 0.0):
                    "Not enough tokens to buy the NFT!"
            }

            let recipient = recipientCap.borrow()!

            // get the value out of the optional
            let price = self.flovatarPrices[tokenId]!

            self.flovatarPrices[tokenId] = nil

            let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")

            let token <-self.withdrawFlovatar(tokenId: tokenId)

            let creatorAccount = getAccount(token.getMetadata().creatorAddress)
            let creatorWallet = creatorAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!
            let creatorAmount = price * Flovatar.getRoyaltyCut()
            let tempCreatorWallet <- buyTokens.withdraw(amount: creatorAmount)
            creatorWallet.deposit(from: <-tempCreatorWallet)
            

            let marketplaceWallet = FlovatarMarketplace.marketplaceWallet.borrow()!
            let marketplaceAmount = price * Flovatar.getMarketplaceCut()
            let tempMarketplaceWallet <- buyTokens.withdraw(amount: marketplaceAmount)
            marketplaceWallet.deposit(from: <-tempMarketplaceWallet)

            // deposit the purchasing tokens into the owners vault
            vaultRef.deposit(from: <-buyTokens)

            // deposit the NFT into the buyers collection
            recipient.deposit(token: <- token)

            emit FlovatarPurchased(id: tokenId, price: price, from: vaultRef.owner!.address, to: recipient.owner!.address)
        }

        // Lets a user send tokens to purchase a Component that is for sale
        access(all) purchaseFlovatarComponent(tokenId: UInt64, recipientCap: Capability<&{FlovatarComponent.CollectionPublic}>, buyTokens: @FungibleToken.Vault) {
            pre {
                self.flovatarComponentForSale[tokenId] != nil && self.flovatarComponentPrices[tokenId] != nil:
                    "No token matching this ID for sale!"
                buyTokens.balance >= (self.flovatarComponentPrices[tokenId] ?? 0.0):
                    "Not enough tokens to buy the NFT!"
            }

            let recipient = recipientCap.borrow()!

            // get the value out of the optional
            let price = self.flovatarComponentPrices[tokenId]!

            self.flovatarComponentPrices[tokenId] = nil

            let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")

            let token <-self.withdrawFlovatarComponent(tokenId: tokenId)


            let marketplaceWallet = FlovatarMarketplace.marketplaceWallet.borrow()!
            let marketplaceAmount = price * Flovatar.getMarketplaceCut()
            let tempMarketplaceWallet <- buyTokens.withdraw(amount: marketplaceAmount)
            marketplaceWallet.deposit(from: <-tempMarketplaceWallet)

            // deposit the purchasing tokens into the owners vault
            vaultRef.deposit(from: <-buyTokens)

            // deposit the NFT into the buyers collection
            recipient.deposit(token: <- token)

            emit FlovatarComponentPurchased(id: tokenId, price: price, from: vaultRef.owner!.address, to: recipient.owner!.address)
        }

        // Returns the price of a specific Flovatar in the sale
        access(all) getFlovatarPrice(tokenId: UInt64): UFix64? {
            return self.flovatarPrices[tokenId]
        }
        // Returns the price of a specific Component in the sale
        access(all) getFlovatarComponentPrice(tokenId: UInt64): UFix64? {
            return self.flovatarComponentPrices[tokenId]
        }

        // Returns an array of Flovatar IDs that are for sale
        access(all) getFlovatarIDs(): [UInt64] {
            return self.flovatarForSale.keys
        }
        // Returns an array of Component IDs that are for sale
        access(all) getFlovatarComponentIDs(): [UInt64] {
            return self.flovatarComponentForSale.keys
        }

        // Returns a borrowed reference to a Flovatar Sale
        // so that the caller can read data and call methods from it.
        access(all) getFlovatar(tokenId: UInt64): &{Flovatar.Public}? {
            if self.flovatarForSale[tokenId] != nil {
                let ref = (&self.flovatarForSale[tokenId] as auth &NonFungibleToken.NFT?)!
                return ref as! &Flovatar.NFT
            } else {
                return nil
            }
        }
        // Returns a borrowed reference to a Component Sale
        // so that the caller can read data and call methods from it.
        access(all) getFlovatarComponent(tokenId: UInt64): &{FlovatarComponent.Public}? {
            if self.flovatarComponentForSale[tokenId] != nil {
                let ref = (&self.flovatarComponentForSale[tokenId] as auth &NonFungibleToken.NFT?)!
                return ref as! &FlovatarComponent.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.flovatarForSale
            destroy self.flovatarComponentForSale
        }
    }


    // This struct is used to send a data representation of the Flovatar Sales
    // when retrieved using the contract helper methods outside the collection.
    access(all) struct FlovatarSaleData {
        access(all) let id: UInt64
        access(all) let price: UFix64
        access(all) let metadata: Flovatar.Metadata
        access(all) let accessoryId: UInt64?
        access(all) let hatId: UInt64?
        access(all) let eyeglassesId: UInt64?
        access(all) let backgroundId: UInt64?

        init(
            id: UInt64,
            price: UFix64,
            metadata: Flovatar.Metadata,
            accessoryId: UInt64?,
            hatId: UInt64?,
            eyeglassesId: UInt64?,
            backgroundId: UInt64?
            ){

            self.id = id
            self.price = price
            self.metadata = metadata
            self.accessoryId = accessoryId
            self.hatId = hatId
            self.eyeglassesId = eyeglassesId
            self.backgroundId = backgroundId
        }
    }

    // This struct is used to send a data representation of the Component Sales 
    // when retrieved using the contract helper methods outside the collection.
    access(all) struct FlovatarComponentSaleData {
        access(all) let id: UInt64
        access(all) let price: UFix64
        access(all) let metadata: FlovatarComponent.ComponentData

        init(
            id: UInt64,
            price: UFix64,
            metadata: FlovatarComponent.ComponentData){

            self.id = id
            self.price = price
            self.metadata = metadata
        }
    }

    // Get all the Flovatar Sale offers for a specific account
    access(all) getFlovatarSales(address: Address) : [FlovatarSaleData] {
        var saleData: [FlovatarSaleData] = []
        let account = getAccount(address)

        if let saleCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarMarketplace.SalePublic}>()  {
            for id in saleCollection.getFlovatarIDs() {
                let price = saleCollection.getFlovatarPrice(tokenId: id)
                let flovatar = saleCollection.getFlovatar(tokenId: id)
                saleData.append(FlovatarSaleData(
                    id: id,
                    price: price!,
                    metadata: flovatar!.getMetadata(),
                    accessoryId: flovatar!.getAccessory(),
                    hatId: flovatar!.getHat(),
                    eyeglassesId: flovatar!.getEyeglasses(),
                    backgroundId: flovatar!.getBackground()
                    ))
            }
        }
        return saleData
    }

    // Get all the Component Sale offers for a specific account
    access(all) getFlovatarComponentSales(address: Address) : [FlovatarComponentSaleData] {
        var saleData: [FlovatarComponentSaleData] = []
        let account = getAccount(address)

        if let saleCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarMarketplace.SalePublic}>()  {
            for id in saleCollection.getFlovatarComponentIDs() {
                let price = saleCollection.getFlovatarComponentPrice(tokenId: id)
                let flovatarComponent = saleCollection.getFlovatarComponent(tokenId: id)
                saleData.append(FlovatarComponentSaleData(
                    id: id,
                    price: price!,
                    metadata: FlovatarComponent.ComponentData(
                        id: id,
                        templateId: flovatarComponent!.templateId,
                        mint: flovatarComponent!.mint
                        )
                    ))
            }
        }
        return saleData
    }

    // Get a specific Flovatar Sale offers for an account
    access(all) getFlovatarSale(address: Address, id: UInt64) : FlovatarSaleData? {
        let account = getAccount(address)

        if let saleCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarMarketplace.SalePublic}>()  {
            if let flovatar = saleCollection.getFlovatar(tokenId: id) {
                let price = saleCollection.getFlovatarPrice(tokenId: id)
                return FlovatarSaleData(
                           id: id,
                            price: price!,
                            metadata: flovatar.getMetadata(),
                            accessoryId: flovatar.getAccessory(),
                            hatId: flovatar.getHat(),
                            eyeglassesId: flovatar.getEyeglasses(),
                            backgroundId: flovatar!.getBackground()
                           )
            }
        }
        return nil
    }

    // Get a specific Component Sale offers for an account
    access(all) getFlovatarComponentSale(address: Address, id: UInt64) : FlovatarComponentSaleData? {

        let account = getAccount(address)

        if let saleCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarMarketplace.SalePublic}>()  {
            if let flovatarComponent = saleCollection.getFlovatarComponent(tokenId: id) {
                let price = saleCollection.getFlovatarComponentPrice(tokenId: id)
                return FlovatarComponentSaleData(
                           id: id,
                            price: price!,
                            metadata: FlovatarComponent.ComponentData(
                                id: id,
                                templateId: flovatarComponent!.templateId,
                                mint: flovatarComponent!.mint
                                )
                           )
            }
        }
        return nil
    }



    // Returns a new collection resource to the caller
    access(all) createSaleCollection(ownerVault: Capability<&{FungibleToken.Receiver}>): @SaleCollection {
        return <- create SaleCollection(vault: ownerVault)
    }

    access(all) init() {
        self.CollectionPublicPath= /public/FlovatarMarketplace
        self.CollectionStoragePath= /storage/FlovatarMarketplace


        self.marketplaceWallet = self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

    }
}
