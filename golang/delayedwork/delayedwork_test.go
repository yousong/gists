package delayedwork

import (
	"context"
	"sync/atomic"
	"testing"
	"time"
)

type delayedWorkTester struct {
	count int32
}

func (dwt *delayedWorkTester) do(t *testing.T) {
	atomic.AddInt32(&dwt.count, 1)
}

func drainDwm(ctx context.Context, dwm *DelayedWorkManager) {
	tick := time.NewTicker(10 * time.Millisecond)
	defer tick.Stop()
	for {
		select {
		case <-tick.C:
			count := dwm.pendingCount()
			if count == 0 {
				return
			}
		case <-ctx.Done():
			return
		}
	}
}

func TestDelayedWork(t *testing.T) {
	t.Run("one-soft", func(t *testing.T) {
		ctx := context.Background()
		ctx, cancelFunc := context.WithTimeout(ctx, 10*time.Second)
		defer cancelFunc()

		dwm := NewDelayedWorkManager()
		go dwm.Start(ctx)

		var (
			startTime = time.Now()
			dwt       delayedWorkTester
			req       = DelayedWorkRequest{
				ID:        "1",
				SoftDelay: time.Second,
				HardDelay: 3 * time.Second,
				Func: func(ctx context.Context) {
					dwt.do(t)
				},
			}
		)
		dwm.Submit(ctx, req)
		time.Sleep(500 * time.Millisecond)
		dwm.Submit(ctx, req)
		drainDwm(ctx, dwm)
		if dwt.count != 1 {
			t.Errorf("got %d, want 1", dwt.count)
		}
		if elp := time.Since(startTime); elp <= 1500*time.Millisecond {
			t.Errorf("elapse time too short: %s", elp)
		} else if elp >= 1550*time.Millisecond {
			t.Errorf("elapse time too long: %s", elp)
		}
	})
	t.Run("one-hard", func(t *testing.T) {
		ctx := context.Background()
		ctx, cancelFunc := context.WithTimeout(ctx, 10*time.Second)
		defer cancelFunc()

		dwm := NewDelayedWorkManager()
		go dwm.Start(ctx)

		var (
			startTime = time.Now()
			dwt       delayedWorkTester
			req       = DelayedWorkRequest{
				ID:        "1",
				SoftDelay: time.Second,
				HardDelay: 3 * time.Second,
				Func: func(ctx context.Context) {
					dwt.do(t)
				},
			}
		)
		dwm.Submit(ctx, req)
		for i := 0; i < 17; i++ {
			time.Sleep(200 * time.Millisecond)
			dwm.Submit(ctx, req)
		}
		drainDwm(ctx, dwm)
		if dwt.count != 2 {
			t.Errorf("got %d, want 2", dwt.count)
		}
		if elp := time.Since(startTime); elp <= 4400*time.Millisecond {
			t.Errorf("elapse time too short: %s", elp)
		} else if elp >= 4450*time.Millisecond {
			t.Errorf("elapse time too long: %s", elp)
		}
	})
}
