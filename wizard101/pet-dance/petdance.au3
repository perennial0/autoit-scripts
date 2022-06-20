#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <APISysConstants.au3>
#include <GUIMenu.au3>
#include <WinAPIProc.au3>
#include <WinAPISys.au3>
#include <Misc.au3>
#include <AutoItConstants.au3>
#include <ComboConstants.au3>
#include <GuiComboBox.au3>
#include <ImageSearch2015.au3>

HotKeySet("^q", "OnExitClick")      ; Exit script
HotKeySet("^p", "UnPauseScript")    ; Pause script
;HotKeySet("^s", "Stop")            ; Stop script

Global $g_bPaused = False
Global $g_bStarted = False

Global $g_bFeedSnacks = 0
Global $g_bFeedHighestXP = 1 ; Not finished, will always feed highest XP giving snacks.

Global $g_bFocusWindow = 1 ; Controls whether the Wizard101 window should be focused all the time.

Global $m_arriWindowDimensions

Global $g_hWND

Global $g_iWorld = 0

; Read data from registry
$g_bFeedSnacks = RegRead("HKEY_CURRENT_USER\Software\W101_PDG_SCRIPT", "FEED_SNACKS")
;$g_bFeedHighestXP = RegRead("HKEY_CURRENT_USER\Software\W101_PDG_SCRIPT", "FEED_HIGHEST_XP_SNACKS") ; Not finished, will always feed highest XP giving snacks.

$g_bFocusWindow = RegRead("HKEY_CURRENT_USER\Software\W101_PDG_SCRIPT", "FOCUS_WINDOW")

$g_iWorld = RegRead("HKEY_CURRENT_USER\Software\W101_PDG_SCRIPT", "WORLD")

; GUI
Opt("GUIOnEventMode", 1)

; Main GUI
Global $g_mainGUI = GUICreate("Pet Dance Game Script", 300, 182.5)
GUISetOnEvent($GUI_EVENT_CLOSE, "OnExitClick")

Global $g_settingsButton = GUICtrlCreateButton("Settings", 10, 10, 280, 60)
GUICtrlSetOnEvent($g_settingsButton, "OnButtonClick")

Global $g_startButton = GUICtrlCreateButton("Start script", 10, 80, 280, 60)
GUICtrlSetOnEvent($g_startButton, "OnButtonClick")

Global $g_worldComboMain = GUICtrlCreateCombo("Wizard City", 10, 150, 280, Default, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_worldComboMain, "Krokotopia|Marleybone|MooShu|Dragonspyre")
_GUICtrlComboBox_SetCurSel($g_worldComboMain, $g_iWorld)
GUICtrlSetOnEvent($g_worldComboMain, "OnComboChange")

GUISetState(@SW_SHOW, $g_mainGUI)

; Settings GUI
Global $g_settingsGUI = GUICreate("Settings", 220, 150)
GUISetOnEvent($GUI_EVENT_CLOSE, "OnExitClick")

Global $g_feedSnacksCheckbox = GUICtrlCreateCheckbox("Feed pets snacks?", 10, 10, 130)
GUICtrlSetOnEvent($g_feedSnacksCheckbox, "OnCheckboxCheck")

Global $g_feedHighestXPCheckbox = GUICtrlCreateCheckbox("Feed highest XP giving snacks?", 10, 30, 170)
GUICtrlSetOnEvent($g_feedHighestXPCheckbox, "OnCheckboxCheck")

Global $g_focusWindowCheckbox = GUICtrlCreateCheckbox("Focus Wizard101 window all the time?", 10, 50, 200)
GUICtrlSetOnEvent($g_focusWindowCheckbox, "OnCheckboxCheck")

Global $g_worldCombo = GUICtrlCreateCombo("Wizard City", 10, 75, Default, Default, $CBS_DROPDOWNLIST)
GUICtrlSetData($g_worldCombo, "Krokotopia|Marleybone|MooShu|Dragonspyre")
GUICtrlSetOnEvent($g_worldCombo, "OnComboChange")

Global $g_saveButton = GUICtrlCreateButton("Save settings", 10, 110, 200, 30)
GUICtrlSetOnEvent($g_saveButton, "OnButtonClick")

