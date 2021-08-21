# Struct `NetworkLease`

```cadence
struct NetworkLease {

    status:  LeaseStatus

    time:  UFix64

    profile:  Capability<&{Profile.Public}>

    address:  Address

    tag:  String
}
```


### Initializer

```cadence
func init(status LeaseStatus, time UFix64, profile Capability<&{Profile.Public}>, tag String)
```


