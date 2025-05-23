proc parse {w} {
	if { $::data == {} } {
		return
	}
	set sig {}
	set data $::data
	set ::root {}
	set hsig [string range $data 0 13]
	set ie [string range $::filename end-3 end]
	set doc {}
	if { $hsig == {<?xml version=} && $ie != {epub} } {
		catch {
		set fline [string trim [lindex [split $data "\n"] 0]]
		set i [string first {encoding=} $fline]
		set e [string tolower [string range $fline $i+10 end-3]]
		set e [string map {{windows-} {cp}} $e]
		puts "ENC $e"
		set doc [dom parse -simple [encoding convertfrom $e $data]]
		} res
		puts "catch fb2 res $res"
		if { $doc == {} } {
			return
		}
		$doc documentElement root
		set ::root $root
		set ::type fb2
		.p.t.root configure -state normal
		.p.t.up configure -state normal
		.p.t.prev configure -state normal
		.p.t.next configure -state normal
		display $w $root
	} elseif { $hsig == {<!DOCTYPE html} && $ie != {epub} } {
		catch {
		set doc [dom parse -html5 [encoding convertfrom utf-8 $data]]
		} res
		puts "catch html res $res"
		if { $doc == {} } {
			return
		}
		$doc documentElement root
		set ::root $root
		set ::type html
		.p.t.root configure -state disabled
		.p.t.up configure -state disabled
		.p.t.prev configure -state disabled
		.p.t.next configure -state disabled
		display_html $w $root
	} elseif { $ie == {epub} } {
		if { $::data == {} } {
			return
		}
		set ::root {}
		set ::type epub	
		foreach {fname fdata} $::data {
			set doc {}
			catch {
			set doc [dom parse [encoding convertfrom utf-8 $fdata]]
			}
			if { $doc == {} } {
				continue
			}
			$doc documentElement root
			puts "set ::epub_data($fname) $root"
			set ::epub_data($fname) $root
		}
		display_epub $w
	} else {
		set ::root {}
		set ::type plain
		.p.t.root configure -state disabled
		.p.t.up configure -state disabled
		.p.t.prev configure -state disabled
		.p.t.next configure -state disabled
		display_plain $w $data
	}
}

proc get_node {node path} {
	set tn $node
	foreach item $path {
		foreach n [$tn childNodes] {
			if { [$n nodeName] == $item } {
				set tn $n
				break
			}
		}
	}
	return $tn 
}

