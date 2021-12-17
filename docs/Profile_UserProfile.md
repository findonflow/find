# Struct `UserProfile`

```cadence
struct UserProfile {

    findName:  String

    createdAt:  String

    address:  Address

    name:  String

    gender:  String

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
func init(findName String, address Address, name String, gender String, description String, tags [String], avatar String, links [Link], wallets [WalletProfile], collections [CollectionProfile], following [FriendStatus], followers [FriendStatus], allowStoringFollowers Bool, createdAt String)
```


