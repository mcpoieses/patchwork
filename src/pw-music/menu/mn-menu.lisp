;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

(in-package :pw)

(provide 'MN-menu)

;;==================================================================================
;;=========================================
;; file
(defvar *pw-menu-Music* (new-menu "Music"))
(defvar *pw-MN-Edit-menu* (new-menu "Edit"))
(defvar *pw-Conv-approx-menu* (new-menu "Conv-Approx"))
(defvar *pw-Music-Extern-menu* (new-menu "Extern"))
(defvar *pw-Midi-menu* (new-menu "Midi"))
(defvar *pw-Multidim-Music-menu* (new-menu "Multidim"))
(ui:add-menu-items *pw-menu-Music* *pw-MN-Edit-menu* *pw-Conv-approx-menu*
                ;*pw-Music-Extern-menu*
                *pw-Midi-menu* *pw-Multidim-Music-menu*)

(setf *patch-work-menu-root*
  (list
     *pw-menu-apps*
     *pw-menu-file* *pw-menu-edit* 
     *PWoper-menu* *pw-kernel-menu* *pw-menu-Music* *pw-menu-patch* 
     *pw-windows-menu*))

(ui:set-menubar *default-CCL-menubar*)

;;==================================

(defvar *active-MN-window* nil)

(defvar *MN-menu-file* (new-menu "File"))

(ui:add-menu-items  *MN-menu-file* (new-leafmenu "Save as midifile..."  
    #'(lambda () (PW-midi-file-SAVE))))

;;============================================
;; MN
(defvar a-leaf-menu ())
(defvar *MN-menu* (new-menu "MN"))

#|
(ui:add-menu-items *MN-menu*
    (new-menu "Approximation"
        (prog1 (setf a-leaf-menu
                     (new-leafmenu "SemiTone" #'(lambda() (use-all-approx-scale  *c-major-scale*))))
          (set-command-key a-leaf-menu #\2))
        (prog1 (setf a-leaf-menu
                     (new-leafmenu "Quarter tone" 
                                   #'(lambda() (use-all-approx-scale  *1/4-tone-chromatic-scale*))))
          (set-command-key a-leaf-menu #\4))
        (prog1 (setf a-leaf-menu
                     (new-leafmenu "Eigth tone" 
                                   #'(lambda() (use-all-approx-scale  *1/8-tone-chromatic-scale*))))
          (set-command-key a-leaf-menu #\8)))
    (new-menu "Scale"
              (new-leafmenu "C-major" 
                            #'(lambda() (use-all-scale  *c-major-scale*)))
              (new-leafmenu "Chromatic" 
                            #'(lambda() (use-all-scale  *chromatic-scale*)))
              (new-leafmenu "Quarter Tone"
                            #'(lambda() (use-all-scale *1/4-tone-chromatic-scale*)))
              (new-leafmenu "Eighth Tone"
                        #'(lambda() (use-all-scale  *1/8-tone-chromatic-scale*)))))
|#

(defvar *play-Pbend-menu* 
  (new-leafmenu "Pitch Bend" #'(lambda () (set-playing-option :pb))))

(defvar *play-Multichan-menu* 
  (new-leafmenu "Multi Channel" #'(lambda () (set-playing-option :mc))))

#|(ui:add-menu-items *MN-menu*
                (new-menu "Play Option" *play-Pbend-menu* *play-Multichan-menu*))|#

;;============================================
;; menubar for MN
(defvar *MN-menu-edit* (new-menu "Edit"))

;;added 910415
(defvar *undo-MN-menu* (new-leafmenu "Undo" #'(lambda () (redo-MN-edit))))
(ui:add-menu-items *MN-menu-edit* *undo-MN-menu*)
(set-command-key *undo-MN-menu* #\Z)
(menu-item-disable *undo-MN-menu*)
(ui:add-menu-items *MN-menu-edit* (new-leafmenu "-" ()))

 (ui:add-menu-items  *MN-menu-edit* 
     (setq menu-now (new-leafmenu "Cut" 
       #'(lambda () (cut *active-MN-window*)))))
   (set-command-key menu-now #\X)
   (ui:add-menu-items  *MN-menu-edit*
      (setq menu-now (new-leafmenu "Copy" 
       #'(lambda () (copy *active-MN-window*)))))
   (set-command-key menu-now #\C)
   (ui:add-menu-items  *MN-menu-edit*
      (setq menu-now (new-leafmenu "Paste" 
       #'(lambda () (paste *active-MN-window*)))))
   (set-command-key menu-now #\V)

(defvar *MN-menu-root*
  (list
     *pw-menu-apps*
     *MN-menu-file* 
     *MN-menu-edit*
     (fifth (ui:menubar) )
     (sixth (ui:menubar) )
     ;*MN-menu*
     ))

;;============================================
;; application 

(defvar *apps-MN-menu-item* ())


(setf *apps-MN-menu-item* 
   (add-apps-item-to-apps-menu  "MN"
     #'(lambda () 
        (if *active-MN-window* 
          (if (wptr *active-MN-window*)
            (progn 
              (window-select *active-MN-window*)
              (enable-all-apps-menu-items)
              (menu-item-disable *apps-MN-menu-item*))
            (ed-beep))
          (ed-beep)))))
