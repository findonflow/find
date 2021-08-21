# Resource `Administrator`

```cadence
resource Administrator {
}
```

## Functions

### fun `createNetwork()`

```cadence
func createNetwork(leasePeriod UFix64, lockPeriod UFix64, secondaryCut UFix64, defaultPrice UFix64, lengthPrices {Int: UFix64}, wallet Capability<&{FungibleToken.Receiver}>): Network
```

---
