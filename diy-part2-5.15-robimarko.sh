#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2-5.15-robimarko.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# https://github.com/deplives/OpenWrt-CI-RC/blob/main/second.sh
# https://github.com/jarod360/Redmi_AX6/blob/main/diy-part2.sh

COMMIT_COMMENT=$1
if [ -z "$COMMIT_COMMENT" ]; then
    COMMIT_COMMENT='Unknown'
fi
WIFI_SSID=$2
if [ -z "$WIFI_SSID" ]; then
    WIFI_SSID='Unknown'
fi
WIFI_KEY=$3
if [ -z "$WIFI_KEY" ]; then
    WIFI_KEY='Unknown'
fi

# Modify default timezone
echo 'Modify default timezone...'
sed -i "s/'UTC'/'CST-8'\n\t\tset system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

# 修正连接数（by ベ七秒鱼ベ）
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=165535' package/base-files/files/etc/sysctl.conf

# 设置密码为password
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/base-files/files/etc/shadow

# Ax6修改无线国家代码、开关、命名、加密方式及密码
sed -i 's/radio${devidx}.disabled=1/radio${devidx}.country=US\n\t\t\tset wireless.radio${devidx}.disabled=0/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i "s/radio\${devidx}.ssid=OpenWrt/radio0.ssid=${WIFI_SSID}\n\t\t\tset wireless.default_radio1.ssid=${WIFI_SSID}_2.4G/g" package/kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i "s/radio\${devidx}.encryption=none/radio\${devidx}.encryption=psk-mixed\n\t\t\tset wireless.default_radio\${devidx}.key=${WIFI_KEY}\n\t\t\tset wireless.default_radio\${devidx}.iw_qos_map_set=none/g" package/kernel/mac80211/files/lib/wifi/mac80211.sh

# hijack dns queries to router(firewall)
sed -i '/REDIRECT --to-ports 53/d' package/network/config/firewall/files/firewall.user
# 把局域网内所有客户端对外ipv4的53端口查询请求，都劫持指向路由器(iptables -n -t nat -L PREROUTING -v --line-number)(iptables -t nat -D PREROUTING 2)
echo 'iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> package/network/config/firewall/files/firewall.user
echo 'iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> package/network/config/firewall/files/firewall.user
# 把局域网内所有客户端对外ipv6的53端口查询请求，都劫持指向路由器(ip6tables -n -t nat -L PREROUTING -v --line-number)(ip6tables -t nat -D PREROUTING 1)
echo '[ -n "$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> package/network/config/firewall/files/firewall.user
echo '[ -n "$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> package/network/config/firewall/files/firewall.user

