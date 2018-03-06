package main

import (
	"fmt"
	"time"
)

func main() {
	{
		// struct Time has fields for both wall time and monotonic time
		timeLoc := time.Now()
		fmt.Printf("%s\n", timeLoc)
	}

	// Mon Jan 2 15:04:05 -0700 MST 2006
	timeFmt := "2006-01-02 15:04:05"
	locTok, _ := time.LoadLocation("Asia/Tokyo")
	{
		// Parse() and Format()
		// Location conversion
		timeStr := "2018-02-26 11:38:58"
		//
		// UTC if time zone indicator is missing
		timeUtc, _ := time.Parse(timeFmt, timeStr)
		timeLoc, _ := time.ParseInLocation(timeFmt, timeStr, time.Local)
		timeTok := timeLoc.In(locTok)
		fmt.Printf("%s\n", timeUtc)
		fmt.Printf("%s\n", timeLoc)
		fmt.Printf("%s\n", timeTok)

		timeStr_ := timeTok.Format(timeFmt)
		fmt.Printf("%s\n", timeStr_)
	}

	{
		// POSIX timestamp conversion
		var sec int64 = 1519616929
		var nsec int64 = 1
		timeLoc := time.Unix(sec, nsec)
		sec = timeLoc.Unix()
		nsec = timeLoc.UnixNano()
		fmt.Printf("%s\n", timeLoc)
		fmt.Printf("sec: %d, nsec: %d\n", sec, nsec)
	}
	{
		// Duration
		timeFmt := "Mon Jan 2 15:04:05 MST 2006"
		timeStr := "Tue Mar  6 11:00:10 CST 2018"
		timeLoc, _ := time.Parse(timeFmt, timeStr)
		// No definition for units of Day or larger
		dur := 38*24*time.Hour + 18*time.Hour + 19*time.Minute
		timeBoot := timeLoc.Add(-dur)
		fmt.Printf("timeBoot: %s\n", timeBoot)
	}
}
