;;;; -*- mode:lisp; coding:utf-8 -*-
(in-package :pw)


#|
now defined in Music-Package.lisp GA 20/06/94

(defvar *all-rhythm-files*
  (list "PW:PW-Music;editors;rhythm;global-vars" 
  "PW:PW-Music;editors;rhythm;rtm-selection-button" 
  "PW:PW-Music;editors;rhythm;beat-measure-measure-line" 
  "PW:PW-Music;editors;rhythm;rtm-editor" 
  "PW:PW-Music;editors;rhythm;rtm-window" 
  "PW:PW-Music;Boxes;edit;rtm-patch" 
  "PW:PW-Music;editors;rhythm;rtm-midi-files" 
  "PW:PW-Music;editors;rhythm;rtm-help-window" 
  "PW:PW-Music;editors;rhythm;print-rtm" 
  "PW:PW-Music;Menu;rtm-menu" 
  "PW:PW-Music;editors;rhythm;rtm-dialog-win" 
  "CLENI:cleni" ; GAS 920811 
  "PW:PW-Music;Boxes;edit;quantizer" 
  "PW:PW-Music;editors;rhythm;rtm-cleni-interface"
  "PW:PW-Music;editors;rhythm;rtm-paging+kill"
  "PW:PW-Music;Boxes;edit;rhythm-formation"))

(defun update-all-rhythm-files ()
  (mapc  #'|CLPF-UTIL|:compile-file? *all-rhythm-files*))

(mapc #'(lambda (file) (load-once file)) *all-rhythm-files*)

|#

(in-package :pw)
(defclass  C-patch-application-rtm-editor (C-patch-application C-process-begin+end)  
  ((clock :initform 0 :accessor clock)
   (clock-obj :initform *global-clock* :allocation :class :accessor clock-obj)
   (chord-objects :initform nil :accessor chord-objects)
;;   (previous-t-time :initform nil :accessor previous-t-time)
   (play-flag :initform nil :accessor play-flag)
  (measure-line :initform (make-instance 'C-measure-line) :initarg :measure-line :accessor measure-line)
))
