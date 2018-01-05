// 删一页回复
function del_comment(idx, val) {
	var cid = $(val).attr("data-cid");
	var kv = {
		"reason": "other_reason",
		"cid": cid,
		"other": "",
		"submit": "确定"
	};
	return $.post_withck("remove_comment", kv, function () {
		console.log(idx + " ok")
	});
}
var lnks = $(".lnk-delete-comment");
$.each(lnks, del_comment);


// 只看楼主
if (!localStorage.TidOpHref) { localStorage.setItem("TidOpHref", JSON.stringify({})); } function GetOpHref() { var tid = /\/(\d+)\/?$/.exec(window.location.pathname)[1]; var map = JSON.parse(localStorage.getItem("TidOpHref")); var op_href = map[tid]; if (op_href) { return op_href; } var html = /\?start=\d+/.test(window.location.href) ? document.body : null; if (!html) { $.ajax({ url: window.location.pathname, success: function (d) { html = d; }, async: false }); } op_href = $(".topic-content div.user-face a", html).attr("href"); map[tid] = op_href; localStorage.setItem("TidOpHref", JSON.stringify(map)); return op_href; } var op_href = GetOpHref(); var sel = "div.user-face>a:not([href$='" + op_href + "'])"; $("#comments>li").has(sel).css("display", "none"); 


// 提取 itunes.apple.com 页面视频下载地址URL
var trs = $("tr[role=row][video-preview-url]"); var resl = []; trs.each(function (i, el) { resl.push($(el).attr("video-preview-url") + "," + $(el).attr("preview-title")); }); console.log(resl.join("\n")); 


// 用于将 Vim TOhtml 生成的 html 文件转换为 pdf
//
//        pre { font-family: monospace; color: #000000; background-color: #ffffff; margin: 0 auto; width: 630px; }
//        body { font-family: monospace; color: #000000; background-color: #ffffff; }
//
//    pdf header margin: up 0.4, left and right 0.6; header font Courier New Bold; header font size 8pt; page number format, Page i of n


// 在用户主页上没法执行关注，也没法取消关注。因为`$.post_withck`不存在……嗯，添上
$.post_withck=function (b,e,f,c,d){if($.isFunction(e)){c=f;f=e;e={}}return $.ajax({type:"POST",traditional:typeof d=="undefined"?true:d,url:b,data:$.extend(e,{ck:get_cookie("ck")}),success:f,dataType:c||"text"})}
