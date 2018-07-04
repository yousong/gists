Name:           admnet
Version:        1.0
Release:        1
BuildArch:      noarch
Summary:        为云平台主机生成静态网络配置

Requires:       initscripts, iproute

%description

当一台虚机还同时绑定有管理网卡、vpc公共服务网卡时，通过dhcp取得的地址虽然正确，但是路由的配置却不一定符合期望

脚本尝试固化此类虚机的网络配置项，实现

 - 所有网卡地址配置正确
 - 默认路由走管理网卡
 - vpc公共服务相关子网路由设置正确
 - 基于网卡源地址的策略路由，例如，FullNAT环境中的NGINX机器，源地址为内网网卡地址、目的地址为公网IP的报文仍从内网网卡出去，而不是通过默认路由走管理网网卡
 - 重启机器配置能不变

%install
mkdir -p %{buildroot}/%{_datadir}/admnet
cp -f $OLDPWD/admnet.sh %{buildroot}/%{_datadir}/admnet


%files
%defattr(-,root,root,-)
%{_datadir}/admnet/*


%changelog
* Thu Oct 03 2017 Yousong Zhou 1.0
- initial
