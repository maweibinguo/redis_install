#!/bin/bash
#安装redis服务

#校验网络
function check_network()
{
	lose_rate=`ping -c 4 www.baidu.com | awk '/packet loss/{print $6}' | sed -e 's/%//' `
	if [ $lose_rate -ne 0 ]
	then
		echo 'The Network Is Wrong'
		exit 1
	fi
}

#校验是否是root用户
function check_isroot()
{
	uid=`id -u`
	if [ $uid -ne 0 ]
	then
		echo 'Plase Change To Root'
		exit 1
	fi	
}

#校验依赖的文件是否存在
function check_config_file()
{
	if [ ! -d ${config_dir} ]
	then
		echo 'The Config File Is Not Exists'
		exit 1
	fi

	if [ ! -s ${redis_config_file} ]
	then
		echo "The Redis.conf Is Not Exists"
		exit 1
	fi

	if [ ! -s ${redis_manage_file} ]
	then
		echo "The Redis_init_script Is Not Exists"
		exit 1
	fi
}

#安装公共的依赖环境
function install_public_dependent()
{
	yum -y install gcc gcc-c++ make
}

#获取redis源文件
function get_redis_package()
{
	if [ ! -d ${redis_package_dir} ]
	then
		mkdir $redis_package_dir
	else
		cd $redis_package_dir
		rm -rf *
	fi

	cd $redis_package_dir
	wget http://download.redis.io/releases/redis-3.2.9.tar.gz
}


#将大写转换为小写
upcase_to_lowcase()
{
    echo $1 | tr '[A-Z]' '[a-z]'
}

#安装redis
function install_redis()
{
	cd $redis_package_dir
	tar -xvzf redis-3.2.9.tar.gz
	cd ./redis-3.2.9
	make PREFIX=${redis_install_dir} install

	#配置文件
	mkdir /etc/redis 
	cp ${redis_config_file} ${target_redis_config_file}  

	#redis启动与停止的管理文件
	cp ${redis_manage_file} ${target_redis_manage_file}

	#redis的pid存放文件
	if [ ! -d '/var/run/redis' ]
	then
		mkdir /var/run/redis
	fi
}

#卸载redis
function unstall_redis()
{
	service redisd stop
	sleep 1

	if [ -d ${redis_package_dir} ]
	then
		rm -rf ${redis_package_dir}
	fi

	if [ -d /usr/local/redis ]
	then
		rm -rf /usr/local/redis
	fi

	if [ -e /etc/redis/6379.conf ]
	then
		rm -rf /etc/redis/6379.conf
	fi

	if [ -e /etc/init.d/redisd ]
	then
		rm -rf /etc/init.d/redisd
	fi
}

root_dir=`pwd`

#redis源文件目录
redis_package_dir="${root_dir}/redis_package"

#redis要安装的目录
redis_install_dir="/usr/local/redis/3.2.9"

#安装redis需要的配置文件目录
config_dir="${root_dir}/config_file"	

#安装redis需要的redis配置文件
redis_config_file="${config_dir}/redis.conf"

#指定的redis.conf文件的安装位置
target_redis_config_file="/etc/redis/6379.conf"

#安装redis需要的启动与关闭管理文件
redis_manage_file="${config_dir}/redis_init_script"

#指定redis_init_script的位置
target_redis_manage_file="/etc/init.d/redisd"

case "$1" in
	install)
		echo "########################################################################"
		echo "##                          start install redis ...                   ##"
		echo "########################################################################"
		check_network
		check_isroot
		check_config_file
		install_public_dependent
		get_redis_package
		install_redis
		echo "########################################################################"
		echo "##                   now redis had been complete ...                  ##"
		echo "## now you can execute 'service redisd start' command to start redis  ##"
		echo "########################################################################"
		;;
	unstall)
		read -p "Do You Sure To Remove The Redis ? Plase Enter[Y/N], It Is Not Case Sensitive :" answer 
		answer=`upcase_to_lowcase ${answer}`
		if [ ${answer} = 'n' ]
		then
			echo "Had Quite Unstall..."
			exit 1
		elif [ ${answer} = 'y' ]
		then
			unstall_redis		
		else
			echo "Plase Enter[Y] [N] [y] [n]"
			exit 1
		fi
		echo "########################################################################"
		echo "##                        redis had been removed                      ##"
		echo "########################################################################"
		;;
	*)
		echo "Please use install or unstall as first argument"
		;;
esac
