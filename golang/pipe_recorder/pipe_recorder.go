package pipe_recorder

import (
	"io"
	"sync"
)

type PipeRecorder struct {
	data    []byte
	cond    *sync.Cond
	written int
	done    bool
	mixer   Mixer
}

func NewPipeRecorder() *PipeRecorder {
	p := &PipeRecorder{
		cond: sync.NewCond(&sync.Mutex{}),
	}
	return p
}

// Write implements io.Writer
func (pr *PipeRecorder) Write(p []byte) (int, error) {
	pr.cond.L.Lock()
	pr.data = append(pr.data, p...)
	if pr.mixer != nil {
		pr.mixer.Mix(p)
	}
	pr.cond.L.Unlock()
	pr.cond.Signal()
	return len(p), nil
}

// Write implements io.Reader
func (pr *PipeRecorder) Read(p []byte) (int, error) {
	pr.cond.L.Lock()
	defer pr.cond.L.Unlock()
	for pr.written >= len(pr.data) && !pr.done {
		pr.cond.Wait()
	}
	n := copy(p, pr.data[pr.written:])
	pr.written += n
	if !pr.done {
		return n, nil
	} else {
		return n, io.EOF
	}
}

// Pipe pipes and records data transfers between r and w
func (pr *PipeRecorder) Pipe(w io.Writer, r io.Reader) (int64, error) {
	go func() {
		io.Copy(pr, r)
		pr.cond.L.Lock()
		pr.done = true
		pr.cond.L.Unlock()
		pr.cond.Signal()
	}()
	return io.Copy(w, pr)
}

// Bytes returns the recorded data
func (pr *PipeRecorder) Bytes() []byte {
	pr.cond.L.Lock()
	defer pr.cond.L.Unlock()
	return pr.data
}

type Mixer interface {
	// Mix passes the data to Mixer
	Mix([]byte)
}

type PipeMixer struct {
	data  []byte
	mutex *sync.Mutex
}

func NewPipeMixer() *PipeMixer {
	pm := &PipeMixer{
		mutex: &sync.Mutex{},
	}
	return pm
}

// AddPipe tells PipeRecorder to pass what it receives to PipeMixer
func (pm *PipeMixer) AddPipeRecorder(pr *PipeRecorder) {
	pr.mixer = pm
}

// Mix implements Mixer interface
func (pm *PipeMixer) Mix(p []byte) {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()
	pm.data = append(pm.data, p...)
}

// Bytes returns the mixed data
func (pm *PipeMixer) Bytes() []byte {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()
	return pm.data
}
