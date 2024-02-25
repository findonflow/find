access(all) contract Sender {

    access(all) let storagePath: StoragePath

    /// This is just an empty resource we create in storage, you can safely send a reference to it to obtain msg.sender
    access(all) resource Token { }

    access(all) fun createToken() : @Sender.Token {
        return <- create Token()
    }

    init() {
        self.storagePath = /storage/findSender
    }
}

