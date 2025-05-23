proc display_img {w data mtype name} {
	set type {}
	#puts "display_image mimetype $mtype"
	switch $mtype {
		"image/png" {
			set type png
		}
		"image/jpeg" {
			set type jpeg
		}
		"image/jpg" {
			set type jpeg
		}
		"image/gif" {
			set type gif
		}
		default {
			puts "unknown image type $mtype"
			return -1
		}
	}
	if { $::show_img == 1 } {
		set fimg [image create photo -format $type -data $data]
		set img [image create photo]
		set iw [image width $fimg]
		set ih [image height $fimg]
		set ww [winfo width $w]
		set wh [winfo height $w]
		if { $ww > $iw && $wh > $ih } {
			$img copy $fimg -to 0 0 -shrink
		} else {
			$img copy $fimg -to 0 0
		}
		catch { image delete $fimg } res
		$w image create end -image $img
		$w insert end "\n"
		lappend ::img $img
	} else {
		$w insert end "(omitted image)" {italic}
		$w insert end "\n"
	}
	$w insert end "name: $name (type: $mtype)\n" {italic}
	$w insert end "\n"
	return 0
}

proc clean_img {} {
	foreach img $::img {
		catch { image delete $img } res
	}
	set ::img {}
}
