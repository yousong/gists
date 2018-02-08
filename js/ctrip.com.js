// 删除“已取消”火车订单
var els = $('a.hideOrder')
for (var i = 0; i < els.length; i++) {
  var el = els[i];
  var oid = $(el).attr('rid');
  console.log(oid);
  ajax.post('http://my.ctrip.com/Home/Ajax/HideOrderHandler.ashx', {'type':'Train', 'orderID':oid})
}
