#!/bin/bash
# Step 2: Ask the user to choose an option
dir=$(pwd)
echo "请选择一个选项："
echo "1. 初始化"
echo "2. 同步gitee"
echo "3. 上传gitee"
echo "4. 解决冲突"
read -p "输入的你选择: " choice

# Step 3: Perform actions based on the user's choice
if [ "$choice" -eq 1 ]; then
    echo "开始初始化......"
    pkg update
    pkg install openssh git nano
    termux-setup-storage
    dir=$(pwd)
    echo $dir/.ssh/id_ed25519.pub

    if [ -f $dir/.ssh/id_ed25519.pub ] && [ -f $dir/.ssh/id_ed25519 ]; then
        echo "SSH key 本地存在"
    else
        echo "SSH key 本地不存在，开始创建"
        ssh-keygen -t ed25519 -C "ob"
    fi
    echo "复制下面内容到gitee的公钥中:"
   
    echo "-------------------------------分割线（不要复制）-----------------------------------------"
    echo "\n\n\n\n"
    echo `cat $dir/.ssh/id_ed25519.pub`
    echo "\n\n\n\n"
    echo "-------------------------------分割线（不要复制）-----------------------------------------"
    
    while true; do
        read -p "是否已经放入gitee中?回车继续" input
        ssh_output=$(ssh -T git@gitee.com 2>&1)
        echo $ssh_output
        if echo "$ssh_output" | grep -q 'authenticated,'; then
            echo "gitee 公钥已经配置"
            break
        else
            echo "gitee 公钥没有配置，请配置"
        fi
        
    done

    vault=$dir/storage/downloads
    cd $vault
    read -p '复制gitee对应的地址：' url
    if [ "$url" = '' ]; then
        echo "请输入地址"
        exit
    fi
    basename=$(basename $url)
    repositoryname=${basename%.git}
    notefolder=$vault/$repositoryname
    if [ -f $notefolder ];then
        echo "本地笔记已经存在"
    else
        echo "本地笔记不存在，开始创建，地址在$vault目录下"
        git clone $url
    fi
    git config --global --add safe.directory /storage/emulated/0/Download/note
    git config --global user.email "a@qq.com"
    git config --global user.name "a"
    echo "添加更新脚本"
    echo "cd $notefolder  && git pull" > $dir/update.sh
    chmod a+x $dir/update.sh
    echo "添加上传脚本"
    echo "./update.sh && cd $notefolder  && git add . && git commit -m 'sync' && git push origin master" > $dir/commit.sh
    chmod a+x $dir/commit.sh
    echo "添加重置脚本"
    echo "./update.sh && cd $notefolder  && git checkout . " > $dir/checkout.sh
    chmod a+x $dir/checkout.sh
    echo "部署已经完成，请开心享用吧～"


elif [ "$choice" -eq 2 ]; then
    if [ -f $dir/update.sh ]; then
        echo "开始同步gitee中......"
        sh $dir/update.sh
    else
        echo "同步gitee脚本不存在，请先初始化"
    fi
elif [ "$choice" -eq 3 ]; then
    if [ -f $dir/commit.sh ]; then
        echo "开始上传gitee中......"
        sh $dir/commit.sh
    else
        echo "上传gitee脚本不存在，请先初始化"
    fi
elif [ "$choice" -eq 4 ]; then
    if [ -f $dir/checkout.sh ]; then
        echo "开始解决冲突中......"
        sh $dir/checkout.sh
    else
        echo "解决冲突脚本不存在，请先初始化"
    fi
else
  echo "错误的选项"
fi

echo "脚本已经完成了～"
