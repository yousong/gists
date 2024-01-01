package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"unicode/utf8"

	"github.com/pkg/errors"
	"golang.org/x/text/encoding/simplifiedchinese"
)

func main() {
	if len(os.Args) != 2 {
		log.Fatalf("usage: %s rootdir", os.Args[0])
	}
	rd := os.Args[1]
	if err := walk(rd, ""); err != nil {
		log.Fatalf("%v", err)
	}
}

func walk(pref, name string) error {
	p := filepath.Join(pref, name)
	st, err := os.Stat(p)
	if err != nil {
		return errors.Wrapf(err, "stat %q", p)
	}
	if st.IsDir() {
		des, err := os.ReadDir(p)
		if err != nil {
			return errors.Wrapf(err, "readdir %q", p)
		}
		for _, de := range des {
			err := walk(p, de.Name())
			if err != nil {
				return err
			}
		}
	}
	return gbk2utf8(pref, name)
}

func gbk2utf8(pref, name string) error {
	if utf8.ValidString(name) {
		return nil
	}
	dec := simplifiedchinese.GB18030.NewDecoder()
	name1, err := dec.String(name)
	if err != nil {
		return err
	}
	if name1 == "" {
		return fmt.Errorf("%s: converted to empty: %q", pref, name)
	}
	if name1 == name {
		return nil
	}
	oldp := filepath.Join(pref, name)
	newp := filepath.Join(pref, name1)
	if true {
		if err := os.Rename(oldp, newp); err != nil {
			return err
		}
	} else {
		log.Printf("%s", name1)
	}
	return nil
}
