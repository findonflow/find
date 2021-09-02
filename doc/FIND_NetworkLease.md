# Struct `NetworkLease`

```cadence
struct NetworkLease {

    status:  LeaseStatus

    time:  UFix64

    profile:  Capability<&{Profile.Public}>

    address:  Address

    name:  String
}
```


### Initializer

```cadence
func init(status LeaseStatus, time UFix64, profile Capability<&{Profile.Public}>, name String)
```


