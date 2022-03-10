package main

import (
	"os"

	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowMainnet().Start()

	account := os.Getenv("account")

	o.ScriptFromFile("collections").Args(o.Arguments().RawAccount(account)).Run()
}
