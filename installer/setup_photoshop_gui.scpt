-- SuperStarOff 管理工具
-- 安装/卸载 Photoshop 插件

on run
    set appDir to "/usr/local/SuperStarOff"
    set jsxSource to appDir & "/慧眼去星.jsx"

    -- 检查是否已安装核心组件
    set coreInstalled to false
    try
        do shell script "test -f " & quoted form of (appDir & "/superstaroff")
        set coreInstalled to true
    end try

    if not coreInstalled then
        display alert "未找到 SuperStarOff" message "请先安装 SuperStarOff 安装包" as critical
        return
    end if

    -- 主菜单
    set mainChoice to button returned of (display dialog "慧眼去星 - 管理工具

请选择操作：" buttons {"卸载", "安装插件", "取消"} default button "安装插件" with title "慧眼去星" with icon note)

    if mainChoice is "取消" then
        return
    else if mainChoice is "卸载" then
        uninstallSuperStarOff()
    else if mainChoice is "安装插件" then
        installToPhotoshop(jsxSource)
    end if
end run

-- 安装到 Photoshop
on installToPhotoshop(jsxSource)
    -- 扫描 Photoshop 版本
    set psVersions to {}
    set psPaths to {}

    repeat with psYear in {"2026", "2025", "2024", "2023", "2022"}
        set psPath to "/Applications/Adobe Photoshop " & psYear & "/Presets/Scripts"
        try
            do shell script "test -d " & quoted form of psPath
            set end of psVersions to "Photoshop " & psYear
            set end of psPaths to psPath
        end try
    end repeat

    if (count of psVersions) = 0 then
        display alert "未找到 Photoshop" message "请确保 Adobe Photoshop 已安装在 /Applications 目录" as critical
        return
    end if

    -- 检查已安装状态
    set menuItems to {}
    repeat with i from 1 to count of psVersions
        set psName to item i of psVersions
        set psPath to item i of psPaths
        try
            do shell script "test -f " & quoted form of (psPath & "/慧眼去星.jsx")
            set end of menuItems to psName & " ✓"
        on error
            set end of menuItems to psName
        end try
    end repeat

    set menuItems to menuItems & {"──────────", "安装到所有版本"}

    -- 显示选择对话框
    set userChoice to choose from list menuItems with title "安装 Photoshop 插件" with prompt "请选择要安装插件的版本：
（✓ 表示已安装）" default items {item 1 of menuItems}

    if userChoice is false then
        return
    end if

    set selectedItem to item 1 of userChoice

    if selectedItem is "──────────" then
        return
    else if selectedItem is "安装到所有版本" then
        set installedCount to 0
        repeat with i from 1 to count of psVersions
            set targetPath to (item i of psPaths) & "/慧眼去星.jsx"
            try
                do shell script "cp " & quoted form of jsxSource & " " & quoted form of targetPath with administrator privileges
                set installedCount to installedCount + 1
            end try
        end repeat
        display alert "安装完成" message "已安装到 " & installedCount & " 个 Photoshop 版本。

请重启 Photoshop 后使用：
文件 > 脚本 > 慧眼去星"
    else
        -- 去掉 ✓ 标记
        set cleanName to selectedItem
        if selectedItem ends with " ✓" then
            set cleanName to text 1 thru -3 of selectedItem
        end if

        repeat with i from 1 to count of psVersions
            if (item i of psVersions) is cleanName then
                set targetPath to (item i of psPaths) & "/慧眼去星.jsx"
                try
                    do shell script "cp " & quoted form of jsxSource & " " & quoted form of targetPath with administrator privileges
                    display alert "安装完成" message "已安装到 " & cleanName & "。

请重启 Photoshop 后使用：
文件 > 脚本 > 慧眼去星"
                on error errMsg
                    display alert "安装失败" message errMsg as critical
                end try
                exit repeat
            end if
        end repeat
    end if
end installToPhotoshop

-- 卸载 SuperStarOff
on uninstallSuperStarOff()
    set confirmResult to button returned of (display dialog "确定要卸载 慧眼去星 吗？

这将删除：
• 核心程序 (/usr/local/SuperStarOff)
• 所有 Photoshop 中的插件脚本
• 命令行工具" buttons {"取消", "卸载"} default button "取消" with title "确认卸载" with icon caution)

    if confirmResult is "取消" then
        return
    end if

    -- 执行卸载
    try
        set uninstallScript to "
# 删除 Photoshop 脚本
for YEAR in 2022 2023 2024 2025 2026; do
    rm -f \"/Applications/Adobe Photoshop $YEAR/Presets/Scripts/慧眼去星.jsx\" 2>/dev/null
done

# 删除命令行快捷方式
rm -f /usr/local/bin/superstaroff 2>/dev/null

# 删除核心目录
rm -rf /usr/local/SuperStarOff 2>/dev/null

echo done
"
        do shell script uninstallScript with administrator privileges

        display alert "卸载完成" message "慧眼去星 已完全卸载。

感谢使用！
詹姆斯祝你晴空万里 Clear Skies!"
    on error errMsg
        display alert "卸载失败" message errMsg as critical
    end try
end uninstallSuperStarOff