proc recurse_text {node} {
	if { $node == {} } {
		return
	}
	set res {}
	set type [$node nodeName]
	set children [$node childNodes]
	foreach child $children {
		append res [recurse_text $child]
	}
	if { $type == {#text} } {
		append res " [$node nodeValue]"
	}
	return $res
}

proc recurse_sections {w node dep} {
	set ret {}
	set type [$node nodeName]
	if { $dep > 8 } {
		return
	}
	set name {}
	set children [$node childNodes]
	if { $type == {section} } {
		set name {}
		foreach child $children {
			set ctype [$child nodeName]
			if { $ctype == {title} } {
				set name [string trim [recurse_text $child]]
				break
			}
		}
		if { $name == {} } {
			set name {---}
		}
		set pad {}
		for { set c 1 } { $c < $dep } { incr c 1 } {
			append pad {+}
		}
		if { $pad != {} } {
			$w insert end "$pad " {tilde}
		}
		insert_chapter_link $w $node $name fromroot
	}
	foreach child $children {
		if { [$child nodeName] == {section} } {
			recurse_sections $w $child [expr {$dep+1}]
		}
	}
}

proc recurse_rootfile_epub {node} {
	if { $node == {} } {
		puts "empty node"
		return
	}
	set type [$node nodeName]
	puts [$node nodeValue]
	set res {}
	if { $type == {rootfile} } {
		append res [$node getAttribute full-path]
	}
	set children [$node childNodes]
	foreach child $children {
		append res [recurse_rootfile_epub $child]
	}
	return $res
}

#proc recurse_chapters_epub {w node} {
#	if { $node == {} } {
#		puts "empty node"
#		return
#	}
#	set type [$node nodeName]
#	if { $type == {item} } {
#		$w insert end 
#	}	
#}

proc display_chapters_epub {w} {
	if { $::type != {epub} } {
		return
	}
	#set node $::epub_data(META-INF/container.xml)
	#set rootname [recurse_rootfile_epub $node]
	#puts "rootname $rootname"
	#set root $::epub_data($rootname)
	set root [lindex [array get ::epub_data "*toc.ncx"] end]
	puts "root $root"
	recurse $w $root {hide}
}

proc display_chapters {w root} {
	if { $::type != {fb2} } {
		return
	}
	if { $root == {} } {
		return
	}
	set body {}
	foreach n [$root childNodes] {
		if { [$n nodeName] == {body} } {
			set body $n
			break
		}
	}
	if { $body == {} } {
		return
	}

	$w delete 1.0 end

	set path [list "FictionBook" "description" "title-info" "book-title" "#text"]
	set ::cur $root
	set ::topline [string range [[get_node $root $path] nodeValue] 0 32]
	#set ::topline [[get_node $root $path] nodeValue]
	set ::bottomline {---} 
	set ::lastpos {} 

	recurse $w [get_node $root [list "FictionBook" "description"]] {hide}

#	set chapters [$body childNodes]
#	foreach chapter $chapters {
#		set rtype [$chapter nodeName]
#		if { $rtype != {section} } {
#			recurse $w $chapter {hide}
#			continue
#		}
#		set name {}
#		foreach fc [$chapter childNodes] {
#			set type [$fc nodeName]
#			if { $type == {title} } {
#				catch { set name [recurse_text $fc] }
#				insert_chapter_link $w $chapter $name
#				#break
#			} elseif { $type == {section} } {
#				set cname {}
#				foreach fcc [$fc childNodes] {
#					set ctype [$fcc nodeName]
#					if { $ctype == {title} } {
#						catch { set cname [recurse_text $fcc] }
#						insert_chapter_link $w $fc $cname
#						break
#					} else {
#						continue
#					}
#				}
#			} else {
#				continue	
#			}
#		}
#	}
	recurse_sections $w $body 0

	foreach n [$root childNodes] {
		if { [$n nodeName] != {body} } {
			continue
		}
		set name {}
		catch { set name [$n getAttribute name] }
		if { $name == {notes} } {
			$w insert end "\n" {text}
			insert_chapter_link $w $n "Notes" fromroot
			break
		}
	}
}

proc insert_chapter_link {w node title addtag} {
	if { $node == {} || $w == {} } {
		return
	}
	if { $title == {} } {
		set title {---}
	}
	set htags [list chapter hide $addtag]
	set ntags [list chapter $addtag]
	$w insert end $node $htags
	$w insert end { } $htags
	$w insert end $title $ntags
	$w insert end "\n" {text}
}

proc duplicate_link {w node title addtag} {
	if { [$node nodeName] != {section} } {
		return
	}
	set name {}
	foreach fc [$node childNodes] {
		set type [$fc nodeName]
		if { $type == {title} } { 
			catch { set name [string trim [recurse_text $fc]] }
			break
		} else {
			continue  
		}   
	}   
	if { $name == {} } { 
		set name {---}
	}
	$w sync
	$w insert end "$title: " {text}
	insert_chapter_link $w $node $name $addtag
	$w sync
}

proc display_entity {w node title link} {
	if { $node != $::root } {
		$w insert end {Root: } {text}
		insert_chapter_link $w $::root $::topline fromroot
		$w insert end "\n" {text}
		if { $link == 0 } {
			catch { duplicate_link $w [$node parentNode] "Parent" toparent }
			catch { duplicate_link $w [$node previousSibling] "Prev" toprev }
			catch { duplicate_link $w [$node nextSibling] "Next" tonext }
		}
		$w insert end "\n" {text}
		if { $::cur != $::root && $link == 1 } {
			$w insert end "Back:\n" {text}
			insert_chapter_link $w $::cur $::bottomline fromroot
		}
		set ::cur $node
		set ::bottomline [string range $title 0 20]
		#set ::bottomline $title
		recurse $w $node {hide}
		if { $link == 0 && $::lastpos != {} } {
			$w sync
			$w yview moveto [lindex $::lastpos 0]
			set ::lastpos {}
		}
	}	else {
		display_chapters $w $::root
	}
}

proc display_chapter {w node title} {
	if { $::type != {fb2} } {
		return
	}
	if { [[$node lastChild] nodeName] != {section} } {
		display_entity $w $node $title 0
	} else {
		set ::bottomline [string range $title 0 20]
		$w insert end {Root: } {text}
		insert_chapter_link $w $::root $::topline fromroot
		$w insert end "\n" {text}
		catch { duplicate_link $w [$node parentNode] "Parent" toparent }
		catch { duplicate_link $w [$node previousSibling] "Prev" toprev }
		catch { duplicate_link $w [$node nextSibling] "Next" tonext }
		$w insert end "\n" {text}
		recurse_sections $w $node 1
	}
}

proc display_link {w id title} {
	if { $::type != {fb2} } {
		return
	}
	if { [string index $id 0] != {#} || $title == {} || $w == {} } {
		return
	}
	set id [string range $id 1 end]
	set notebody {}
	foreach n [$::root childNodes] {
		if { [$n nodeName] != {body} } {
			continue
		}
		set name {}
		catch { set name [$n getAttribute name] }
		if { $name == {notes} } {
			set notebody $n
			break
		}
	}
	set node {}
	foreach s [$notebody childNodes] {
		if { [$s nodeName] == {section} } {
			set sid {}
			catch {	
				set sid [$s getAttribute id]
			}
			if { $sid == $id } {
				set node $s
				break	
			}
		}
	}
	if { $node == {} } {
		return
	}
	set ::lastpos [$w yview]
	display_entity $w $node "Note #$id" 1
} 

proc display_imglink {w id} {
	if { [string index $id 0] != {#} || $w == {} } {
		return
	}
	set id [string range $id 1 end]
	set node {}
	foreach n [$::root childNodes] {
		if { [$n nodeName] != {binary} } {
			continue
		}
		set aid {}
		catch { set aid [$n getAttribute id] }
		if { $aid == $id } {
			set node $n
			break
		}
	}
	if { $node == {} } {
		return
	}
	set data [[$node firstChild] nodeValue]
	set type [$node getAttribute content-type]
	display_img $w $data $type $id
}

proc lremove {lvar item} {
	upvar 1 $lvar ret
	set i [lsearch -exact $ret $item]
	set ret [lreplace $ret $i $i]
}

proc recurse {w node ptags} {
	if { $node == {} } {
		puts "empty node"
		return
	}
	set type [$node nodeName]
	set tags $ptags
	#puts "node $node parent $parent type $type tags $tags"
	switch $type {
		"#text" {
			set ti [$node nodeValue]
			if { [string length $ti] > 0 } {
				$w insert end " [$node nodeValue]" $tags
			}
		}
		"epigraph" -
		"p" {	
			lremove tags {hide}
			lappend tags {text}
		}
		"v" -
		"i" {	
			lremove tags {hide}
			lappend tags {italic}
		}
		"strong" {
			lremove tags {hide}
			lappend tags {strong}	
		} 
		"b" {	
			lremove tags {hide}
			lappend tags {bold}
		}
		"book-title" {
			lremove tags {hide}
			lappend tags {header1}
		}
		"title" {
			lremove tags {hide}
			lappend tags {header2}
		}
		"subtitle" {
			lremove tags {hide}
			lappend tags {header3}
		}
		"binary" {
			set tags {hide}
			#display_img $w [$node getAttribute id] [$node getAttribute content-type] [$node getValue]
		}
		"script" {
			set tags {hide}
		}
		"reference" -
		"item" -
		"a" {
			set tags {link}
			set link_text {}
			set link_dir {}
			set link_type {}
			catch {
				set link_text [[$node firstChild] nodeValue]
				set link_dir [$node getAttribute l:href]
				set link_type [$node getAttribute type]
			}
			if { $link_type == {note} || $link_text != {} || $link_dir != {} } {
				$w insert end $link_dir {link hide}
				$w insert end { } {link hide}
				$w insert end $link_type {link hide}
				$w insert end { } {link hide}
				$w insert end $link_text {link}
				$w insert end { } {text}
			}
			set tags {hide}
		}
		"image" {
			set tags {image}
			set image_dir {}
			catch {
				set image_dir [$node getAttribute l:href]
			}
			if { $image_dir != {} } {
				display_imglink $w $image_dir
			}
		}
	}
	set children [$node childNodes]
	foreach child $children {
		recurse $w $child $tags
	}
	switch $type {
		"empty-line" -
		"book-title" -
		"binary" -
		"title" -
		"subtitle" -
		"section" -
		"annotation" -
		"epigraph" -
		"v" -
		"p" {
			$w insert end "\n\n" {}
		}
	}
}

proc display_plain {w data} {
	if { $::type != {plain} } {
		return
	}
	set_tags $w
	if { $::enc == {} } {
		set ::enc utf-8
	}
	set data [encoding convertfrom $::enc $data]

	set ::topline [string range $::filename 0 32]
	set ::bottomline {---}

	$w delete 1.0 end
	if { ![winfo exists .p.m.t.enc] } {	
		set omenu [tk_optionMenu .p.m.t.enc ::enc {*}[lsort -increasing [encoding names]]]
		$omenu configure -font {Monospace 9} -activebackground {#606060} -activeforeground {#000000}
		.p.m.t.enc configure -font {Monospace 9} {*}$::gui_button_opts -width 8
		bind $omenu <ButtonRelease> {after idle [list display_plain .p.m.t $::data]}
	}
	$w window create end -window .p.m.t.enc
	$w insert end "\n" {}
	$w insert end [string map {"\r" ""} $data] {}
	$w insert end "\n" {}
}

proc display_html {w root} {
	if { $::type != {html} } {
		return
	}
	set_tags $w

	set children [$root childNodes]
	foreach child $children {
		set type [$child nodeName]
		if { $type == {title} } {
			set ::topline [string range [string trim [recurse_text $child]] 0 32]
			set ::bottomline [string range [string trim [recurse_text $child]] 0 20]
			break
		}
	}
	$w delete 1.0 end
	recurse $w $root {hide}
}

proc display_epub {w} {
	if { $::type != {epub} } {
		return
	}
	set_tags $w

	display_chapters_epub $w
}

proc display {w root} {
	if { $::type != {fb2} } {
		return
	}
	set_tags $w

	display_chapters $w $root
}

proc set_tags {w} {
	$w tag configure hide -elide true
	$w tag configure tilde -font {Sans 10} -foreground {#909090}
	$w tag configure mono -font {Monospace 10} -foreground {#c0c0c0}
	$w tag configure text -font {Sans 10} -foreground {#c0c0c0}
	$w tag configure italic -font {Sans 10 italic} -foreground {#c0c0c0}
	$w tag configure bold -font {Sans 10 bold} -foreground {#c0c0c0}
	$w tag configure strong -font {Sans 10 bold} -foreground {#c0c0c0}
	$w tag configure link -font {Sans 10} -underline true -foreground {#6090c0} 
	$w tag configure chapter -font {Sans 10} -underline true -foreground {#6090c0} 
	#$w tag configure text -font {Sans 10} -foreground {#c0c0c0}
	#$w tag configure italic -font {Sans 10 italic} -foreground {#c0c0c0}
	#$w tag configure bold -font {Sans 10 bold} -foreground {#c0c0c0}
	#$w tag configure strong -font {Sans 10 bold} -foreground {#c0c0c0}
	#$w tag configure link -font {Sans 10} -underline true -foreground {#6090c0} 
	#$w tag configure chapter -font {Sans 10} -underline true -foreground {#6090c0} 
	$w tag configure header1 -font {Serif 13 bold} -foreground {#c06060} 
	$w tag configure header2 -font {Serif 12 bold} -foreground {#c09060} 
	$w tag configure header3 -font {Serif 11 bold} -foreground {#c060c0} 
}
