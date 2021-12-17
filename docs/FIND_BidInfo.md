# Struct `BidInfo`

```cadence
struct BidInfo {

    name:  String

    type:  String

    amount:  UFix64

    timestamp:  UFix64

    lease:  LeaseInformation?
}
```


### Initializer

```cadence
func init(name String, amount UFix64, timestamp UFix64, type String, lease LeaseInformation?)
```


