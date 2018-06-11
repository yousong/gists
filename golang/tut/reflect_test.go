package tut

import (
	"reflect"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"
)

func TestSelect(t *testing.T) {
	chanS := make(chan int)
	caseS := reflect.SelectCase{
		Chan: reflect.ValueOf((chan<- int)(chanS)),
		Dir:  reflect.SelectSend,
		Send: reflect.ValueOf(int(2)),
	}
	chanR := make(chan int)
	caseR := reflect.SelectCase{
		Chan: reflect.ValueOf((<-chan int)(chanR)),
		Dir:  reflect.SelectRecv,
	}
	caseD := reflect.SelectCase{
		Dir: reflect.SelectDefault,
	}

	wg := sync.WaitGroup{}
	wg.Add(1)
	go func() {
		wg.Wait()
		<-chanS
		chanR <- 3
		close(chanR)
	}()

	cases := []reflect.SelectCase{caseS, caseD}
	for {
		i, recvV, recvOk := reflect.Select(cases)
		switch cases[i] {
		case caseS:
			t.Logf("sent")
			cases = append(cases, caseR)
		case caseR:
			if recvOk {
				t.Logf("received: %d", recvV.Interface().(int))
			} else {
				t.Logf("closed")
				goto out
			}
		case caseD:
			t.Logf("default triggered, remove it")
			cases[i] = cases[len(cases)-1]
			cases = cases[:len(cases)-1]
			wg.Done()
		}
	}
out:
	if len(cases) != 2 {
		t.Errorf("wrong len of cases: %d", len(cases))
	}
}

func TestTypeOf(t *testing.T) {
	var x interface{}

	if reflect.TypeOf(nil) != nil {
		t.Error()
	}
	if reflect.TypeOf(x) != nil {
		t.Error()
	}
	x = int(32)
	if reflect.TypeOf(x).Kind() != reflect.Int {
		t.Error()
	}
	if reflect.TypeOf((*int)(nil)).Kind() != reflect.Ptr {
		t.Error()
	}
	if reflect.TypeOf((*int)(nil)).Elem().Kind() != reflect.Int {
		t.Error()
	}
}

func TestJSONStructTag(t *testing.T) {
	type T struct {
		Str string `json:"hello,world" gorm:"primary,auto"`
		Int int
	}
	typ := reflect.TypeOf(T{})
	okfunc := func(tag reflect.StructTag, key string) bool {
		_, ok := tag.Lookup(key)
		return ok
	}
	for i := 0; i < typ.NumField(); i++ {
		field := typ.Field(i)
		tag := field.Tag
		t.Logf("field: %3s, tag: %s", field.Name, tag)
		t.Logf("            tag: '%s' '%s' '%s'", tag.Get("json"), tag.Get("gorm"), tag.Get("nonexist"))
		t.Logf("            key %s: %v", "json", okfunc(tag, "json"))
		t.Logf("            key %s: %v", "gorm", okfunc(tag, "gorm"))
		t.Logf("            key %s: %v", "nonexist", okfunc(tag, "nonexist"))
	}
}

func TestDeSerialization(t *testing.T) {
	type T struct {
		Str  *string    `json:"str"`
		Int  *int       `json:"int"`
		Time *time.Time `json:"time"`
		Bool *bool      `json:"bool"`
		Heh  *string    `json:"heh"`
	}
	var q T
	var qargs = map[string][]string{
		"str":  {"str1"},
		"int":  {"200"},
		"bool": {"true"},
		"time": {"2018-06-08 00:00:00"},
	}
	val := reflect.ValueOf(&q)
	for k, vs := range qargs {
		fieldval := val.Elem().FieldByNameFunc(func(name string) bool {
			if strings.ToLower(name) == k {
				return true
			}
			return false
		})
		if fieldval.IsValid() {
			switch fieldval.Type().Elem().Kind() {
			case reflect.String:
				fieldval.Set(reflect.ValueOf(&vs[0]))
			case reflect.Bool:
				v, err := strconv.ParseBool(vs[0])
				if err != nil {
					t.Fatalf("parse bool '%s' failed: %s", vs[0], err)
				}
				fieldval.Set(reflect.ValueOf(&v))
			case reflect.Int:
				v, err := strconv.ParseInt(vs[0], 10, 32)
				if err != nil {
					t.Fatalf("parse int '%s' failed: %s", vs[0], err)
				}
				vi := int(v)
				fieldval.Set(reflect.ValueOf(&vi))
			case reflect.Struct:
				if fieldval.Type().Elem() == reflect.TypeOf(time.Time{}) {
					v, err := time.ParseInLocation("2006-01-02 15:04:05", vs[0], time.UTC)
					if err != nil {
						t.Fatalf("parse time '%s' failed: %s", vs[0], err)
					}
					fieldval.Set(reflect.ValueOf(&v))
				}
			}
		}
	}
	t.Logf("%#v", q)
}
