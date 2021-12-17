# Struct `Wallet`

```cadence
struct Wallet {

    name:  String

    receiver:  Capability<&{FungibleToken.Receiver}>

    balance:  Capability<&{FungibleToken.Balance}>

    accept:  Type

    tags:  [String]
}
```


### Initializer

```cadence
func init(name String, receiver Capability<&{FungibleToken.Receiver}>, balance Capability<&{FungibleToken.Balance}>, accept Type, tags [String])
```


