package tut

import "testing"
import (
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
)

type M struct {
	gorm.Model
	Vni uint
}

func openDb(t *testing.T) *gorm.DB {
	db, err := gorm.Open("mysql", "root:2130e20349949406f8f1@tcp(localhost:3306)/test?parseTime=true")
	if err != nil {
		t.Fatalf("open db failed: %s", err)
	}
	//db.LogMode(true)
	db.DropTable(&M{})
	db.AutoMigrate(&M{})
	return db
}

func TestGormBasic(t *testing.T) {
	v := []*M{&M{Vni: 1000}, &M{Vni: 1001}}
	db := openDb(t)
	for _, obj := range v {
		db.Create(obj)
	}

	var obj *M
	for _, obj = range v {
		var outv M // primary key (id) needs to be zero/null.
		db.Take(&outv, "vni = ?", obj.Vni)
		// time in obj has subsecond resolution, while it's lost in the db
		if obj.Vni != outv.Vni {
			t.Errorf("not equal: expect: %v, queried: %v", obj, outv)
		}
	}
	var outv = M{Vni: obj.Vni}
	db.Take(&outv, "vni = 100")
	if outv.Vni != obj.Vni {
		t.Errorf("touched: %v", outv)
	}
}
