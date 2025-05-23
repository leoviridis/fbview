proc open_file {path} {
	if { $path == {} } {
		set path [tk_getOpenFile]
	}
	if { $path == "" || ![file exists $path]} {
		puts "empty path or no such file"
		return
	}
	set f [open $path r]
	fconfigure $f -translation binary -encoding binary
	set start [read $f 8]
	close $f
	binary scan $start H8 sig
  puts "signature $sig"
  if { $sig == "504b0304" } {
		puts "zipped file"
		::zipfile::decode::open $path
		set d [::zipfile::decode::archive]
		set np [::zipfile::decode::files $d]
		foreach cf $np {
			set e [string tolower [string range $cf end-2 end]]
			set ie [string tolower [string range $path end-3 end]]
			if { $e != {fb2} && $e != {txt} && $e != {tml} && $e != {xml} & $ie != {epub} } {
				continue
			}
			if { $ie != {epub} } {
				set ::data [::zipfile::decode::getfile $d $cf]
			} else {
				set ::data {}
				foreach cf $np {
					lappend ::data $cf
					lappend ::data [::zipfile::decode::getfile $d $cf]
				}	
			}
		}
		::zipfile::decode::close
  } else {
		set f [open $path r]
		fconfigure $f -translation binary -encoding binary
		set ::data [read $f]
		close $f
	}
	set ::filename [lindex [file split $path] end]
	hist_add $path
}
