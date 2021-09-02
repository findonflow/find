# Struct `NameStatus`

```cadence
struct NameStatus {

    status:  LeaseStatus

    owner:  Address?

    persisted:  Bool
}
```


### Initializer

```cadence
func init(status LeaseStatus, owner Address?, persisted Bool)
```


