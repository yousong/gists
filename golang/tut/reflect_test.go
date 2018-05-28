package tut

import (
	"reflect"
	"sync"
	"testing"
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
