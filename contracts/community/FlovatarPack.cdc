import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"
import "FlovatarComponentTemplate"
import "FlovatarComponent"
import Crypto
import "FlowUtilityToken"

/*

 This contract defines the Flovatar Packs and a Collection to manage them.

 Each Pack will contain one item for each required Component (body, hair, eyes, nose, mouth, clothing),
 and two other Components that are optional (facial hair, accessory, hat, eyeglasses, background).

 Packs will be pre-minted and can be purchased from the contract owner's account by providing a
 verified signature that is different for each Pack (more info in the purchase function).

 Once purchased, packs cannot be re-sold and users will only be able to open them to receive
 the contained Components into their collection.

 */

access(all) contract FlovatarPack {

    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath

    // Counter for all the Packs ever minted
    access(all) var totalSupply: UInt64

    // Standard events that will be emitted
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Created(id: UInt64, prefix: String)
    access(all) event Opened(id: UInt64)
    access(all) event Purchased(id: UInt64)

    // The public interface contains only the ID and the price of the Pack
    access(all) resource interface Public {
        access(all) let id: UInt64
        access(all) let price: UFix64
        access(all) let sparkCount: UInt32
        access(all) let series: UInt32
        access(all) let name: String
    }

    // The Pack resource that implements the Public interface and that contains
    // different Components in a Dictionary
    access(all) resource Pack: Public {
        access(all) let id: UInt64
        access(all) let price: UFix64
        access(all) let sparkCount: UInt32
        access(all) let series: UInt32
        access(all) let name: String
        access(account) let components: @[FlovatarComponent.NFT]
        access(account) var randomString: String

        // Initializes the Pack with all the Components.
        // It receives also the price and a random String that will signed by
        // the account owner to validate the purchase process.
        init(
            components: @[FlovatarComponent.NFT],
            randomString: String,
            price: UFix64,
            sparkCount: UInt32,
            series: UInt32,
            name: String
        ) {

            // Makes sure that if it's set to have a spark component, this one is present in the array

            var sparkCountCheck: UInt32 = 0
            if(sparkCount > 0){
                var i: Int = 0
                while(i < components.length){
                    if(components[i].getCategory() == "spark"){
                        sparkCountCheck = sparkCountCheck + 1
                    }
                    i = i + 1
                }
            }

            if(sparkCount != sparkCountCheck){
                panic("There is a mismatch in the spark count")
            }




            // Increments the total supply counter
            FlovatarPack.totalSupply = FlovatarPack.totalSupply + UInt64(1)
            self.id = FlovatarPack.totalSupply

            // Moves all the components into the array
            self.components <- []
            while(components.length > 0){
                self.components.append(<- components.remove(at: 0))
            }

            destroy components

            // Sets the randomString text and the price
            self.randomString = randomString
            self.price = price
            self.sparkCount = sparkCount
            self.series = series
            self.name = name
        }

        destroy() {
            destroy self.components
        }

        // This function is used to retrieve the random string to match it
        // against the signature passed during the purchase process
        access(contract) fun getRandomString(): String {
            return self.randomString
        }

        // This function reset the randomString so that after the purchase nobody
        // will be able to re-use the verified signature
        access(contract) fun setRandomString(randomString: String) {
            self.randomString = randomString
        }

        access(all) removeComponent(at: Int): @FlovatarComponent.NFT {
            return <- self.components.remove(at: at)
        }

    }

    //Pack CollectionPublic interface that allows users to purchase a Pack
    access(all) resource interface CollectionPublic {
        access(all) view fun getIDs(): [UInt64]
        access(all) deposit(token: @FlovatarPack.Pack)
        access(all) purchase(tokenId: UInt64, recipientCap: Capability<&{FlovatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, signature: String)
        access(all) purchaseDapper(tokenId: UInt64, recipientCap: Capability<&{FlovatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, signature: String, expectedPrice: UFix64)
    }

    // Main Collection that implements the Public interface and that
    // will handle the purchase transactions
    access(all) resource Collection: CollectionPublic {
        // Dictionary of all the Packs owned
        access(account) let ownedPacks: @{UInt64: FlovatarPack.Pack}
        // Capability to send the FLOW tokens to the owner's account
        access(account) let ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>

        // Initializes the Collection with the vault receiver capability
        init (ownerVault: Capability<&{FungibleToken.Receiver}>) {
            self.ownedPacks <- {}
            self.ownerVault = ownerVault
        }

        // getIDs returns an array of the IDs that are in the collection
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedPacks.keys
        }

        // deposit takes a Pack and adds it to the collections dictionary
        // and adds the ID to the id array
        access(all) deposit(token: @FlovatarPack.Pack) {
            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedPacks[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // withdraw removes a Pack from the collection and moves it to the caller
        access(all) withdraw(withdrawID: UInt64): @FlovatarPack.Pack {
            let token <- self.ownedPacks.remove(key: withdrawID) ?? panic("Missing Pack")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // This function allows any Pack owner to open the pack and receive its content
        // into the owner's Component Collection.
        // The pack is destroyed after the Components are delivered.
        access(all) openPack(id: UInt64) {

            // Gets the Component Collection Public capability to be able to
            // send there the Components contained in the Pack
            let recipientCap = self.owner!.getCapability<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath)
            let recipient = recipientCap.borrow()!

            // Removed the pack from the collection
            let pack <- self.withdraw(withdrawID: id)

            // Removes all the components from the Pack and deposits them to the
            // Component Collection of the owner

            while(pack.components.length > 0){
                recipient.deposit(token: <- pack.removeComponent(at: 0))
            }

            // Emits the event to notify that the pack was opened
            emit Opened(id: pack.id)

            destroy pack
        }

        // Gets the price for a specific Pack
        access(account) fun getPrice(id: UInt64): UFix64 {
            let pack: &FlovatarPack.Pack = (&self.ownedPacks[id] as auth &FlovatarPack.Pack?)!
            return pack.price
        }

        // Gets the random String for a specific Pack
        access(account) fun getRandomString(id: UInt64): String {
            let pack: &FlovatarPack.Pack = (&self.ownedPacks[id] as auth &FlovatarPack.Pack?)!
            return pack.getRandomString()
        }

        // Sets the random String for a specific Pack
        access(account) fun setRandomString(id: UInt64, randomString: String) {
            let pack: &FlovatarPack.Pack = (&self.ownedPacks[id] as auth &FlovatarPack.Pack?)!
            pack.setRandomString(randomString: randomString)
        }


        // This function provides the ability for anyone to purchase a Pack
        // It receives as parameters the Pack ID, the Pack Collection Public capability to receive the pack,
        // a vault containing the necessary FLOW token, and finally a signature to validate the process.
        // The signature is generated off-chain by the smart contract's owner account using the Crypto library
        // to generate a hash from the original random String contained in each Pack.
        // This will guarantee that the contract owner will be able to decide which user can buy a pack, by
        // providing them the correct signature.
        //
        access(all) purchase(tokenId: UInt64, recipientCap: Capability<&{FlovatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, signature: String) {

            // Checks that the pack is still available and that the FLOW tokens are sufficient
            pre {
                self.ownedPacks.containsKey(tokenId) == true : "Pack not found!"
                self.getPrice(id: tokenId) <= buyTokens.balance : "Not enough tokens to buy the Pack!"
                buyTokens.isInstance(Type<@FlowToken.Vault>()) : "Vault not of the right Token Type"
            }

            // Gets the Crypto.KeyList and the public key of the collection's owner
            let keyList = Crypto.KeyList()
            let accountKey = self.owner!.keys.get(keyIndex: 0)!.publicKey

            // Adds the public key to the keyList
            keyList.add(
                PublicKey(
                    publicKey: accountKey.publicKey,
                    signatureAlgorithm: accountKey.signatureAlgorithm
                ),
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: 1.0
            )

            // Creates a Crypto.KeyListSignature from the signature provided in the parameters
            let signatureSet: [Crypto.KeyListSignature] = []
            signatureSet.append(
                Crypto.KeyListSignature(
                    keyIndex: 0,
                    signature: signature.decodeHex()
                )
            )

            // Verifies that the signature is valid and that it was generated from the
            // owner of the collection
            if(!keyList.verify(signatureSet: signatureSet, signedData: self.getRandomString(id: tokenId).utf8,  domainSeparationTag: "FLOW-V0.0-user")){
                panic("Unable to validate the signature for the pack!")
            }


            // Borrows the recipient's capability and withdraws the Pack from the collection.
            // If this fails the transaction will revert but the signature will be exposed.
            // For this reason in case it happens, the randomString will be reset when the purchase
            // reservation timeout expires by the web server back-end.
            let recipient = recipientCap.borrow()!
            let pack <- self.withdraw(withdrawID: tokenId)

            // Borrows the owner's capability for the Vault and deposits the FLOW tokens
            let vaultRef = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner pack vault")
            vaultRef.deposit(from: <-buyTokens)


            // Resets the randomString so that the provided signature will become useless
            let packId: UInt64 = pack.id
            pack.setRandomString(randomString: unsafeRandom().toString())

            // Deposits the Pack to the recipient's collection
            recipient.deposit(token: <- pack)

            // Emits an even to notify about the purchase
            emit Purchased(id: packId)

        }
        //
        access(all) purchaseDapper(tokenId: UInt64, recipientCap: Capability<&{FlovatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, signature: String, expectedPrice: UFix64) {

            // Checks that the pack is still available and that the FLOW tokens are sufficient
            pre {
                self.ownedPacks.containsKey(tokenId) == true : "Pack not found!"
                self.getPrice(id: tokenId) <= buyTokens.balance : "Not enough tokens to buy the Pack!"
                self.getPrice(id: tokenId) == expectedPrice : "Price not set as expected!"
                buyTokens.isInstance(Type<@FlowUtilityToken.Vault>()) : "Vault not of the right Token Type"
            }

            // Gets the Crypto.KeyList and the public key of the collection's owner
            let keyList = Crypto.KeyList()
            let accountKey = self.owner!.keys.get(keyIndex: 0)!.publicKey

            // Adds the public key to the keyList
            keyList.add(
                PublicKey(
                    publicKey: accountKey.publicKey,
                    signatureAlgorithm: accountKey.signatureAlgorithm
                ),
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: 1.0
            )

            // Creates a Crypto.KeyListSignature from the signature provided in the parameters
            let signatureSet: [Crypto.KeyListSignature] = []
            signatureSet.append(
                Crypto.KeyListSignature(
                    keyIndex: 0,
                    signature: signature.decodeHex()
                )
            )

            // Verifies that the signature is valid and that it was generated from the
            // owner of the collection
            if(!keyList.verify(signatureSet: signatureSet, signedData: self.getRandomString(id: tokenId).utf8,  domainSeparationTag: "FLOW-V0.0-user")){
                panic("Unable to validate the signature for the pack!")
            }


            // Borrows the recipient's capability and withdraws the Pack from the collection.
            // If this fails the transaction will revert but the signature will be exposed.
            // For this reason in case it happens, the randomString will be reset when the purchase
            // reservation timeout expires by the web server back-end.
            let recipient = recipientCap.borrow()!
            let pack <- self.withdraw(withdrawID: tokenId)

            // Borrows the owner's capability for the Vault and deposits the FLOW tokens
            let dapperMarketVault = getAccount(0x8a86f18e0e05bd9f).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
            let vaultRef = dapperMarketVault.borrow() ?? panic("Could not borrow reference to owner pack vault")
            vaultRef.deposit(from: <-buyTokens)


            // Resets the randomString so that the provided signature will become useless
            let packId: UInt64 = pack.id
            pack.setRandomString(randomString: unsafeRandom().toString())

            // Deposits the Pack to the recipient's collection
            recipient.deposit(token: <- pack)

            // Emits an even to notify about the purchase
            emit Purchased(id: packId)
        }

        destroy() {
            destroy self.ownedPacks
        }
    }



    // public function that anyone can call to create a new empty collection
    access(all) createEmptyCollection(ownerVault: Capability<&{FungibleToken.Receiver}>): @FlovatarPack.Collection {
        return <- create Collection(ownerVault: ownerVault)
    }

    // Get all the packs from a specific account
    access(all) getPacks(address: Address) : [UInt64]? {

        let account = getAccount(address)

        if let packCollection = account.getCapability(self.CollectionPublicPath).borrow<&{FlovatarPack.CollectionPublic}>()  {
            return packCollection.getIDs();
        }
        return nil
    }



    // This method can only be called from another contract in the same account (The Flovatar Admin resource)
    // It creates a new pack from a list of Components, the random String and the price.
    // Some Components are required and others are optional
    access(account) fun createPack(
            components: @[FlovatarComponent.NFT],
            randomString: String,
            price: UFix64,
            sparkCount: UInt32,
            series: UInt32,
            name: String
        ) : @FlovatarPack.Pack {

        var newPack <- create Pack(
            components: <-components,
            randomString: randomString,
            price: price,
            sparkCount: sparkCount,
            series: series,
            name: name
        )

        // Emits an event to notify that a Pack was created.
        // Sends the first 4 digits of the randomString to be able to sync the ID with the off-chain DB
        // that will store also the signatures once they are generated
        emit Created(id: newPack.id, prefix: randomString.slice(from: 0, upTo: 4))

        return <- newPack
    }

	init() {
        let wallet =  self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        self.CollectionPublicPath=/public/FlovatarPackCollection
        self.CollectionStoragePath=/storage/FlovatarPackCollection

        // Initialize the total supply
        self.totalSupply = 0

        self.account.storage.save<@FlovatarPack.Collection>(<- FlovatarPack.createEmptyCollection(ownerVault: wallet), to: FlovatarPack.CollectionStoragePath)
        self.account.link<&{FlovatarPack.CollectionPublic}>(FlovatarPack.CollectionPublicPath, target: FlovatarPack.CollectionStoragePath)

        emit ContractInitialized()
	}
}

