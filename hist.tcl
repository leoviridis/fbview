proc hist_load {} {
	set path "./history"
	if { ![file exists $path] } {
		return
	}
	set f [open $path r]
	set ::hist {}
	while { [gets $f url] >= 0 && ![eof $f] } {
		lappend ::hist $url
	}
	close $f
	set ::hist [lsort -unique $::hist]
}

proc hist_add {url} {
	lappend ::hist $url
	set ::hist [lsort -unique $::hist]
	set path "./history"
	set f [open $path a]
	puts $f $url
	close $f
}

proc hist_save {} {
	set path "./history"
	set f [open $path w]
	set ::hist [lsort -unique $::hist]
	foreach url $::hist {
		puts $f $url
	}
	close $f
}
