package delayedwork

import (
	"context"
	"sync"
	"time"
)

var (
	maxDuration = time.Duration(290 * 365 * 24 * time.Hour)
	maxTime     = time.Now().Add(maxDuration)
)

type DelayedWorkFunc func(context.Context)
type delayedWork struct {
	id       string
	created  time.Time
	interval time.Duration
	deadline time.Time
	f        DelayedWorkFunc

	last time.Time
}

func (dw *delayedWork) recentTime() time.Time {
	t0 := dw.last.Add(dw.interval)
	if t0.Before(dw.deadline) {
		return t0
	}
	return dw.deadline
}

type DelayedWorkManager struct {
	works   map[string]*delayedWork
	worksMu *sync.Mutex
	sigch   chan struct{}
}

func NewDelayedWorkManager() *DelayedWorkManager {
	dwm := &DelayedWorkManager{
		works:   map[string]*delayedWork{},
		worksMu: &sync.Mutex{},
		sigch:   make(chan struct{}),
	}
	return dwm
}

func (dwm *DelayedWorkManager) pendingCount() int {
	dwm.worksMu.Lock()
	defer dwm.worksMu.Unlock()
	return len(dwm.works)
}

func (dwm *DelayedWorkManager) Start(ctx context.Context) {
	var (
		tmr *time.Timer
		dw  *delayedWork
	)
	for {
		tmr, dw = dwm.calRecentWork(ctx)
		select {
		case <-tmr.C:
			if dw != nil {
				dwm.worksMu.Lock()
				delete(dwm.works, dw.id)
				dwm.worksMu.Unlock()

				go dw.f(ctx)
			}
		case <-dwm.sigch:
			if !tmr.Stop() {
				<-tmr.C
			}
		case <-ctx.Done():
			return
		}
	}
}

func (dwm *DelayedWorkManager) calRecentWork(ctx context.Context) (*time.Timer, *delayedWork) {
	dwm.worksMu.Lock()
	defer dwm.worksMu.Unlock()

	var (
		rt  = maxTime
		rdw *delayedWork
	)
	for _, dw := range dwm.works {
		recent := dw.recentTime()
		if rt.After(recent) {
			rt = recent
			rdw = dw
		}
	}
	return time.NewTimer(rt.Sub(time.Now())), rdw
}

type DelayedWorkRequest struct {
	ID        string
	SoftDelay time.Duration
	HardDelay time.Duration
	Func      DelayedWorkFunc
}

func (dwm *DelayedWorkManager) Submit(ctx context.Context, req DelayedWorkRequest) {
	dwm.worksMu.Lock()
	dw, ok := dwm.works[req.ID]
	if !ok {
		now := time.Now()
		dw = &delayedWork{
			id:       req.ID,
			created:  now,
			interval: req.SoftDelay,
			deadline: now.Add(req.HardDelay),
			f:        req.Func,

			last: now,
		}
		dwm.works[req.ID] = dw
	} else {
		dw.last = time.Now()
	}
	dwm.worksMu.Unlock()

	dwm.sigch <- struct{}{}
}
