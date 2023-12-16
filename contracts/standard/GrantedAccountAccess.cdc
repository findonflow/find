// MADE BY: Emerald City, Jacob Tucker

// This is a very simple contract that lets users add addresses
// to an "Info" resource signifying they want them to share their account.  

// This is specifically used by the
// `access(all) fun borrowSharedRef(fromHost: Address): &FLOATEvents`
// function inside FLOAT.cdc to give users access to someone elses
// FLOATEvents if they are on this shared list.

// This contract is my way of saying I hate private capabilities, so I
// implemented an alternative solution to private access.

access(all) contract GrantedAccountAccess {

  access(all) let InfoStoragePath: StoragePath
  access(all) let InfoPublicPath: PublicPath

  access(all) resource interface InfoPublic {
    access(all) fun getAllowed(): [Address]
    access(all) fun isAllowed(account: Address): Bool
  }

  // A list of people you allow to share your
  // account.
  access(all) resource Info: InfoPublic {
    access(account) var allowed: {Address: Bool}

    // Allow someone to share your account
    access(all) fun addAccount(account: Address) {
      self.allowed[account] = true
    }

    access(all) fun removeAccount(account: Address) {
      self.allowed.remove(key: account)
    }

    access(all) fun getAllowed(): [Address] {
      return self.allowed.keys
    }

    access(all) fun isAllowed(account: Address): Bool {
      return self.allowed.containsKey(account)
    }

    init() {
      self.allowed = {}
    }
  }

  access(all) fun createInfo(): @Info {
    return <- create Info()
  }

  init() {
    self.InfoStoragePath = /storage/GrantedAccountAccessInfo
    self.InfoPublicPath = /public/GrantedAccountAccessInfo
  }

}

