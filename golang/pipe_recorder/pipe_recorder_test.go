package pipe_recorder

import (
	"bytes"
	"fmt"
	"io"
	"strings"
	"sync"
	"testing"
)

func newWriter() io.Writer {
	return &bytes.Buffer{}
}

func newReader(buf []byte) io.Reader {
	return bytes.NewBuffer(buf)
}

func TestPipeRecorder(t *testing.T) {
	pm := NewPipeMixer()
	wg := &sync.WaitGroup{}
	for i := 0; i < 32; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			want := fmt.Sprintf("round%d,", i)
			w := newWriter()
			r := newReader([]byte(want))
			pr := NewPipeRecorder()
			pm.AddPipeRecorder(pr)
			pr.Pipe(w, r)
			got := w.(*bytes.Buffer).String()
			if got != want {
				t.Errorf("%d: want %q, got %q", i, want, got)
			}
		}(i)
	}
	wg.Wait()
	got := string(pm.Bytes())
	for i := 0; i < 32; i++ {
		want := fmt.Sprintf("round%d,", i)
		if !strings.Contains(got, want) {
			t.Errorf("want %q, not in %q", want, got)
		}
	}
}
