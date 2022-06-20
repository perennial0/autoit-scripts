#Region
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#EndRegion

#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <APISysConstants.au3>
#include <GUIMenu.au3>
#include <WinAPIProc.au3>
#include <WinAPISys.au3>
#include <Misc.au3>

;HotKeySet("^z", "init")        ; Start script
HotKeySet("^q", "_exit")        ; Exit script
HotKeySet("^s", "stop_script")  ; Stop script

OnAutoItExitRegister(on_autoit_exit)

global $paused = false
global $temp_paused = false
global $started = false
global $wait_for_opponent = false

global $hit_count = 0

; DLLs
global $dll = DllOpen("user32.dll")

; Hooks
global $event_proc = DllCallbackRegister(event_proc, "none", "ptr;dword;hwnd;long;long;dword;dword")
global $event_hook = _WinAPI_SetWinEventHook($EVENT_MIN, $EVENT_MAX, DllCallbackGetPtr($event_proc))

; GUI
Opt("GUIOnEventMode", 1)

global $main_gui = GUICreate("Farming Script", 300, 95)
GUISetOnEvent($GUI_EVENT_CLOSE, "_exit")

global $start_button = GUICtrlCreateButton("Start script", 10, 10, 280, 60)
GUICtrlSetOnEvent($start_button, "init")

GUICtrlSetOnEvent(GUICtrlCreateCheckbox("Wait for two opponents?", 10, 70), "change_wait")

GuiSetState(@SW_SHOW, $main_gui)

while true
    if not WinExists("Wizard101") and not $started then
        GUICtrlSetData($start_button, "Could not find Wizard101 window")
        GUICtrlSetState($start_button, $GUI_DISABLE)
        $paused = $started = false
    elseif WinExists("Wizard101") and $started then
        $started = false
        GUICtrlSetData($start_button, "Start script")
        GUICtrlSetState($start_button, $GUI_ENABLE)
    endif

    Sleep(100)
wend

func init()
    if not $started then
        if MsgBox($MB_YESNO, "Confirmation", "Are you standing within the area of your target?") = $IDYES then
            $started = true

            GUICtrlSetData($start_button, "Script has already been started")
            GUICtrlSetState($start_button, $GUI_DISABLE)

            WinMove("Wizard101", "", 0, 0)
            WinActivate("Wizard101")

            local $arr_wnd_dims = WinGetClientSize("Wizard101")
            local $hwnd = WinGetHandle("Wizard101")

            while $started
                if not WinActive("Wizard101") then
                    WinActivate("Wizard101")
                    $arr_wnd_dims = WinGetClientSize("Wizard101")
                endif

                if not $temp_paused then
                    ; Check if in duel.
                    PixelSearch(300, 300, $arr_wnd_dims[0] - 300, $arr_wnd_dims[1] - 300, 0x691E15, 0, 1, $hwnd)
                    if not @error then
                        Send("{w up}")
                        Send("{d up}")

                        if $wait_for_opponent then
                            do
                                PixelSearch(300, 50, $arr_wnd_dims[0] - 300, $arr_wnd_dims[1] - 50, 0xFF3C00, 5, 1, $hwnd)
                            until not @error ; Continue searching for second duelee until found.
                        endif

                        ; Look for tempest.
                        local const $tmpst_coords = PixelSearch(300, 300, $arr_wnd_dims[0] - 300, $arr_wnd_dims[1] - 300, 0x284068, 5, 1, $hwnd)
                        if not @error then
                            MouseClick("left", $tmpst_coords[0], $tmpst_coords[1], 1, 3)
                            $hit_count += 1
                        endif
                    elseif @error then
                        if 100 <= $hit_count then
                            ; Find potions.
                            local const $pot_coords = PixelSearch(0, 0, $arr_wnd_dims[0] - 50, $arr_wnd_dims[1] - 50, 0xA96FF3, 0, 1, $hwnd)
                            if not @error then
                                $hit_count = 0
                                MouseClick("left", $pot_coords[0], $pot_coords[1], 1, 3)
                            endif
                        endif

                        Send("{w down}")
                        Send("{d down}")

                        Sleep(500)

                        Send("{w up}")
                        Send("{d up}")
                    endif
                endif

                Sleep(100)
            wend
        else
            MsgBox($MB_OK + $MB_ICONINFORMATION, "Information", "Please ensure that you are within the area of your target.")
        endif
    endif
endfunc

func _exit()
    exit
endfunc

func on_autoit_exit()
    _WinAPI_UnhookWinEvent($event_hook)
    DllCallbackFree($event_proc)
endfunc

func event_proc($event_hook, $event, $hwnd, $object_id, $child_id, $thread_id, $event_time)
    if $started then
        switch $event
            case $EVENT_SYSTEM_MOVESIZEEND
                WinMove("Wizard101", "", 0, 0)
                $temp_paused = false

            case $EVENT_SYSTEM_MOVESIZESTART
                $temp_paused = true
        endswitch
    endif
endfunc

func stop_script()
    if $started then
        GUICtrlSetData($start_button, "Start script")
        GUICtrlSetState($start_button, $GUI_ENABLE)
        $started = false
    elseif not $started then
        init()
    endif
endfunc

func change_wait()
    $wait_for_opponent = not $wait_for_opponent
endfunc