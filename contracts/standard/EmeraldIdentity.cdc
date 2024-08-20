// Welcome to the EmeraldIdentity contract!
//
// This contract is a service that maps a user's on-chain address
// to their DiscordID. 
//
// A user cannot configure their own EmeraldID. It must be done 
// by someone who has access to the Administrator resource.
//
// A user can only ever have 1 address mapped to 1 DiscordID, and
// 1 DiscordID mapped to 1 address. This means you cannot configure
// multiple addresses to your DiscordID, and you cannot configure
// multiple DiscordIDs to your address. 1-1.

access(all) contract EmeraldIdentity {

    //
    // Paths
    //
    access(all) let AdministratorStoragePath: StoragePath
    access(all) let AdministratorPrivatePath: PrivatePath

    //
    // Events
    //
    access(all) event EmeraldIDCreated(account: Address, discordID: String)
    access(all) event EmeraldIDRemoved(account: Address, discordID: String)

    //
    // Administrator
    //
    access(all) resource Administrator {
        // 1-to-1
        access(account) var accountToDiscord: {Address: String}
        // 1-to-1
        access(account) var discordToAccount: {String: Address}

        access(all) fun createEmeraldID(account: Address, discordID: String) {
            pre {
                EmeraldIdentity.getAccountFromDiscord(discordID: discordID) == nil:
                "The old discordID must remove their EmeraldID first."
                EmeraldIdentity.getDiscordFromAccount(account: account) == nil: 
                "The old account must remove their EmeraldID first."
            }

            self.accountToDiscord[account] = discordID
            self.discordToAccount[discordID] = account

            emit EmeraldIDCreated(account: account, discordID: discordID)
        }

        access(all) fun removeByAccount(account: Address) {
            let discordID = EmeraldIdentity.getDiscordFromAccount(account: account) ?? panic("This EmeraldID does not exist!")
            self.remove(account: account, discordID: discordID)
        }

        access(all) fun removeByDiscord(discordID: String) {
            let account = EmeraldIdentity.getAccountFromDiscord(discordID: discordID) ?? panic("This EmeraldID does not exist!")
            self.remove(account: account, discordID: discordID)
        }

        access(self) fun remove(account: Address, discordID: String) {
            self.discordToAccount.remove(key: discordID)
            self.accountToDiscord.remove(key: account)

            emit EmeraldIDRemoved(account: account, discordID: discordID)
        }

        access(all) fun createAdministrator(): Capability<&Administrator> {
            return EmeraldIdentity.account.capabilities.storage.issue<&Administrator>(EmeraldIdentity.AdministratorStoragePath)
        }

        init() {
            self.accountToDiscord = {}
            self.discordToAccount = {}
        }
    }

    /*** USE THE BELOW FUNCTIONS FOR SECURE VERIFICATION OF ID ***/ 

    access(all) view fun getDiscordFromAccount(account: Address): String?  {
        let admin = EmeraldIdentity.account.storage.borrow<&Administrator>(from: EmeraldIdentity.AdministratorStoragePath)!
        return admin.accountToDiscord[account]
    }

    access(all) view fun getAccountFromDiscord(discordID: String): Address? {
        let admin = EmeraldIdentity.account.storage.borrow<&Administrator>(from: EmeraldIdentity.AdministratorStoragePath)!
        return admin.discordToAccount[discordID]
    }

    init() {
        self.AdministratorStoragePath = /storage/EmeraldIDAdministrator
        self.AdministratorPrivatePath = /private/EmeraldIDAdministrator

        self.account.storage.save(<- create Administrator(), to: EmeraldIdentity.AdministratorStoragePath)
    }
}
