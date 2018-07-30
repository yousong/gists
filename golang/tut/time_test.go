package tut

import "testing"
import (
	"time"
)

func TestNow(t *testing.T) {
	// struct Time has fields for both wall time and monotonic time
	timeLoc := time.Now()
	t.Logf("now: %s", timeLoc)
}

func TestParseFormat(t *testing.T) {

	// Mon Jan 2 15:04:05 -0700 MST 2006
	timeFmt := "2006-01-02 15:04:05"
	locTok, _ := time.LoadLocation("Asia/Tokyo")

	// Parse() and Format()
	// Location conversion
	timeStr := "2018-02-26 11:38:58"
	//
	// UTC if time zone indicator is missing
	timeUtc, _ := time.Parse(timeFmt, timeStr)
	timeLoc, _ := time.ParseInLocation(timeFmt, timeStr, time.Local)
	timeTok := timeLoc.In(locTok)
	t.Logf("%s", timeUtc)
	t.Logf("%s", timeLoc)
	t.Logf("%s", timeTok)

	timeStr_ := timeTok.Format(timeFmt)
	t.Logf("%s", timeStr_)
}

func TestPOSIXConversion(t *testing.T) {
	// POSIX timestamp conversion
	var sec int64 = 1519616929
	var nsec int64 = 1
	timeLoc := time.Unix(sec, nsec)
	sec = timeLoc.Unix()
	nsec = timeLoc.UnixNano()
	t.Logf("%s", timeLoc)
	t.Logf("sec: %d, nsec: %d", sec, nsec)
}

func TestDuration(t *testing.T) {
	// Duration
	timeFmt := "Mon Jan 2 15:04:05 MST 2006"
	timeStr := "Tue Mar  6 11:00:10 CST 2018"
	timeLoc, _ := time.Parse(timeFmt, timeStr)
	// No definition for units of Day or larger
	dur := 38*24*time.Hour + 18*time.Hour + 19*time.Minute
	timeBoot := timeLoc.Add(-dur)
	t.Logf("timeBoot: %s", timeBoot)
}

func TestTimer(t *testing.T) {
	var rv bool
	tm := time.NewTimer(5 * time.Second)
	rv = tm.Stop()
	if !rv {
		t.Errorf("should return true if not already expired/stopped before calling Stop()")
	}
	rv = tm.Stop()
	if rv {
		t.Errorf("should return false on already stopped.")
	}
	<-tm.C
}
