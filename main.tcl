package require Tcl
package require Tk
package require Img
package require tdom
package require zipfile::decode

source "./open.tcl"
source "./image.tcl"
source "./parse.tcl"
source "./window.tcl"
source "./hist.tcl"

set ::cur {}
set ::topline none
set ::bottomline none
set ::data {}
set ::root {}
set ::type {}
set ::img {}
set ::hist {}
set ::enc {utf-8}
set ::show_img 0
set ::status {}
set ::pos {}

hist_load
make_window

#vwait forever
hist_save
