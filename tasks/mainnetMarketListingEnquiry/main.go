package main

import (
	"fmt"
	"os"
	"sort"

	. "github.com/bjartek/overflow"
	"github.com/sanity-io/litter"
)

func main() {
	o := Overflow(
		WithNetwork(os.Args[1]),
	)

	q := o.ScriptFileNameFN("devgetEnabledNFTListings",
		WithArg("detail", false),
	)

	var r Res = Res{}

	page := 1
	for {
		fmt.Println("page", page)
		res := q(
			WithArg("page", page),
		)
		fmt.Println(res.Result.String())
		if res.Err != nil {
			panic(res.Err)
		}
		var a Res
		err := res.MarshalAs(&a)
		if err != nil {
			break
		}
		r.Combine(&a)
		page++
	}
	r.Sort()
	litter.Dump(r)
}

type Res struct {
	Dapper    []string
	NonDapper []string
}

func (r *Res) Combine(a *Res) {
	r.Dapper = append(r.Dapper, a.Dapper...)
	r.NonDapper = append(r.NonDapper, a.NonDapper...)
}

func (r *Res) Sort() {
	// sort and remove duplicates
	sort.Strings(r.Dapper)
	sort.Strings(r.NonDapper)
}
