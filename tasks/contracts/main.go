package main

import (
	"fmt"
	"os"

	"github.com/bjartek/overflow/overflow"
)

func main() {
	g := overflow.NewOverflow().ExistingEmulator().Start()

	res, err := g.ParseAllWithConfig(false, []string{}, []string{})
	if err != nil {
		panic(err)
	}

	contracts := res.Networks["mainnet"].Contracts

	for name, contracts := range *contracts {
		err := os.WriteFile(fmt.Sprintf("deploy/%s.cdc", name), []byte(contracts), 0644)
		if err != nil {
			panic(err)
		}
	}

}
