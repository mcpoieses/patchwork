;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

(in-package :pw)

(provide 'BPF-help-window)

;;====================================================================================================
(defclass C-bpf-help-window (C-pw-help-window)())

(defmethod view-key-event-handler ((self C-bpf-help-window) char)
  (declare (special *active-bpf-window*))
     (case char
        ((:Newline)
           (when *active-bpf-window* (window-select *active-bpf-window*))
           (window-hide self)) 
        ((:Enter)
           (when *active-bpf-window* (window-select *active-bpf-window*))))) 

;;====================================================================================================

(defvar *BPF-help-window* ())

(defun make-BPF-help-window ()
  (let (scroller)
    (setq *BPF-help-window*
          (make-instance 'C-bpf-help-window :window-title "BPF help" :GROW-ICON-P t
                         :view-position (make-point 100 50) :view-size (make-point 460 230) :close-box-p nil))
    (setq scroller (make-instance 'C-pw-help-window-view :view-size (make-point (- 460 8) (- 230 16)) 
                                  :view-container *BPF-help-window* :v-scrollp t :h-scrollp nil :track-thumb-p t))
    (add-subviews scroller
                  (make-instance 'static-text-dialog-item :view-position (make-point 5 5) 
                                 :view-font '("monaco" 9 :srcor)
                                 :dialog-item-text 
                                 "
    BPF Editor Keyboard Commands

H			opens the Window Help file, displaying commands
Return		selects the current PW window, hiding the BPF editor 
Enter			selects the current PW window, hiding the BPF editor  
R			renames the BPF window 
Backspace		deletes the selected point
f			rescales the BPF so that the function fills the editor window
K			removes all point except the first
+			zoom out
-			zoom in
g			show/hide the grid
->			time-stretch the selected points
<-			time-contract the selected points
up-arrow		stretch the values of the selected points
down-arrow		contract the values of the selected points
tab			change to another edit mode following the sequence 
			(edit - zoom - sel - drag ...)
a			add another BPF to the editor
s			select  one BPF 
d			deletes the selected BPF

"))))