# 修改初始化配置
touch package/base-files/files/etc/custom.tag
sed -i '/exit 0/d' package/base-files/files/etc/rc.local
cat >> package/base-files/files/etc/rc.local << EOFEOF
PPPOE_USERNAME=""
PPPOE_PASSWORD=""
DDNS_LOOKUP_HOST=""
DDNS_DOMAIN=""
DDNS_USERNAME=""
DDNS_PASSWORD=""
SSR_SUBSCRIBE_URL=""
SSR_SAVE_WORDS=""
SSR_GLOBAL_SERVER=""
refresh_ad_conf() {
    sleep 30
    # 检查拦截列表
    # grep -v "\."                     /etc/smartdns/ad.conf
    # grep "address /api.xiaomi.com/#" /etc/smartdns/ad.conf
    # grep "cnbj2.fds.api.xiaomi.com"  /etc/smartdns/ad.conf
    # grep "*"                         /etc/smartdns/ad.conf
    # grep "address /\."               /etc/smartdns/ad.conf
    # grep "\./#"                      /etc/smartdns/ad.conf
    # grep "pv.kuaizhan.com"           /etc/smartdns/ad.conf
    # grep "changyan.sohu.com"         /etc/smartdns/ad.conf
    # grep "address /.*#.*/#"          /etc/smartdns/ad.conf
    # grep "address /.*[ ].*/#"        /etc/smartdns/ad.conf
    cat > /etc/smartdns/aaa.conf << EOF
address /ad.xiaomi.com/#
address /ad1.xiaomi.com/#
address /ad.mi.com/#
address /tat.pandora.xiaomi.com/#
address /fix.hpplay.cn/#
address /rps.hpplay.cn/#
address /imdns.hpplay.cn/#
address /devicemgr.hpplay.cn/#
address /rp.hpplay.cn/#
address /tvapp.hpplay.cn/#
address /pin.hpplay.cn/#
address /adcdn.hpplay.cn/#
address /sl.hpplay.cn/#
address /vipauth.hpplay.cn/#
address /vipsdkauth.hpplay.cn/#
address /sdkauth.hpplay.cn/#
address /adeng.hpplay.cn/#
address /conf.hpplay.cn/#
address /image.hpplay.cn/#
address /hotupgrade.hpplay.cn/#
address /t7z.cupid.ptqy.gitv.tv/#
address /cloud.hpplay.cn/#
address /ad.hpplay.cn/#
address /adc.hpplay.cn/#
address /gslb.hpplay.cn/#
address /cdn1.hpplay.cn/#
address /ftp.hpplay.com.cn/#
address /rp.hpplay.com.cn/#
address /cdn.hpplay.com.cn/#
address /userapi.hpplay.com.cn/#
address /leboapi.hpplay.com.cn/#
address /api.hpplay.com.cn/#
address /h5.hpplay.com.cn/#
address /hpplay.cdn.cibn.cc/#
address /logonext.tv.kuyun.com/#
address /config.kuyun.com/#
address /f5.market.xiaomi.com/#
address /f4.market.xiaomi.com/#
address /f3.market.xiaomi.com/#
address /f2.market.xiaomi.com/#
address /f1.market.xiaomi.com/#
address /video.market.xiaomi.com/#
address /f5.market.mi-img.com/#
address /f4.market.mi-img.com/#
address /f3.market.mi-img.com/#
address /f2.market.mi-img.com/#
address /f1.market.mi-img.com/#
address /519332DA.dr.youme.im/#
address /aiseet.aa.aisee.tv/#
address /api.hismarttv.com/#
address /e.dangbei.com/#
address /g.dtv.cn.miaozhan.com/#
address /i.mxplayer.j2inter.com/#
address /icsc.sps.expressplay.cn/#
address /misc.in.duokanbox.com/#
address /natdetection.onethingpcs.com/#
address /p2sdk1.mona.p2cdn.com/#
address /pandora.mi.com/#
address /loc.map.baidu.com/#
address /ofloc.map.baidu.com/#
address /si.super-ssp.tv/#
address /sr.super-ssp.tv/#
address /yt3.ggpht.com/#
address /tv.aiseet.atianqi.com/#
address /vv.play.aiseet.atianqi.com/#
address /userapi.hpplay.cn/#
address /pay.hpplay.cn/#
address /tvapi.hpplay.com.cn/#
address /switch.hpplay.com.cn/#
address /lic.hpplay.com.cn/#
address /data.hpplay.com.cn/#
address /upgrade.ptmi.gitv.tv/#
address /appstore.ptmi.gitv.tv/#
address /gamecenter.ptmi.gitv.tv/#
address /p2pupdate.inter.ptqy.gitv.tv/#
address /data.video.ptqy.gitv.tv/#
address /auth.api.gitv.tv/#
address /tv.weixin.pandora.xiaomi.com/#
address /tvmanager.pandora.xiaomi.com/#
address /tvmgr.pandora.xiaomi.com/#
address /redirect.pandora.xiaomi.com/#
address /package.cdn.pandora.xiaomi.com/#
address /ota.cdn.pandora.xiaomi.com/#
address /milink.pandora.xiaomi.com/#
address /appstore.cdn.pandora.xiaomi.com/#
address /appstore.pandora.xiaomi.com/#
address /assistant.pandora.xiaomi.com/#
address /broker.mqtt.pandora.xiaomi.com/#
address /staging.ai.api.xiaomi.com/#
address /as.xiaomi.com/#
address /d1.xiaomi.com/#
address /market.xiaomi.com/#
address /file.xmpush.xiaomi.com/#
address /tracker.live.xycdn.com/#
EOF
    # -t 重试次数 -T 超时时间 -c 断点续传 -P 下载到指定路径 -q 不显示执行过程 -O 以指定的文件名保存 -O- 以'-'作为file参数，将数据打印到标准输出，通常为控制台
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/anti-ad-smartdns.conf >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/anti-ad-smartdns.conf" ]; then
        grep "^address" /etc/smartdns/anti-ad-smartdns.conf | grep -v "address /pv.kuaizhan.com/#" | grep -v "address /changyan.sohu.com/#" >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/anti-ad-smartdns.conf
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/neodevpro/neodevhost/master/smartdns.conf >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/smartdns.conf" ]; then
        grep "^address" /etc/smartdns/smartdns.conf | grep -v "address /changyan.sohu.com/#" >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/smartdns.conf
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/jdlingyu/ad-wars/master/sha_ad_hosts >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/sha_ad_hosts" ]; then
        grep "^127" /etc/smartdns/sha_ad_hosts > /etc/smartdns/host
        sed -i '1d' /etc/smartdns/host
        sed -i 's/127.0.0.1 \*\./127.0.0.1 /g' /etc/smartdns/host
        sed -i 's/127.0.0.1 /address \//g;s/$/\/#/g' /etc/smartdns/host
        cat /etc/smartdns/host | grep -v "address /changyan.sohu.com/#" >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/sha_ad_hosts
        rm -f /etc/smartdns/host
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/hosts.txt" ]; then
        grep "^127" /etc/smartdns/hosts.txt > /etc/smartdns/host
        sed -i '1d' /etc/smartdns/host
        sed -i 's/127.0.0.1 /address \//g;s/$/\/#/g' /etc/smartdns/host
        cat /etc/smartdns/host >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/hosts.txt
        rm -f /etc/smartdns/host
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/FuckNoMotherCompanyAlliance/Fuck_CJMarketing_hosts/master/hosts >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/hosts" ]; then
        grep "^0" /etc/smartdns/hosts | tr -d "\r" > /etc/smartdns/host
        sed -i 's/www.xitongqingli.com /www.xitongqingli.com/g' /etc/smartdns/host
        sed -i 's/0.0.0.0 /address \//g;s/$/\/#/g' /etc/smartdns/host
        cat /etc/smartdns/host >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/hosts
        rm -f /etc/smartdns/host
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/Goooler/1024_hosts/master/hosts >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/hosts" ]; then
        grep "^127" /etc/smartdns/hosts | tr -d "\r" | sed 's/\.$//g' > /etc/smartdns/host
        sed -i 's/127.0.0.1 /address \//g;s/$/\/#/g' /etc/smartdns/host
        cat /etc/smartdns/host >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/hosts
        rm -f /etc/smartdns/host
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/VeleSila/yhosts/master/hosts.txt >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/hosts.txt" ]; then
        grep "^0" /etc/smartdns/hosts.txt | grep -v "0.0.0.0 XiaoQiang" | grep -v "0.0.0.0 localhost" | sed 's/\.$//g' > /etc/smartdns/host.txt
        sed -i 's/0.0.0.0 /address \//g;s/$/\/#/g' /etc/smartdns/host.txt
        cat /etc/smartdns/host.txt >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/hosts.txt
        rm -f /etc/smartdns/host.txt
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-social/hosts >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/hosts" ]; then
        grep "^0" /etc/smartdns/hosts | sed 's/[ ]*#.*$//g' > /etc/smartdns/host.txt
        sed -i '1d' /etc/smartdns/host.txt
        sed -i 's/0.0.0.0 /address \//g;s/$/\/#/g' /etc/smartdns/host.txt
        cat /etc/smartdns/host.txt | grep -v "address /inf/#" | grep -v "address /fe/#" | grep -v "address /ff/#" >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/hosts
        rm -f /etc/smartdns/host.txt
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/reject-list.txt >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/reject-list.txt" ]; then
        sed -i 's/^/address \//g;s/$/\/#/g' /etc/smartdns/reject-list.txt
        cat /etc/smartdns/reject-list.txt | grep -v "address /pv.kuaizhan.com/#" >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/reject-list.txt
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/win-spy.txt >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/win-spy.txt" ]; then
        sed -i 's/^/address \//g;s/$/\/#/g' /etc/smartdns/win-spy.txt
        cat /etc/smartdns/win-spy.txt >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/win-spy.txt
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/win-update.txt >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/win-update.txt" ]; then
        sed -i 's/^/address \//g;s/$/\/#/g' /etc/smartdns/win-update.txt
        cat /etc/smartdns/win-update.txt >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/win-update.txt
    fi
    wget -t 1 -T 10 -c -P /etc/smartdns https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/win-extra.txt >> /etc/custom.tag 2>&1
    if [ -f "/etc/smartdns/win-extra.txt" ]; then
        sed -i 's/^/address \//g;s/$/\/#/g' /etc/smartdns/win-extra.txt
        cat /etc/smartdns/win-extra.txt >> /etc/smartdns/aaa.conf
        rm -f /etc/smartdns/win-extra.txt
    fi
    sort -u /etc/smartdns/aaa.conf > /etc/smartdns/ad.conf
    rm -f /etc/smartdns/aaa.conf
    /etc/init.d/smartdns restart >> /etc/custom.tag 2>&1
    echo "smartdns block ad domain list finish" >> /etc/custom.tag
}
init_custom_config() {
    sleep 30
    uci set network.wan.proto='pppoe'
    uci set network.wan.username="\${PPPOE_USERNAME}"
    uci set network.wan.password="\${PPPOE_PASSWORD}"
    uci set network.wan.ipv6='auto'
    uci set network.wan.peerdns='0'
    uci add_list network.wan.dns='127.0.0.1'
    uci set network.modem=interface
    uci set network.modem.proto='dhcp'
    uci set network.modem.device='eth0'
    uci set network.modem.defaultroute='0'
    uci set network.modem.peerdns='0'
    uci set network.modem.delegate='0'
    uci commit network
    /etc/init.d/network restart >> /etc/custom.tag 2>&1
    echo "network finish" >> /etc/custom.tag
    sleep 30
    # hijack dns queries to router(firewall4)
    # 把局域网内所有客户端对外ipv4和ipv6的53端口查询请求，都劫持指向路由器(nft list chain inet fw4 dns-redirect)(nft delete chain inet fw4 dns-redirect)
    cat >> /etc/nftables.d/10-custom-filter-chains.nft << EOF
chain dns-redirect {
    type nat hook prerouting priority -105;
    udp dport 53 counter redirect to :53
    tcp dport 53 counter redirect to :53
}
EOF
    uci add_list firewall.cfg03dc81.network='modem'
    uci commit firewall
    /etc/init.d/firewall restart >> /etc/custom.tag 2>&1
    echo "firewall finish" >> /etc/custom.tag
    uci set ttyd.cfg01a8ea.ssl='1'
    uci set ttyd.cfg01a8ea.ssl_cert='/etc/nginx/conf.d/_lan.crt'
    uci set ttyd.cfg01a8ea.ssl_key='/etc/nginx/conf.d/_lan.key'
    uci commit ttyd
    /etc/init.d/ttyd restart >> /etc/custom.tag 2>&1
    echo "ttyd finish" >> /etc/custom.tag
    uci set autoreboot.cfg01f8be.enable='1'
    uci set autoreboot.cfg01f8be.week='7'
    uci set autoreboot.cfg01f8be.hour='3'
    uci set autoreboot.cfg01f8be.minute='30'
    uci commit autoreboot
    /etc/init.d/autoreboot restart >> /etc/custom.tag 2>&1
    echo "autoreboot finish" >> /etc/custom.tag
    sleep 30
    uci set smartdns.cfg016bb1.enabled='1'
    uci set smartdns.cfg016bb1.server_name='smartdns'
    uci set smartdns.cfg016bb1.port='6053'
    uci set smartdns.cfg016bb1.tcp_server='0'
    uci set smartdns.cfg016bb1.ipv6_server='0'
    uci set smartdns.cfg016bb1.dualstack_ip_selection='1'
    uci set smartdns.cfg016bb1.prefetch_domain='1'
    uci set smartdns.cfg016bb1.serve_expired='1'
    uci set smartdns.cfg016bb1.redirect='dnsmasq-upstream'
    uci set smartdns.cfg016bb1.cache_size='16384'
    uci set smartdns.cfg016bb1.rr_ttl='30'
    uci set smartdns.cfg016bb1.rr_ttl_min='30'
    uci set smartdns.cfg016bb1.rr_ttl_max='300'
    uci set smartdns.cfg016bb1.seconddns_enabled='1'
    uci set smartdns.cfg016bb1.seconddns_port='5335'
    uci set smartdns.cfg016bb1.seconddns_tcp_server='0'
    uci set smartdns.cfg016bb1.seconddns_server_group='oversea'
    uci set smartdns.cfg016bb1.seconddns_no_speed_check='1'
    uci set smartdns.cfg016bb1.seconddns_no_rule_addr='0'
    uci set smartdns.cfg016bb1.seconddns_no_rule_nameserver='1'
    uci set smartdns.cfg016bb1.seconddns_no_rule_ipset='0'
    uci set smartdns.cfg016bb1.seconddns_no_rule_soa='0'
    uci set smartdns.cfg016bb1.seconddns_no_dualstack_selection='1'
    uci set smartdns.cfg016bb1.seconddns_no_cache='1'
    uci set smartdns.cfg016bb1.force_aaaa_soa='1'
    uci set smartdns.cfg016bb1.coredump='0'
    uci del smartdns.cfg016bb1.old_redirect
    uci add_list smartdns.cfg016bb1.old_redirect='dnsmasq-upstream'
    uci del smartdns.cfg016bb1.old_port
    uci add_list smartdns.cfg016bb1.old_port='6053'
    uci del smartdns.cfg016bb1.old_enabled
    uci add_list smartdns.cfg016bb1.old_enabled='1'
    uci commit smartdns
    touch /etc/smartdns/ad.conf
    cat >> /etc/smartdns/custom.conf << EOF
# Include another configuration options
conf-file /etc/smartdns/ad.conf
# remote dns server list
server 114.114.114.114 -group china #114DNS
server 114.114.115.115 -group china #114DNS
server 119.29.29.29 -group china #TencentDNS
server 182.254.116.116 -group china #TencentDNS
server 2402:4e00:: -group china #TencentDNS
server-tls 223.5.5.5 -group china -group bootstrap #AlibabaDNS
server-tls 223.6.6.6 -group china -group bootstrap #AlibabaDNS
server-tls 2400:3200::1 -group china -group bootstrap #AlibabaDNS
server-tls 2400:3200:baba::1 -group china -group bootstrap #AlibabaDNS
server 180.76.76.76 -group china #BaiduDNS
server 2400:da00::6666 -group china #BaiduDNS
nameserver /cloudflare-dns.com/bootstrap
nameserver /dns.google/bootstrap
nameserver /doh.opendns.com/bootstrap
server-tls 1.1.1.1 -group oversea -exclude-default-group #CloudflareDNS
server-tls 1.0.0.1 -group oversea -exclude-default-group #CloudflareDNS
server-https https://cloudflare-dns.com/dns-query -group oversea -exclude-default-group #CloudflareDNS
server-tls 8.8.8.8 -group oversea -exclude-default-group #GoogleDNS
server-tls 8.8.4.4 -group oversea -exclude-default-group #GoogleDNS
server-https https://dns.google/dns-query -group oversea -exclude-default-group #GoogleDNS
server-tls 208.67.222.222 -group oversea -exclude-default-group #OpenDNS
server-tls 208.67.220.220 -group oversea -exclude-default-group #OpenDNS
server-https https://doh.opendns.com/dns-query -group oversea -exclude-default-group #OpenDNS
EOF
    /etc/init.d/smartdns restart >> /etc/custom.tag 2>&1
    echo "smartdns remote dns server list finish" >> /etc/custom.tag
    sleep 30
    uci set ddns.test=service
    uci set ddns.test.service_name='cloudflare.com-v4'
    uci set ddns.test.use_ipv6='1'
    uci set ddns.test.enabled='1'
    uci set ddns.test.lookup_host="\${DDNS_LOOKUP_HOST}"
    uci set ddns.test.domain="\${DDNS_DOMAIN}"
    uci set ddns.test.username="\${DDNS_USERNAME}"
    uci set ddns.test.password="\${DDNS_PASSWORD}"
    uci set ddns.test.ip_source='network'
    uci set ddns.test.ip_network='wan_6'
    uci set ddns.test.interface='wan_6'
    uci set ddns.test.use_syslog='2'
    uci set ddns.test.check_unit='minutes'
    uci set ddns.test.force_unit='minutes'
    uci set ddns.test.retry_unit='seconds'
    uci commit ddns
    /etc/init.d/ddns restart >> /etc/custom.tag 2>&1
    echo "ddns finish" >> /etc/custom.tag
    echo "cloudflare-dns.com" >> /etc/ssrplus/black.list
    echo "dns.google" >> /etc/ssrplus/black.list
    echo "doh.opendns.com" >> /etc/ssrplus/black.list
    uci add_list shadowsocksr.cfg034417.wan_fw_ips='1.1.1.1'
    uci add_list shadowsocksr.cfg034417.wan_fw_ips='1.0.0.1'
    uci add_list shadowsocksr.cfg034417.wan_fw_ips='8.8.8.8'
    uci add_list shadowsocksr.cfg034417.wan_fw_ips='8.8.4.4'
    uci add_list shadowsocksr.cfg034417.wan_fw_ips='208.67.222.222'
    uci add_list shadowsocksr.cfg034417.wan_fw_ips='208.67.220.220'
    uci set shadowsocksr.cfg029e1d.auto_update='1'
    uci set shadowsocksr.cfg029e1d.auto_update_time='4'
    uci add_list shadowsocksr.cfg029e1d.subscribe_url="\${SSR_SUBSCRIBE_URL}"
    uci set shadowsocksr.cfg029e1d.save_words="\${SSR_SAVE_WORDS}"
    uci set shadowsocksr.cfg029e1d.switch='1'
    uci commit shadowsocksr
    /usr/bin/lua /usr/share/shadowsocksr/subscribe.lua >> /etc/custom.tag
    uci set shadowsocksr.cfg013fd6.global_server="\${SSR_GLOBAL_SERVER}"
    uci set shadowsocksr.cfg013fd6.pdnsd_enable='0'
    uci del shadowsocksr.cfg013fd6.tunnel_forward
    uci commit shadowsocksr
    /etc/init.d/shadowsocksr restart >> /etc/custom.tag 2>&1
    echo "shadowsocksr finish" >> /etc/custom.tag
    # crontab -l 查看计划表
    # mkdir -p /data/5icodes.com/test./cert
    # /usr/lib/acme/acme.sh --home "/etc/acme" --install-cert -d test.5icodes.com --key-file /data/5icodes.com/test./cert/_lan.key --fullchain-file /data/5icodes.com/test./cert/_lan.crt --reloadcmd "service nginx reload"
    # 如果是泛域名证书，*号需转义 /usr/lib/acme/acme.sh --home "/etc/acme" --install-cert -d \*.5icodes.com --key-file /data/5icodes.com/test./cert/_lan.key --fullchain-file /data/5icodes.com/test./cert/_lan.crt --reloadcmd "service nginx reload"
    uci set acme.cfg01f3db.account_email="\${DDNS_USERNAME}"
    uci set acme.cfg01f3db.debug='1'
    uci set acme.test=cert
    uci set acme.test.enabled='1'
    uci set acme.test.use_staging='0'
    uci set acme.test.keylength='2048'
    uci add_list acme.test.domains="\${DDNS_LOOKUP_HOST}"
    uci set acme.test.update_uhttpd='0'
    uci set acme.test.update_nginx='0'
    uci set acme.test.validation_method='dns'
    uci set acme.test.dns='dns_cf'
    uci add_list acme.test.credentials="CF_Key=\${DDNS_PASSWORD}"
    uci add_list acme.test.credentials="CF_Email=\${DDNS_USERNAME}"
    uci commit acme
    /etc/init.d/acme restart >> /etc/custom.tag 2>&1
    echo "acme finish" >> /etc/custom.tag
    refresh_ad_conf
}
if [ -f "/etc/custom.tag" ]; then
    echo "smartdns block ad domain list start" > /etc/custom.tag
    refresh_ad_conf &
