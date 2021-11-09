# Struct `Royalty`

```cadence
struct Royalty {

    wallets:  {String: Capability<&{FungibleToken.Receiver}>}

    cut:  UFix64

    percentage:  Bool

    owner:  Address
}
```


### Initializer

```cadence
func init(wallets {String: Capability<&{FungibleToken.Receiver}>}, cut UFix64, percentage Bool, owner Address)
```


