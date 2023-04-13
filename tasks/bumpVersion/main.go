package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"
)

var rcSuffix = "-rc"

func main() {

	jsonFile, err := os.Open("lib/package.json")
    if err != nil {
        fmt.Println(err)
    }
    defer jsonFile.Close()

    byteValue, _ := ioutil.ReadAll(jsonFile)

    var result Package
    json.Unmarshal([]byte(byteValue), &result)

    currentVersion := result.Version

	packageName := result.Name
	isRcPackage := strings.Contains(currentVersion, rcSuffix)
	nextVersion := currentVersion

	if !isRcPackage {
		nextMinorVersion := bumpMinorVersion(currentVersion)
		nextVersion = nextMinorVersion + rcSuffix + ".0"
		fmt.Printf("Package %s is not an RC package. Bumping minor version to %s and creating RC version %s. \n", packageName,nextMinorVersion, nextVersion)
	}

	published := checkIfPublished(nextVersion, packageName)
	for published {
		nextVersion = bumpRcVersion(nextVersion)
		fmt.Printf("Package %s is an RC package and has been published before. Bumping RC version to %s .\n", packageName, nextVersion)
		published = checkIfPublished(nextVersion, packageName)
	}
	result.Version = nextVersion

	// store it back to the file
	jsonString, _ := JSONMarshal(result, "", "	")
	ioutil.WriteFile("lib/package.json", jsonString, 0644)

}

func checkIfPublished(version string, packageName string) bool {
	cmd := exec.Command("npm", "view", packageName+"@"+version)
	err := cmd.Run()
	return err == nil
}

func bumpRcVersion(version string) string {
	version = bumpMinorVersion(version)
	parts := strings.Split(version, rcSuffix+".")
	rcVersion := parts[len(parts)-1]
	rcVersionNumber := strings.TrimSuffix(rcVersion, "\n")
	newRcVersion := fmt.Sprintf("%d", atoi(rcVersionNumber)+1)
	parts[len(parts)-1] = newRcVersion
	return strings.Join(parts, rcSuffix+".")
}

func bumpMinorVersion(version string) string {
	parts := strings.Split(version, ".")
	minorVersion := parts[2]
	newMinorVersion := fmt.Sprintf("%d", atoi(minorVersion)+1)

	parts[2] = newMinorVersion
	return strings.Join(parts, ".")
}

func atoi(s string) int {
	i := 0
	for _, r := range s {
		i = i*10 + int(r-'0')
	}
	return i
}

func JSONMarshal(t interface{}, prefix, indent string) ([]byte, error) {
    buffer := &bytes.Buffer{}
    encoder := json.NewEncoder(buffer)
    encoder.SetEscapeHTML(false)
    err := encoder.Encode(t)
	if err != nil {
		return nil, err
	}

	var buf bytes.Buffer
	err = json.Indent(&buf, buffer.Bytes(), prefix, indent)
	if err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

type Package struct {
	Name        string `json:"name"`
	Version     string `json:"version"`
	Description string `json:"description"`
	Main        string `json:"main"`
	Scripts     struct {
		Test string `json:"test"`
	} `json:"scripts"`
	Repository struct {
		Type string `json:"type"`
		URL  string `json:"url"`
	} `json:"repository"`
	Keywords []string `json:"keywords"`
	Author   string   `json:"author"`
	License  string   `json:"license"`
	Bugs     struct {
		URL string `json:"url"`
	} `json:"bugs"`
	Homepage string `json:"homepage"`
}
