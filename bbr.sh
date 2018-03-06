#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Debian/Ubuntu
#	Description: 魔改版BBR
#	Version: 1.0
#	Author: 雨落无声
#	Blog: https://www.zhujiboke.com
#	From https://doub.io
#=================================================

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

#Check OS
if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
fi
bit=`uname -m`
dir=`pwd`
installbbr(){
	#Install GCC
	apt-get update
	apt-get install build-essential -y
	apt-get install make gcc-4.9 -y


	#Download Kernel V4.10
	wget -O headers-all.deb http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.15/linux-headers-4.10.15-041015_4.10.15-041015.201705080411_all.deb
	dpkg -i headers-all.deb

	if [[ ${bit} == "i386" ]]; then
		wget --no-check-certificate -O headers.deb http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.15/linux-headers-4.10.15-041015-generic_4.10.15-041015.201705080411_i386.deb
		wget --no-check-certificate -O image.deb http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.15/linux-image-4.10.15-041015-generic_4.10.15-041015.201705080411_i386.deb
	elif [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -O headers.deb http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.15/linux-headers-4.10.15-041015-generic_4.10.15-041015.201705080411_amd64.deb
		wget --no-check-certificate -O image.deb http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.15/linux-image-4.10.15-041015-generic_4.10.15-041015.201705080411_amd64.deb
	else
			echo -e "不支持 ${bit} !" && exit 1
	fi

	dpkg -i headers.deb
	dpkg -i image.deb
	rm -rf headers-all.deb
	rm -rf headers.deb image.deb

	#Uninstall Other Kernel
	deb_total=`dpkg -l | grep linux-image | awk '{print $2}' | grep -v "4.10.15" | wc -l`
	if [ "${deb_total}" > "1" ]; then
		echo -e "检测到 ${deb_total} 个其余内核，开始卸载..."
		for((integer = 1; integer <= ${deb_total}; integer++))
		do
			deb_del=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "4.10.15" | head -${integer}`
			echo -e "开始卸载 ${deb_del} 内核..."
			apt-get purge -y ${deb_del}
			echo -e "卸载 ${deb_del} 内核卸载完成，继续..."
		done
		deb_total=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "4.10.15" | wc -l`
		if [ "${deb_total}" = "0" ]; then
			echo -e "内核卸载完毕，继续..."
		else
			echo -e " 内核卸载异常，请检查 !" && exit 1
		fi
	else
		echo -e " 检测到 内核 数量不正确，请检查 !" && exit 1
	fi

	#Finish Install
	update-grub
	echo -e "\033[42;37m[注意]\033[0m 重启VPS后，请重新运行脚本开启魔改BBR \033[42;37m bash bbr.sh start \033[0m"
	stty erase '^H' && read -p "需要重启VPS后，才能开启BBR，是否现在重启 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
		if [[ $yn == [Yy] ]]; then
			echo -e "\033[41;37m[信息]\033[0m VPS 重启中..."
			reboot
		fi
}


startbbr(){
    mkdir -p $dir/tsunami && cd $dir/tsunami
	wget --no-check-certificate -O ./tcp_tsunami.c https://raw.githubusercontent.com/ILLKX/BBR-Mod-backup/master/tcp_tsunami.c
	echo "obj-m:=tcp_tsunami.o" > Makefile
	make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc-4.9
	insmod tcp_tsunami.ko
    	cp -rf ./tcp_tsunami.ko /lib/modules/$(uname -r)/kernel/net/ipv4
    	depmod -a
    	modprobe tcp_tsunami
	rm -rf /etc/sysctl.conf
	wget -O /etc/sysctl.conf -N --no-check-certificate https://raw.githubusercontent.com/FunctionClub/YankeeBBR/master/sysctl.conf
	sysctl -p
    cd .. && rm -rf $dir/tsunami
	echo "魔改版BBR启动成功！"
}


action=$1
[ -z $1 ] && action=install
case "$action" in
	install|start)
	${action}bbr
	;;
	*)
	echo "输入错误 !"
	echo "用法: { install | start }"
	;;
esac
