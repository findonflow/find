# Struct `UserProfile`

```cadence
struct UserProfile {

    address:  Address

    name:  String

    description:  String

    tags:  [String]

    avatar:  String

    links:  [Link]

    wallets:  [WalletProfile]

    collections:  [CollectionProfile]

    following:  [FriendStatus]

    followers:  [FriendStatus]

    allowStoringFollowers:  Bool
}
```


### Initializer

```cadence
func init(address Address, name String, description String, tags [String], avatar String, links [Link], wallets [WalletProfile], collections [CollectionProfile], following [FriendStatus], followers [FriendStatus], allowStoringFollowers Bool)
```


