﻿; UTF-8 with BOM
;
; 程序核心
; 最后更新：(20190707)
;
; Copyright © 2017-2019 snomiao@gmail.com
; 创建：Snowstar QQ: 997596439
; 参与完善：张工 QQ: 45289331
; LICENCE: GNU GPLv3
;

Process Priority, , High ; 脚本高优先级
SetTitleMatchMode RegEx
#SingleInstance Force ; 跳过对话框并自动替换旧实例
; #NoTrayIcon ; 隐藏托盘图标
; #NoEnv ; 不检查空变量是否为环境变量
#Persistent
#MaxHotkeysPerInterval 1000 ; 时间内按键最大次数（通常是一直按着键触发的）
#InstallMouseHook ; 安装鼠标钩子

; 载入设定
#Include CapsLockX-Settings.ahk

; 管理员模式运行
AskRunAsAdmin()
{
    full_command_line := DllCall("GetCommandLine", "str")
    if (!A_IsAdmin And !RegExMatch(full_command_line, " /restart(?!\S)")) {
        try {
            if A_IsCompiled {
                
                Run *RunAs "%A_ScriptFullPath%" /restart, "%A_WorkingDir%"
            }
            Else{
                Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%", "%A_WorkingDir%"
            }
        }
        ExitApp
    }
}

If(T_AskRunAsAdmin) {
    AskRunAsAdmin()
}

; 模式处理
global CapsLockX := 1 ; 模块运行标识符
global CapsLockXMode := 0
global ModuleState := 0
global CapsLockX_FnActed := 0
global CM_NORMAL := 0 ; 普通模式
global CM_FN := 1 ; 临时 CapsLockX 模式（或称组合键模式
global CM_CapsLockX := 2 ; CapsLockX 模式
; global CM_FNX := 3 ; FnX 模式
global LastLightState := ((CapsLockXMode & CM_CapsLockX) || (CapsLockXMode & CM_FN))
global CapsLockPressTimestamp := 0

; 切换模式
UpdateCapsLockXMode()
{
    CapsLockXMode := GetKeyState(T_CapsLockXKey, "P")
    If(T_UseScrollLockLight) {
        CapsLockXMode |= GetKeyState("ScrollLock", "T") << 1
    }
    
    Return CapsLockXMode
}
UpdateCapsLockXMode()
; 根据当前模式，切换灯
Menu, tray, icon, ./数据/图标白.ico
UpdateLight()
{
    NowLightState := ((CapsLockXMode & CM_CapsLockX) || (CapsLockXMode & CM_FN))
    ; UpdateCapsCursor(1)
    if (NowLightState == LastLightState) {
        Return
    }
    ; ToolTip testDDDD
    
    if ( NowLightState && !LastLightState) {
        Menu, tray, icon, ./数据/图标蓝.ico
        if (T_SwitchSound && T_SwitchSoundOn) {
            SoundPlay %T_SwitchSoundOn%
        }
    }
    if ( !NowLightState && LastLightState ) {
        Menu, tray, icon, ./数据/图标白.ico
        if (T_SwitchSound && T_SwitchSoundOff) {
            SoundPlay %T_SwitchSoundOff%
        }
    }
    if (T_UseScrollLockLight) {
        ; ToolTip % CapsLockXMode
        if (GetKeyState("ScrollLock", "T") != NowLightState) {
            Send {ScrollLock}
            Return 1
        }
    }
    if (1 || T_UseCursor) {
        ; ToolTip test
        UpdateCapsCursor(NowLightState)
    }
    
    ; tips(CapsLockXMode)
    LastLightState := NowLightState
}

CapsLockXTurnOff()
{
    CapsLockXMode &= ~CM_CapsLockX
    re =: UpdateLight()
    Return re
}
CapsLockXTurnOn()
{
    CapsLockXMode |= CM_CapsLockX
    re =: UpdateLight()
    Return re
}

Hotkey $*%T_CapsLockXKey%, CapsLockX_Dn
Hotkey $*%T_CapsLockXKey% Up, CapsLockX_Up

#Include Core\CapsLockX-LoadModules.ahk

#If

; CapsLockX模式切换处理
CapsLockX_Dn:
    if (A_ThisHotkey == "$*CapsLock" && CapsLockPressTimestamp == 0){
        CapsLockPressTimestamp := A_TickCount
    }
    ; 进入 Fn 模式
    CapsLockXMode |= CM_FN
    ; 限制在远程桌面里无法进入 Fn 模式，避免和远程桌面里的 CapsLockX 冲突
    if (WinActive("ahk_class TscShellContainerClass ahk_exe mstsc.exe")) {
        CapsLockXMode &= ~CM_FN
    }
    ; SendInput, {CapsLock}

    UpdateLight()
Return

CapsLockX_Up:
    ; 退出 Fn 模式
    CapsLockXMode &= ~CM_FN
    
    ; (20200629) 取消长按进入 CapslockX Mode 的功能，改为只要没有用作组合键都算切换 Capslock
    if(A_PriorKey == "CapsLock"){
        if (GetKeyState("CapsLock", "T")) {
            SetCapsLockState, Off
        }else{
            SetCapsLockState, On
        }
    }
    UpdateLight()

    ; 轻按 CapsLock 切换 CapsLock 锁定（用来保留 CapsLock 键的原功能）
    ; if (A_PriorKey == "CapsLock" && CapsLockPressTimestamp){
    ;     dt := A_TickCount - CapsLockPressTimestamp
    ;     CapsLockPressTimestamp := 0
    ;     if (dt <= 300){
    ;         if (GetKeyState("CapsLock", "T")) {
    ;             SetCapsLockState, Off
    ;         }else{
    ;             SetCapsLockState, On
    ;         }
    ;         UpdateLight()
    ;         Return
    ;     }
    ; }
    ; 不是轻按 CapsLock 则尝试进入 CapsLockX 模式
    ; 规避 Fn 功能键（也就是 CapsLockX 当作组合键使用时，不进入 CapsLockX 模式
    ; CapsLockX_FnActed := CapsLockX_FnActed || (A_PriorKey != T_CapsLockXKey && A_PriorKey != "Insert")
    ; if (!CapsLockX_FnActed) {
    ;     CapsLockXMode ^= CM_CapsLockX
        
    ;     ; 限制在远程桌面里无法进入 CapsLockX 模式，避免和远程桌面里的 CapsLockX 冲突
    ;     if (WinActive("ahk_class TscShellContainerClass ahk_exe mstsc.exe")) {
    ;         CapsLockXMode &= ~CM_CapsLockX
    ;     }
    ; }
    ; CapsLockX_FnActed := 0
    ; UpdateLight()
Return

#If CapsLockXMode

; 显示使用方法，直接调用前面定义的函数
/:: CapslockXShowHelp(globalHelpInfo, 1)



; 用ScrollLock代替CapsLock键
#if T_UseScrollLockAsCapsLock
    $ScrollLock:: CapsLock

#if T_UseDoubleClickShiftAsCapsLock
    ; TODO

#if

; 软重启键
!F12:: Reload

; 硬重启键
^!F12::
    ; Run CapsLockX.ahk, %A_WorkingDir%
    Run CapsLockX.exe, %A_WorkingDir%
    ExitApp
Return

; 结束键
^!+F12:: ExitApp

*Insert:: GoSub CapsLockX_Dn
*Insert Up:: GoSub CapsLockX_Up

