# Struct `NameStatus`

```cadence
struct NameStatus {

    status:  LeaseStatus

    owner:  Address?

    persisted:  Bool
}
```

Struct holding information about a lease. Contains both the internal status the owner of the lease and if the state is persisted or not.

### Initializer

```cadence
func init(status LeaseStatus, owner Address?, persisted Bool)
```


