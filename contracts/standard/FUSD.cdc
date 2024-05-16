import "FungibleToken"
import "MetadataViews"
import "FungibleTokenMetadataViews"

access(all) contract FUSD: FungibleToken {

    access(all) entitlement MinterProxyOwner

    // Event that is emitted when new tokens are minted
    access(all) event TokensMinted(amount: UFix64)

    // The storage path for the admin resource
    access(all) let AdminStoragePath: StoragePath

    // The storage Path for minters' MinterProxy
    access(all) let MinterProxyStoragePath: StoragePath

    // The public path for minters' MinterProxy capability
    access(all) let MinterProxyPublicPath: PublicPath

    // Total supply of fusd in existence
    access(all) var totalSupply: UFix64s

    // -------- ViewResolver Functions for MetadataViews --------
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()
        ]
    }

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
                    mediaType: ""
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Flow USD",
                    symbol: "FUSD",
                    description: "Deprecated version of Flow USD. Developers are advised to not use this contract any more",
                    externalURL: MetadataViews.ExternalURL(""),
                    logos: medias,
                    socials: {}
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: /storage/fusdVault,
                    receiverPath: /public/fusdReceiver,
                    metadataPath: /public/fusdBalance,
                    receiverLinkedType: Type<&FUSD.Vault>(),
                    metadataLinkedType: Type<&FUSD.Vault>(),
                    createEmptyVaultFunction: (fun(): @{FungibleToken.Vault} {
                        return <-FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
                    })
                )
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(
                    totalSupply: FUSD.totalSupply
                )
        }
        return nil
    }

    // Vault
    //
    access(all) resource Vault: FungibleToken.Vault {

        // holds the balance of a users tokens
        access(all) var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        /// Called when a fungible token is burned via the `Burner.burn()` method
        access(contract) fun burnCallback() {
            if self.balance > 0.0 {
                FUSD.totalSupply = FUSD.totalSupply - self.balance
            }
            self.balance = 0.0
        }

        access(all) view fun getViews(): [Type] {
            return FUSD.getContractViews(resourceType: nil)
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return FUSD.resolveContractView(resourceType: nil, viewType: view)
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

        /// Asks if the amount can be withdrawn from this vault
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return amount <= self.balance
        }

        // withdraw
        //
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            self.balance = self.balance - amount
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @FUSD.Vault
            self.balance = self.balance + vault.balance
            vault.balance = 0.0
            destroy vault
        }

        /// createEmptyVault allows any user to create a new Vault that has a zero balance
        ///
        access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
            return <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
        }
    }

    // createEmptyVault
    //
    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        pre {
            vaultType == Type<@FUSD.Vault>(): "Unsupported vault type requested"
        }
        return <-create Vault(balance: 0.0)
    }

    // Minter
    access(all) resource Minter {

        // mintTokens
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context.
        //
        access(all) fun mintTokens(amount: UFix64): @FUSD.Vault {
            FUSD.totalSupply = FUSD.totalSupply + amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

    }

    access(all) resource interface MinterProxyPublic {
        access(all) fun setMinterCapability(cap: Capability<&Minter>)
    }

    // MinterProxy
    //
    // Resource object holding a capability that can be used to mint new tokens.
    // The resource that this capability represents can be deleted by the admin
    // in order to unilaterally revoke minting capability if needed.
    access(all) resource MinterProxy: MinterProxyPublic {

        // access(self) so nobody else can copy the capability and use it.
        access(self) var minterCapability: Capability<&Minter>?

        // Anyone can call this, but only the admin can create Minter capabilities,
        // so the type system constrains this to being called by the admin.
        access(all) fun setMinterCapability(cap: Capability<&Minter>) {
            self.minterCapability = cap
        }

        access(MinterProxyOwner) fun mintTokens(amount: UFix64): @FUSD.Vault {
            return <- self.minterCapability!
            .borrow()!
            .mintTokens(amount:amount)
        }

        init() {
            self.minterCapability = nil
        }
    }

    // Administrator
    // kept for backwards compatibility
    access(all) resource Administrator {}

    init() {
        self.AdminStoragePath = /storage/fusdAdmin
        self.MinterProxyPublicPath = /public/fusdMinterProxy
        self.MinterProxyStoragePath = /storage/fusdMinterProxy

        self.totalSupply = 1000.0

        let minter <- create Minter()
        self.account.storage.save(<-minter, to: self.AdminStoragePath)

        let vault <- create Vault(balance: self.totalSupply)

        // Create a new FUSD Vault and put it in storage
        self.account.storage.save(<-vault, to: /storage/fusdVault)

        // Create a public capability to the Vault that exposes the Vault interfaces
        let vaultCap = self.account.capabilities.storage.issue<&FUSD.Vault>(
            /storage/fusdVault
        )
        self.account.capabilities.publish(vaultCap, at: /public/fusdBalance)

        // Create a public Capability to the Vault's Receiver functionality
        let receiverCap = self.account.capabilities.storage.issue<&FUSD.Vault>(
            /storage/fusdVault
        )
        self.account.capabilities.publish(receiverCap, at: /public/fusdReceiver)
    }
}