else
    echo "init custom config start" > /etc/custom.tag
    init_custom_config &
fi
echo "rc.local finish" >> /etc/custom.tag
exit 0
EOFEOF

#修复netdata缺少jquery-2.2.4.min.js的问题，有两种解决方式
#1、不使用汉化，使用lede仓库的luci-app-netdata插件，https://github.com/coolsnowwolf/luci/tree/master/applications/luci-app-netdata
#2、要使用汉化，回滚netdata版本至1.30.1
#cd feeds/packages
#git config --global user.email "i@5icodes.com"
#git config --global user.name "hnyyghk"
#git revert --no-edit 1278eec776e86659b3e812148796a53d0f865edc
#cd ../../

#netdata不支持ssl访问，有两种解决方式
#1、修改编译配置使netdata原生支持ssl访问，参考https://www.right.com.cn/forum/thread-4045278-1-1.html
#sed -i 's/disable-https/enable-https/g' feeds/packages/admin/netdata/Makefile
#sed -i 's/DEPENDS:=/DEPENDS:=+libopenssl /g' feeds/packages/admin/netdata/Makefile
#sed -i 's/\[web\]/[web]\n\tssl certificate = \/etc\/nginx\/conf.d\/_lan.crt\n\tssl key = \/etc\/nginx\/conf.d\/_lan.key/g' feeds/kenzo/luci-app-netdata/root/etc/netdata/netdata.conf
#2、修改netdata页面端口，配置反向代理http协议19999端口至https协议19998端口，参考https://blog.csdn.net/lawsssscat/article/details/107298336
#添加/etc/nginx/conf.d/ssl2netdata.conf如下：
#server {
#    listen 19998 ssl;
#    listen [::]:19998 ssl;
#    server_name _ssl2netdata;
#    include restrict_locally;
#    ssl_certificate /etc/nginx/conf.d/_lan.crt;
#    ssl_certificate_key /etc/nginx/conf.d/_lan.key;
#    ssl_session_cache shared:SSL:32k;
#    ssl_session_timeout 64m;
#    location / {
#        proxy_set_header Host $http_host;
#        proxy_set_header X-Real-IP $remote_addr;
#        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto $scheme;
#        proxy_pass http://localhost:19999;
#    }
#}

# 移除重复软件包
rm -rf feeds/packages/net/xray-core
rm -rf feeds/packages/net/adguardhome

./scripts/feeds update -a
./scripts/feeds install -a
