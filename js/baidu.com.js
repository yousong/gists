// 清理关注的贴吧
//
$('div.often_forum a[data-fname]').each(function (i,e) {
    var n = $(e).attr('data-fname');
    console.log(n);
    $.post('http://tieba.baidu.com/i/submit/del_concernforum', {'tbs':'xxx', 'fname':n,'is_like':1,'ie':'utf-8','forum_type':'undefined'})
})
