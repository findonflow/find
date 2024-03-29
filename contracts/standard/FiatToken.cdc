import FungibleToken from "./FungibleToken.cdc"

//NB NB NB!
// THis is a local mocked version of USDC FiatToken that is basically a clone of FUSD just to make it easier to test with
//the paths are copied from the testnet version 

pub contract FiatToken: FungibleToken {

    // Event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    // Event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    // Event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    // The storage path for the admin resource
    pub let AdminStoragePath: StoragePath

    // The storage Path for minters' MinterProxy
    pub let MinterProxyStoragePath: StoragePath

    // The public path for minters' MinterProxy capability
    pub let MinterProxyPublicPath: PublicPath

    // Event that is emitted when a new minter resource is created
    pub event MinterCreated()

    // Total supply of fusd in existence
    pub var totalSupply: UFix64


		//paths copied from Fiattoken https://github.com/flow-usdc/flow-usdc/blob/main/contracts/FiatToken.cdc
	  pub let VaultStoragePath: StoragePath
    pub let VaultBalancePubPath: PublicPath
    pub let VaultUUIDPubPath: PublicPath
    pub let VaultReceiverPubPath: PublicPath

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault are governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //

		pub resource interface ResourceId {
        pub fun UUID(): UInt64
    }

    pub resource Vault: ResourceId, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        // holds the balance of a users tokens
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

				 pub fun UUID(): UInt64 {
            return self.uuid
        }
        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @FiatToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            FiatToken.totalSupply = FiatToken.totalSupply - self.balance
        }
    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    pub fun createEmptyVault(): @FiatToken.Vault {
        return <-create Vault(balance: 0.0)
    }

    // Minter
    //
    // Resource object that can mint new tokens.
    // The admin stores this and passes it to the minter account as a capability wrapper resource.
    //
    pub resource Minter {

        // mintTokens
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context.
        //
        pub fun mintTokens(amount: UFix64): @Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
            }
            FiatToken.totalSupply = FiatToken.totalSupply + amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

    }

    pub resource interface MinterProxyPublic {
        pub fun setMinterCapability(cap: Capability<&Minter>)
    }

    // MinterProxy
    //
    // Resource object holding a capability that can be used to mint new tokens.
    // The resource that this capability represents can be deleted by the admin
    // in order to unilaterally revoke minting capability if needed.

    pub resource MinterProxy: MinterProxyPublic {

        // access(self) so nobody else can copy the capability and use it.
        access(self) var minterCapability: Capability<&Minter>?

        // Anyone can call this, but only the admin can create Minter capabilities,
        // so the type system constrains this to being called by the admin.
        pub fun setMinterCapability(cap: Capability<&Minter>) {
            self.minterCapability = cap
        }

        pub fun mintTokens(amount: UFix64): @FiatToken.Vault {
            return <- self.minterCapability!
            .borrow()!
            .mintTokens(amount:amount)
        }

        init() {
            self.minterCapability = nil
        }

    }

    // createMinterProxy
    //
    // Function that creates a MinterProxy.
    // Anyone can call this, but the MinterProxy cannot mint without a Minter capability,
    // and only the admin can provide that.
    //
    pub fun createMinterProxy(): @MinterProxy {
        return <- create MinterProxy()
    }

    // Administrator
    //
    // A resource that allows new minters to be created
    //
    // We will only want one minter for now, but might need to add or replace them in future.
    // The Minter/Minter Proxy structure enables this.
    // Ideally we would create this structure in a single function, generate the paths from the address
    // and cache all of this information to enable easy revocation but String/Path comversion isn't yet supported.
    //
    pub resource Administrator {
        pub fun createNewMinter(): @Minter {
            emit MinterCreated()
            return <- create Minter()
        }

    }

    init() {
        let adminAccount =self.account
        self.AdminStoragePath = /storage/fiatAdmin
        self.MinterProxyPublicPath = /public/fiatMinterProxy
        self.MinterProxyStoragePath = /storage/fiatMinterProxy

        self.totalSupply = 0.0

        let admin <- create Administrator()
        adminAccount.save(<-admin, to: self.AdminStoragePath)

        // Emit an event that shows that the contract was initialized
        emit TokensInitialized(initialSupply: 0.0)

				self.VaultStoragePath= /storage/USDCVault
				self.VaultBalancePubPath = /public/USDCVaultBalance
				self.VaultUUIDPubPath = /public/USDCVaultUUID
				self.VaultReceiverPubPath = /public/USDCVaultReceiver

    }
}
