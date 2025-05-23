set ::gui_entry_opts {-highlightcolor {#909090} -highlightbackground {#606060}}
set ::gui_button_opts {-activebackground {#606060} -activeforeground {#000000} -highlightthickness 2 -highlightcolor {#909090} -highlightbackground {#606060}}
set ::gui_listbox_opts {-highlightthickness 2 -highlightcolor {#909090} -highlightbackground {#606060} -selectforeground {#000000} -selectbackground {#606060}}
set ::gui_text_opts {-highlightthickness 2 -highlightcolor {#909090} -highlightbackground {#606060}}
set ::gui_label_opts {-highlightcolor {#909090} -highlightbackground {#606060}}
set ::gui_scroll_opts {-activebackground {#606060} -troughcolor {#606060} -width 16}

proc make_window {} {
	wm title . "fbview"
	pack [panedwindow .p -ori ver -showhandle false -handlepad 0 -handlesize 0 -sashpad 0 -sashrelief flat -sashwidth 0] -fill both -expand 1

	.p add [frame .p.t] -stretch never
	pack [button .p.t.root -text "/" -command {display_chapters .p.m.t $::root} -font {Sans 9} {*}$::gui_button_opts -width 1 -state disabled ] -fill y -side left
	pack [button .p.t.up -text ".." -command {upbutton .p.m.t} -font {Sans 9} {*}$::gui_button_opts -width 1 -state disabled ] -fill y -side left
	pack [label .p.t.tline -textvar ::topline -font {Monospace 9} {*}$::gui_label_opts ] -fill y -expand 1 -side left
	pack [label .p.t.sep -text {-} -font {Monospace 9} {*}$::gui_label_opts ] -fill y -side left
	pack [label .p.t.bline -textvar ::bottomline -font {Monospace 9} {*}$::gui_label_opts ] -fill both -expand 1 -side left
	pack [button .p.t.prev -text "<" -command {prevbutton .p.m.t} -font {Sans 9} {*}$::gui_button_opts -width 1 -state disabled ] -fill y -side left
	pack [button .p.t.next -text ">" -command {nextbutton .p.m.t} -font {Sans 9} {*}$::gui_button_opts -width 1 -state disabled ] -fill y -side left
	pack [button .p.t.book -text "book" -command {fhistory} -font {Sans 9} {*}$::gui_button_opts -width 4] -fill y -side left

	.p add [frame .p.m] -stretch always
	pack [text .p.m.t -wrap word -yscrollc {pos_wrap .p.m.y set} -height 20 -width 80 -font {Monospace 9} {*}$::gui_text_opts ] -fill both -expand 1 -side left
	pack [scrollbar .p.m.y -command {pos_wrap .p.m.t yview} {*}$::gui_scroll_opts ] -fill y -side left
	
	.p add [frame .p.b] -stretch never
	pack [label .p.b.status -textvar ::status -font {Sans 9} {*}$::gui_label_opts ] -fill both -expand 1 -side left
	pack [label .p.b.pos -textvar ::pos -font {Sans 9} {*}$::gui_label_opts -width 12] -fill y -side left

	set chapter_cmd {+ click .p.m.t %x %y chapter display_chapter}
	.p.m.t tag bind chapter <1> $chapter_cmd
  .p.m.t tag bind chapter <Enter> ".p.m.t config -cursor hand2 ; click .p.m.t %x %y chapter status"
  .p.m.t tag bind chapter <Leave> ".p.m.t config -cursor {} ; set ::status {}"

	set link_cmd {+ click .p.m.t %x %y link display_link}
	.p.m.t tag bind link <1> $link_cmd
  .p.m.t tag bind link <Enter> ".p.m.t config -cursor hand2 ; click .p.m.t %x %y link status"
  .p.m.t tag bind link <Leave> ".p.m.t config -cursor {} ; set ::status {}"
	
	bind .p.m.t <Key-BackSpace> ".p.m.t yview scroll -1 pages ; break"
	bind .p.m.t <Key-space> ".p.m.t yview scroll 1 pages ; break"
	bind .p.m.t <Key-End> ".p.m.t yview end ; break"
}

proc pos_wrap {w args} {
	$w {*}$args
	set ::pos [getpos $w]
}

proc clean_all {w} {
	$w delete 1.0 end
	set ::data {}
	set ::cur {}
	set ::root {}
	set ::topline none
	set ::bottomline none
	set ::filename none
	set ::status {}
	set ::type {}
	set ::pos {}
	clean_img
}

proc getpos {w} {
	set sincestart [.p.m.t count -displaylines 1.0 current]
	set all [.p.m.t count -displaylines 1.0 end]
	#set percent [expr "100*$sincestart/$all"]
	#return "$percent%"
	return "$sincestart / $all"
}

proc status {w start endrange} {
	set ::status "$start -> $endrange"
}

proc upbutton {w} {
	if { $::type != {fb2} } {
		return
	}
	set arg {}
	catch {
	set r [$w tag ranges toparent]
	set range [lrange $r 0 1]
	set arg [eval $w get $range]
	}
	if { $arg != "" } {
		$w delete 1.0 end
		display_chapter $w [lindex $arg 0] [lrange $arg 1 end]
	}
}

proc prevbutton {w} {
	if { $::type != {fb2} } {
		return
	}
	set arg {}
	catch {
	set r [$w tag ranges toprev]
	set range [lrange $r 0 1]
	set arg [eval $w get $range]
	}
	if { $arg != "" } {
		$w delete 1.0 end
		display_chapter $w [lindex $arg 0] [lrange $arg 1 end]
	}
}

proc nextbutton {w} {
	if { $::type != {fb2} } {
		return
	}
	set arg {}
	catch {
	set r [$w tag ranges tonext]
	set range [lrange $r end-1 end]
	set arg [eval $w get $range]
	}
	if { $arg != "" } {
		$w delete 1.0 end
		display_chapter $w [lindex $arg 0] [lrange $arg 1 end]
	}
}

proc click {w x y tag action} {
	if { $::type != {fb2} } {
		return
	}
	#puts "click w $w x $x y $y action $action postaction $postaction"
	set arg {}
	set argp {}
	catch {
	set range [$w tag prevrange $tag [$w index @$x,$y]]
	set arg [eval $w get $range]
	}
	if { $arg != "" } {
		if { $action != {status} } {
			$w delete 1.0 end
		}
		$action $w [lindex $arg 0] [lrange $arg 1 end]
	}
}

proc fhistory {} {
  if { [winfo exists .h] == 1 } { 
    return
  }
  toplevel .h
  wm title .h "Open path from history"
  pack [panedwindow .h.p -ori ver -showhandle false -handlepad 0 -handlesize 0 -sashpad 0 -sashrelief flat -sashwidth 0] -fill both -expand 1
  .h.p add [frame .h.t] -stretch never
  pack [label .h.t.line -text "Open path from history" -font {Sans 9} {*}$::gui_label_opts ] -fill both -expand 1 -side left
	pack [button .h.t.close -text "close" -command {clean_all .p.m.t} -font {Sans 9} {*}$::gui_button_opts -width 4 ] -fill y -side left
  pack [button .h.t.open -text "open" -command {clean_all .p.m.t ; open_file "[lindex $::hist [lindex [.h.m.l index active] 0]]" ; parse .p.m.t ; destroy .h} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .h.t.new -text "new" -command {clean_all .p.m.t ; open_file {} ; parse .p.m.t} -font {Sans 9} {*}$::gui_button_opts -width 4] -fill y -side left
  pack [button .h.t.delete -text "delete" -command {set i [lindex [.h.m.l index active] 0] ; set ::hist [lreplace $::hist $i $i] ; hist_save} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
  .h.p add [frame .h.m] -stretch always
  pack [listbox .h.m.l -listvar ::hist -yscrollc {.h.m.y set} -height 20 -width 80 -font {Sans 9} {*}$::gui_listbox_opts ] -fill both -expand 1 -side left
  pack [scrollbar .h.m.y -command {.h.m.l yview} {*}$::gui_scroll_opts ] -fill y -side left
  .h.m.l yview end 
}

