extends Control

@export var email_adress = &"tycro.games@gmail.com"


func _ready() -> void:
	%EmailText.text = email_adress


func open_save_folder():
	OS.shell_open(ProjectSettings.globalize_path("user://"))


func open_logs_folder():
	OS.shell_open(ProjectSettings.globalize_path("user://logs/"))


func open_email():
	OS.shell_open("mailto:%s" % email_adress)


func show_report_bug_window():
	%ReportBugWindow.show()
