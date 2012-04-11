;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

(in-package :pw)

(provide 'structured-time2)

;;==============================================================================================================
;;========================================================================================
(defclass C-make-structured-win (C-patch) ()) 

(defmethod patch-value ((self C-make-structured-win) obj)
  (declare (ignore obj))
  (make-new-structured-window (patch-value (car (input-objects self)) ())))

(defvar strwin ()
"Strwin (structured window) allows collecting super-notes from Patch Work.
It should be connected to the ins input of the collector box
while collecting.The super-notes will contain a plain PW window.
Strwin box is normally used in context of structured time.
")
;;========================================================================================
(defclass C-make-structured-win+collector (C-patch) ()) 

(defmethod patch-value ((self C-make-structured-win+collector) obj)
  (declare (ignore obj))
  (let ((pw-win (make-new-structured-window 
                   (patch-value (car (input-objects self)) ())
                   (incf *pw-struct-collector-counter*))))
      (add-subviews pw-win (make-new-note-collector))
      pw-win))

(defvar strcoll ()
"Strcoll (structured collector) allows collecting super-notes from Patch Work.
It should be connected to the ins input of the collector box
while collecting.The super-notes will contain a PW window with a collector.
Strcoll box is normally used in context of structured time.
")

;;========================================================================================
(defclass C-make-structured-abstraction (C-patch) ()) 

(defmethod patch-value ((self C-make-structured-abstraction) obj)
  (declare (ignore obj))
    (let (pw-win) 
      (when (nth-connected-p self 0)
        (setq pw-win (eval (decompile (patch-win (car (input-objects self))))))
        (remove-subviews pw-win (car (find-abstract-out-box pw-win (controls pw-win))))
        (set-window-title pw-win 
             (concatenate  'string  (dialog-item-text (car (pw-controls self)))   
                  (format nil "~D" (incf *pw-struct-window-counter*)))))
        pw-win))

(defvar strabs ()
"Strabs (structured abstraction) allows collecting super-notes from Patch Work.
It should be connected to the ins input of the collector box while collecting.
To the input box of strabs box should be connected with an abstraction 
(no input-boxes are allowed for the abstraction).
The super-notes will contain a PW window with copies of all PW boxes that are inside the 
original abstraction exept the 'about' box.
Strabs box is normally used in context of structured time.
")