; Main loop
While 1
	If Not WinExists("Wizard101") Then
		GUICtrlSetData($g_startButton, "Could not find Wizard101 window")
		GUICtrlSetState($g_startButton, $GUI_DISABLE)

		$g_bPaused = $g_bStarted = False
	ElseIf WinExists("Wizard101") And Not $g_bStarted Then
		$g_bStarted = False

		GUICtrlSetData($g_startButton, "Start script")
		GUICtrlSetState($g_startButton, $GUI_ENABLE)
	EndIf

	If $g_bStarted Then
		If Not $g_bPaused Then
			If $g_bFocusWindow And Not WinActive($g_hWND) Then
				WinActivate($g_hWND)

				$m_arriWindowDimensions = WinGetClientSize($g_hWND)
			EndIf

			PixelSearch(0, 0, $m_arriWindowDimensions[0] - 50, $m_arriWindowDimensions[1] - 50, 0xEF80BD, 0, 1, $g_hWND)

			If Not @error Then ; If "press 'x'" box appeared.
				Send("x")

				PixelSearch(0, 0, $m_arriWindowDimensions[0] - 50, $m_arriWindowDimensions[1] - 50, 0xED6FB2, 0, 1, $g_hWND)

				If Not @error Then ; If the world selection window appeared.
					local $m_iTempColor

					Switch $g_iWorld
						Case 0 ; Wizard City
							$m_iTempColor = 0x4CD53C

						Case 1 ; Krokotopia
							$m_iTempColor = 0xA08B67

						Case 2 ; Marleybone
							$m_iTempColor = 0x005E57

						Case 3 ; MooShu
							$m_iTempColor = 0x05488C

						Case 4 ; Dragonspyre
							$m_iTempColor = 0x9C555A
					EndSwitch

					local $m_iWorldCoords = PixelSearch(0, 0, $m_arriWindowDimensions[0] - 50, $m_arriWindowDimensions[1] - 50, $m_iTempColor, 0, 1, $g_hWND) ; Find specified world coordinates.

					If Not @error Then ; If specified world found.
						local $m_iPlayButtonCoords = PixelSearch(0, 0, $m_arriWindowDimensions[0] - 50, $m_arriWindowDimensions[1] - 50, 0x431221, 0, 1, $g_hWND) ; Find "Play" button coordinates.

						MouseClick("left", $m_iWorldCoords[0], $m_iWorldCoords[1], 1, 6) ; Select world.
						MouseClick("left", $m_iPlayButtonCoords[0], $m_iPlayButtonCoords[1], 1, 6) ; Press "Play" button.

						For $i = 0 To 4 Step 1 ; Loop through five iterations (five dances).
							local $m_arrsDirections[3]

							ReDim $m_arrsDirections[3 + $i] ; Resizes according to the current iteration (dance).

							local $m_iIterCount = 2 + $i

							For $j = 0 To $m_iIterCount Step 1
								While Not LookForDirection($m_arrsDirections, $j)
								WEnd

								Sleep(230)
							Next

							Sleep(1000) ; Cooldown needed.

							For $j = 0 To $m_iIterCount Step 1
								Switch $m_arrsDirections[$j]
									Case "up"
										Send("w")

									Case "down"
										Send("s")

									Case "left"
										Send("a")

									Case "right"
										Send("d")
								EndSwitch

								Sleep(20)
							Next

							ConsoleWrite(@LF)
						Next

						local $m_arriPos

						Do
							$m_arriPos = PixelSearch(0, 0, @DesktopWidth, @DesktopHeight, 0x82233F, 0, 1, $g_hWND)
						Until Not @error

						MouseClick("left", $m_arriPos[0], $m_arriPos[1], 1, 6)

						If $g_bFeedSnacks Then
							If $g_bFeedHighestXP Then
								Do
									$m_arriPos = PixelSearch(0, 0, $m_arriWindowDimensions[0] - 50, $m_arriWindowDimensions[1] - 50, 0x431221, 0, 1, $g_hWND) ; Find "Feed pet" button coordinates.
								Until Not @error

								MouseClick("left", @DesktopWidth / 2 - @DesktopWidth / 6, @DesktopHeight / 2 + @DesktopHeight / 6, 10, 6)

								Sleep(1000)

								MouseClick("left", $m_arriPos[0], $m_arriPos[1], 1, 6)
							Else ; Not finished, will always feed highest XP giving snacks.
								Do
									$m_arriPos = PixelSearch(0, 0, @DesktopWidth / 2 + @DesktopWidth / 4, @DesktopHeight, 0xCA2D18, 0, 1, $g_hWND)
								Until Not @error

								MouseClick("left", $m_arriPos[0], $m_arriPos[1], 1, 6)
							EndIf
						EndIf

						Sleep(1000)

						Do
							$m_arriPos = PixelSearch(0, 0, @DesktopWidth / 2 + @DesktopWidth / 4, @DesktopHeight, 0x82233F, 0, 1, $g_hWND)
						Until Not @error

						MouseClick("left", $m_arriPos[0], $m_arriPos[1], 1, 6)
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	Sleep(100)
WEnd

