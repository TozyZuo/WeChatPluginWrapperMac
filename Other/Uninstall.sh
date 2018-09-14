# !/bin/bash

app_name="WeChat"
wechat_path="/Applications/WeChat.app"
app_bundle_path="/Applications/${app_name}.app/Contents/MacOS"
app_executable_path="${app_bundle_path}/${app_name}"
app_executable_backup_path="${app_executable_path}_backup"
framework_path_tz="${app_bundle_path}/WeChatPluginWrapper.framework"
framework_path_tk="${app_bundle_path}/WeChatPlugin_TKkk.framework"

if [ ! -d "$wechat_path" ]; then
  wechat_path=${HOME}/Applications/WeChat.app
  if [ ! -d "$wechat_path" ]; then
    wechat_path="/Applications/微信.app"
    if [ ! -d "$wechat_path" ]; then
      wechat_path=${HOME}/Applications/微信.app
      if [ ! -d "$wechat_path" ]; then
        echo -e "\n\n未发现微信，请检查微信是否有重命名或者移动路径位置"
        exit
      fi
    fi
  fi
fi

# 备份WeChat原始可执行文件
if [ -f "$app_executable_backup_path" ]
then
	rm "$app_executable_path"
	rm -rf "$framework_path_tz"
	rm -rf "$framework_path_tk"
	mv "$app_executable_backup_path" "$app_executable_path"

	if [ -f "$app_executable_backup_path" ]
		echo "卸载失败，请到 /Applications/WeChat.app/Contents/MacOS 路径，删除 WeChatPluginWrapper.framework、WeChatPlugin_TKkk.framework、WeChat 三个文件，并将 WeChat_backup 重命名为 WeChat"
	then
		echo "\n\t卸载成功"
	fi

else
	echo "\n\t未发现插件"
fi
