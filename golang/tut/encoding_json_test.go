package tut

import "testing"
import (
	"encoding/json"
	"reflect"
)

type OwnerTenantOption struct {
	TenantId string `json:"tenant_id"`
	UserId   string `json:"user_id"`
}

type VpcOption struct {
	Vni int `json:"vni"`
}

type VpcCreateOption struct {
	Owner OwnerTenantOption `json:"owner"`
	Vpc   VpcOption         `json:"vpc"`
}

func TestNestedJSON(t *testing.T) {
	var j = []byte(`{"owner": {"tenant_id": "tenant_me"},"vpc": {"vni": 123}}`)
	var opt = &VpcCreateOption{}
	var err error
	err = json.Unmarshal(j, opt)
	if err != nil {
		t.Fatalf("unmarshal error: %s", err)
	}
	if opt.Owner.TenantId != "tenant_me" || opt.Vpc.Vni != 123 {
		t.Fatalf("wrong unmarshalled value: %v", opt)
	}
}