Func LookForDirection(ByRef $m_arrsDirections, $index)
	local $m_iFoundX, $m_iFoundY

	local $m_arrsDirectionStrings = ["up", "down", "left", "right"]

	For $i = 0 To 3 Step 1
		If _ImageSearchArea($m_arrsDirectionStrings[$i] & ".png", 0, 300, @DesktopHeight / 2 + @DesktopHeight / 4, @DesktopWidth, @DesktopHeight, $m_iFoundX, $m_iFoundY, 35, 0) Then
			$m_arrsDirections[$index]	= $m_arrsDirectionStrings[$i]

			Return true
		EndIf
	Next

	Return false
EndFunc

Func UnPauseScript()
	If $g_bStarted Then
		$g_bPaused = Not $g_bPaused

		If $g_bPaused Then
			GUICtrlSetData($g_startButton, "Unpause script")
		Else
			GUICtrlSetData($g_startButton, "Pause script")
		EndIf
	EndIf
EndFunc

Func OnExitClick()
	If @GUI_WinHandle = $g_settingsGUI Then
		GUISetState(@SW_HIDE, $g_settingsGUI)
	Else
		Exit
	EndIf
EndFunc

Func OnButtonClick()
	Switch @GUI_CtrlId
		Case $g_settingsButton
			If WinGetState($g_settingsGUI) <> $WIN_STATE_EXISTS Then
				GUICtrlSetState($g_feedSnacksCheckbox, $g_bFeedSnacks ? $GUI_CHECKED : $GUI_UNCHECKED)
				GUICtrlSetState($g_feedHighestXPCheckbox, $g_bFeedHighestXP ? $GUI_CHECKED : $GUI_UNCHECKED)
				GUICtrlSetState($g_focusWindowCheckbox, $g_bFocusWindow ? $GUI_CHECKED : $GUI_UNCHECKED)

				_GUICtrlComboBox_SetCurSel($g_worldCombo, RegRead("HKEY_CURRENT_USER\Software\W101_PDG_SCRIPT", "WORLD"))

				GUISetState(@SW_SHOW, $g_settingsGUI)
			EndIf

		Case $g_saveButton
			RegWrite("HKEY_CURRENT_USER\Software\W101_PDG_SCRIPT", "FEED_SNACKS", "REG_DWORD", $g_bFeedSnacks)
			RegWrite("HKEY_CURRENT_USER\Software\W101_PDG_SCRIPT", "FEED_HIGHEST_XP_SNACKS", "REG_DWORD", $g_bFeedHighestXP)
			RegWrite("HKEY_CURRENT_USER\Software\W101_PDG_SCRIPT", "FOCUS_WINDOW", "REG_DWORD", $g_bFocusWindow)
			RegWrite("HKEY_CURRENT_USER\Software\W101_PDG_SCRIPT", "WORLD", "REG_DWORD", $g_iWorld)

			If @error = 0 Then
				MsgBox($MB_OK, "Saved", "Settings have been successfully saved.")
			Else
				MsgBox($MB_OK + $MB_ICONERROR, "Error", "An error occured while saving the settings.")
			EndIf

		Case $g_startButton
			If $g_bStarted And Not $g_bFocusWindow Then
				UnPauseScript()
			Else
				If Not $g_bFocusWindow Then
					GUICtrlSetData($g_startButton, "Pause script")
				EndIf

				$g_bStarted = True

				$g_hWND = WinGetHandle("Wizard101")

				$m_arriWindowDimensions = WinGetClientSize($g_hWND)
			EndIf
	EndSwitch
EndFunc

Func OnCheckboxCheck()
	Switch @GUI_CtrlId
		Case $g_feedHighestXPCheckbox
			$g_bFeedHighestXP = Not $g_bFeedHighestXP

		Case $g_feedSnacksCheckbox
			$g_bFeedSnacks = Not $g_bFeedSnacks

		Case $g_focusWindowCheckbox
			$g_bFocusWindow = Not $g_bFocusWindow
	EndSwitch
EndFunc

Func OnComboChange()
	Switch @GUI_CtrlId
		Case $g_worldComboMain
			$g_iWorld = _GUICtrlComboBox_GetCurSel($g_worldComboMain)

		Case $g_worldCombo
			$g_iWorld = _GUICtrlComboBox_GetCurSel($g_worldCombo)
	EndSwitch
EndFunc