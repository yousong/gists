package main

import "testing"
import (
	"fmt"
	"github.com/sirupsen/logrus"
	"io/ioutil"
	"os"
	"path/filepath"
)

type LogFileHook struct {
	FileDir  string
	FileName string
	fullPath string
	file     *os.File
}

func (h *LogFileHook) Init() error {
	if fi, err := os.Lstat(h.FileDir); err != nil {
		if os.IsNotExist(err) {
			os.MkdirAll(h.FileDir, 0755)
		} else {
			return fmt.Errorf("Lstat %s: %s", h.FileDir, err)
		}
	} else if !fi.Mode().IsDir() {
		return fmt.Errorf("%s exists and it's not a directory", h.FileDir)
	}

	h.fullPath = filepath.Join(h.FileDir, h.FileName)
	file, err := os.OpenFile(h.fullPath, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0755)
	if err != nil {
		return fmt.Errorf("OpenFile %s: %s", h.fullPath, err)
	}
	h.file = file
	return nil
}

func (h *LogFileHook) DeInit() {
	h.file.Close()
}

func (h *LogFileHook) Levels() []logrus.Level {
	return logrus.AllLevels
}

func (h *LogFileHook) Fire(e *logrus.Entry) error {
	if b, err := e.Logger.Formatter.Format(e); err != nil {
		return err
	} else {
		h.file.Write(b)
		return nil
	}
}

// rotate by size
type LogFileRotateHook struct {
	LogFileHook
	RotateNum  int
	RotateSize int64
	filePaths  []string
}

func (h *LogFileRotateHook) Init() error {
	if err := h.LogFileHook.Init(); err != nil {
		return err
	}
	h.filePaths = make([]string, h.RotateNum)
	for i := 1; i < h.RotateNum; i++ {
		fileName := fmt.Sprintf("%s.%d", h.FileName, i)
		filePath := filepath.Join(h.FileDir, fileName)
		h.filePaths[i] = filePath
	}
	h.filePaths[0] = filepath.Join(h.FileDir, h.FileName)
	return nil
}

func (h *LogFileRotateHook) rotate() {
	for i := h.RotateNum - 1; i > 0; i-- {
		filePath0 := h.filePaths[i-1]
		if _, err := os.Lstat(filePath0); err != nil {
			continue
		}
		filePath1 := h.filePaths[i]
		os.Rename(filePath0, filePath1)
	}
	h.file.Close()
	h.LogFileHook.Init()
}

func (h *LogFileRotateHook) Fire(e *logrus.Entry) error {
	if err := h.LogFileHook.Fire(e); err != nil {
		return err
	}
	if fi, err := os.Lstat(h.filePaths[0]); err != nil {
		return err
	} else if fi.Size() >= h.RotateSize {
		h.rotate()
	}
	return nil
}

func TestLogFile(t *testing.T) {
	logFileHook := LogFileHook{
		FileDir:  "/tmp/log",
		FileName: "spf.log",
	}
	logFileHook.Init()
	defer logFileHook.DeInit()
	l := logrus.New()
	l.AddHook(&logFileHook)
	l.Infof("hello, world")
	l.Debugf("hello, world?")
}

func TestLogFileRotate(t *testing.T) {
	logFileHook := LogFileRotateHook{
		LogFileHook: LogFileHook{
			FileDir:  "/tmp/log",
			FileName: "spf.rot.log",
		},
		RotateNum:  10,
		RotateSize: 1024,
	}
	logFileHook.Init()
	defer logFileHook.DeInit()
	l := logrus.New()
	l.Out = ioutil.Discard
	l.AddHook(&logFileHook)

	for i := 0; i < 3828; i++ {
		l.Infof("%d", i)
	}
}
