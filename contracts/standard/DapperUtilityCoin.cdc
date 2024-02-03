import FungibleToken from "./FungibleToken.cdc"
import ViewResolver from "./ViewResolver.cdc"
import MetadataViews from "./MetadataViews.cdc"
import FungibleTokenMetadataViews from "./FungibleTokenMetadataViews.cdc"

access(all) contract DapperUtilityCoin: ViewResolver  {

    // Total supply of DapperUtilityCoins in existence
    access(all) var totalSupply: UFix64

    // Event that is emitted when the contract is created
    access(all) event TokensInitialized(initialSupply: UFix64)

    // Event that is emitted when tokens are withdrawn from a Vault
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event that is emitted when tokens are deposited to a Vault
    access(all) event TokensDeposited(amount: UFix64, to: Address?)

    // Event that is emitted when new tokens are minted
    access(all) event TokensMinted(amount: UFix64)

    // Event that is emitted when tokens are destroyed
    access(all) event TokensBurned(amount: UFix64)

    // Event that is emitted when a new minter resource is created
    access(all) event MinterCreated(allowedAmount: UFix64)

    // Event that is emitted when a new burner resource is created
    access(all) event BurnerCreated()

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    /// Vault
    ///
    /// Each user stores an instance of only the Vault in their storage
    /// The functions in the Vault and governed by the pre and post conditions
    /// in FungibleToken when they are called.
    /// The checks happen at runtime whenever a function is called.
    ///
    /// Resources can only be created in the context of the contract that they
    /// are defined in, so there is no way for a malicious user to create Vaults
    /// out of thin air. A special Minter resource needs to be defined to mint
    /// new tokens.
    ///
    access(all) resource Vault: FungibleToken.Vault {

        /// The total balance of this vault
        access(all) var balance: UFix64

        access(self) var storagePath: StoragePath
        access(self) var publicPath: PublicPath
        access(self) var receiverPath: PublicPath

        /// Returns the storage path where the vault should typically be stored
        access(all) view fun getDefaultStoragePath(): StoragePath? {
            return self.storagePath
        }

        /// Returns the public path where this vault should have a public capability
        access(all) view fun getDefaultPublicPath(): PublicPath? {
            return self.publicPath
        }

        /// Returns the public path where this vault's Receiver should have a public capability
        access(all) view fun getDefaultReceiverPath(): PublicPath? {
            return self.receiverPath
        }

        access(all) view fun getViews(): [Type] {
            return [
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
            case Type<FungibleTokenMetadataViews.FTView>():
                return FungibleTokenMetadataViews.FTView(
                    ftDisplay: self.resolveView(Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                    ftVaultData: self.resolveView(Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                )
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Example Fungible Token",
                    symbol: "EFT",
                    description: "This fungible token is used as an example to help you develop your next FT #onFlow.",
                    externalURL: MetadataViews.ExternalURL("https://example-ft.onflow.org"),
                    logos: medias,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
                    }
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return DapperUtilityCoin.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(
                    totalSupply: DapperUtilityCoin.totalSupply
                )
            }
            return nil
        }

        /// getSupportedVaultTypes optionally returns a list of vault types that this receiver accepts
        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[self.getType()] = true
            return supportedTypes
        }

        access(all) view fun isSupportedVaultType(type: Type): Bool {
            return self.getSupportedVaultTypes()[type] ?? false
        }

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
            let identifier = "exampleTokenVault"
            self.storagePath = StoragePath(identifier: identifier)!
            self.publicPath = PublicPath(identifier: identifier)!
            self.receiverPath = PublicPath(identifier: "exampleTokenReceiver")!
        }

        /// Get the balance of the vault
        access(all) view fun getBalance(): UFix64 {
            return self.balance
        }

        /// withdraw
        ///
        /// Function that takes an amount as an argument
        /// and withdraws that amount from the Vault.
        ///
        /// It creates a new temporary Vault that is used to hold
        /// the tokens that are being transferred. It returns the newly
        /// created Vault to the context that called so it can be deposited
        /// elsewhere.
        ///
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @DapperUtilityCoin.Vault {
            self.balance = self.balance - amount
            return <-create Vault(balance: amount)
        }

        /// deposit
        ///
        /// Function that takes a Vault object as an argument and adds
        /// its balance to the balance of the owners Vault.
        ///
        /// It is allowed to destroy the sent Vault because the Vault
        /// was a temporary holder of the tokens. The Vault's balance has
        /// been consumed and therefore can be destroyed.
        ///
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @DapperUtilityCoin.Vault
            self.balance = self.balance + vault.balance
            vault.balance = 0.0
            destroy vault
        }


        access(FungibleToken.Withdraw) fun transfer(amount: UFix64, receiver: Capability<&{FungibleToken.Receiver}>) {
            let transferVault <- self.withdraw(amount: amount)

            // Get a reference to the recipient's Receiver
            let receiverRef = receiver.borrow()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

            // Deposit the withdrawn tokens in the recipient's receiver
            receiverRef.deposit(from: <-transferVault)
        }


        /// createEmptyVault
        ///
        /// Function that creates a new Vault with a balance of zero
        /// and returns it to the calling context. A user must call this function
        /// and store the returned Vault in their storage in order to allow their
        /// account to be able to receive deposits of this token type.
        ///
        access(all) fun createEmptyVault(): @DapperUtilityCoin.Vault {
            return <-create Vault(balance: 0.0)
        }

        access(contract) fun burnCallback() {
            // Placeholder for a burn callback
        }
    
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
           return true
        }
    }

    /// Gets a list of the metadata views that this contract supports
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [Type<FungibleTokenMetadataViews.FTView>(),
        Type<FungibleTokenMetadataViews.FTDisplay>(),
        Type<FungibleTokenMetadataViews.FTVaultData>(),
        Type<FungibleTokenMetadataViews.TotalSupply>()]
    }

    /// Get a Metadata View from DapperUtilityCoin
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
        case Type<FungibleTokenMetadataViews.FTView>():
            return FungibleTokenMetadataViews.FTView(
                ftDisplay: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                ftVaultData: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
            )
        case Type<FungibleTokenMetadataViews.FTDisplay>():
            let media = MetadataViews.Media(
                file: MetadataViews.HTTPFile(
                    url: ""
                ),
                mediaType: "image/svg+xml"
            )
            let medias = MetadataViews.Medias([media])
            return FungibleTokenMetadataViews.FTDisplay(
                name: "FLOW Network Token",
                symbol: "FLOW",
                description: "FLOW is the native token for the Flow blockchain. It is required for securing the network, transaction fees, storage fees, staking, FLIP voting and may be used by applications built on the Flow Blockchain",
                externalURL: MetadataViews.ExternalURL("https://flow.com"),
                logos: medias,
                socials: {
                    "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
                }
            )
        case Type<FungibleTokenMetadataViews.FTVaultData>():
            let vaultRef = DapperUtilityCoin.account.storage.borrow<auth(FungibleToken.Withdraw) &DapperUtilityCoin.Vault>(from: /storage/DapperUtilityCoinVault)
            ?? panic("Could not borrow reference to the contract's Vault!")
            return FungibleTokenMetadataViews.FTVaultData(
                storagePath: /storage/DapperUtilityCoinVault,
                receiverPath: /public/DapperUtilityCoinReceiver,
                metadataPath: /public/DapperUtilityCoinBalance,
                receiverLinkedType: Type<&DapperUtilityCoin.Vault>(),
                metadataLinkedType: Type<&DapperUtilityCoin.Vault>(),
                createEmptyVaultFunction: (fun (): @{FungibleToken.Vault} {
                    return <-vaultRef.createEmptyVault()
                })
            )
        case Type<FungibleTokenMetadataViews.TotalSupply>():
            return FungibleTokenMetadataViews.TotalSupply(totalSupply: DapperUtilityCoin.totalSupply)
        }
        return nil
    }


    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
        return <-create Vault(balance: 0.0)
    }

    access(all) resource Administrator {
        // createNewMinter
        //
        // Function that creates and returns a new minter resource
        //
        access(all) fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        // createNewBurner
        //
        // Function that creates and returns a new burner resource
        //
        access(all) fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    // Minter
    //
    // Resource object that token admin accounts can hold to mint new tokens.
    //
    access(all) resource Minter {

        // the amount of tokens that the minter is allowed to mint
        access(all) var allowedAmount: UFix64

        // mintTokens
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context.
        //
        access(all) fun mintTokens(amount: UFix64): @DapperUtilityCoin.Vault {
            pre {
                amount > UFix64(0): "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            DapperUtilityCoin.totalSupply = DapperUtilityCoin.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    // Burner
    //
    // Resource object that token admin accounts can hold to burn tokens.
    //
    access(all) resource Burner {

        // burnTokens
        //
        // Function that destroys a Vault instance, effectively burning the tokens.
        //
        // Note: the burned tokens are automatically subtracted from the
        // total supply in the Vault destructor.
        //
        access(all) fun burnTokens(from: @{FungibleToken.Vault}) {
            let vault <- from as! @DapperUtilityCoin.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    init() {
        // we're using a high value as the balance here to make it look like we've got a ton of money,
        // just in case some contract manually checks that our balance is sufficient to pay for stuff
        self.totalSupply = 999999999.0

        let admin <- create Administrator()
        let minter <- admin.createNewMinter(allowedAmount: self.totalSupply)
        self.account.storage.save(<-admin, to: /storage/dapperUtilityCoinAdmin)

        // mint tokens
        let tokenVault <- minter.mintTokens(amount: self.totalSupply)
        self.account.storage.save(<-tokenVault, to: /storage/dapperUtilityCoinVault)
        destroy minter

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        let vaultCap = self.account.capabilities.storage.issue<&Vault>(/storage/dapperUtilityCoinVault)
        self.account.capabilities.publish(vaultCap, at: /public/dapperUtilityCoinVault)

        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        let recieverCap = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(
            /storage/dapperUtilityCoinVault
        )
        self.account.capabilities.publish(recieverCap, at: /public/dapperUtilityCoinReceiver)

        // Emit an event that shows that the contract was initialized
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
