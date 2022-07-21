package main

import (
	"os"

	"github.com/bjartek/overflow"
)

func main() {

	o := overflow.NewOverflowMainnet().Start()

	account := os.Getenv("account")

	o.ScriptFromFile("getCollections").Args(o.Arguments().RawAccount(account)).Run()
}
