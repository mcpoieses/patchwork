;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               pw-menu.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     MCL User Interface Classes
;;;;DESCRIPTION
;;;;    
;;;;    XXX
;;;;    
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2012-05-07 <PJB> Changed license to GPL3; Added this header.
;;;;BUGS
;;;;LEGAL
;;;;    GPL3
;;;;    
;;;;    Copyright IRCAM 1986 - 2012
;;;;    
;;;;    This program is free software: you can redistribute it and/or modify
;;;;    it under the terms of the GNU General Public License as published by
;;;;    the Free Software Foundation, either version 3 of the License, or
;;;;    (at your option) any later version.
;;;;    
;;;;    This program is distributed in the hope that it will be useful,
;;;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;;    GNU General Public License for more details.
;;;;    
;;;;    You should have received a copy of the GNU General Public License
;;;;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;;**************************************************************************
;;;;    
;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

(in-package :patch-work)

;;===========================================
;; menubar for lisp
(defvar *PW-box-instance-list* '())
(defvar *pw-window-list*       '())
(defvar *active-patch-window*  '())


(defun new-menu (title &rest menus)
  "Creates a new menu with the given <title> and the list of <menus>."
  (let ((menu (make-instance 'menu :menu-title title)))
    (apply #'add-menu-items menu menus)
    menu))

(defun menu-list (menu) (menu-items menu)) 

(defun new-leafmenu (title action)
  "Creates a new leaf menu with the given <title> and <action>."
  (make-instance 'menu-item :menu-item-title title :menu-item-action action))

(defvar *pw-menu-apps* (new-menu "Apps"))

(defvar *apps-lisp-menu-item* '())
(defvar *apps-PW-menu-item*   '())

;;_________________

(defvar *original-CCL-menubar* (ui:menubar))
(defvar *default-CCL-menubar*  '())

(unless *default-CCL-menubar*
  (let ((menus (cons (car (ui:menubar))
                     (cons *pw-menu-apps* (cdr (ui:menubar))))))
    (ui:set-menubar (setf *default-CCL-menubar* menus))))

;;___________

(defun enable-all-apps-menu-items ()
  (let ((menus (menu-list *pw-menu-apps*)))
    (while menus (menu-item-enable (pop menus)))))

(defun enable-Lisp-apps-menu-item? ()
  (unless (member nil (mapcar #'menu-enabled-p (menu-list *pw-menu-apps*)))
      (ui:set-menubar *default-CCL-menubar*)
      ;;added 920818 [Camilo]
      (mapc #'menu-enable (cdr *default-CCL-menubar*))
      (menu-item-disable *apps-lisp-menu-item*)))

(defun add-apps-item-to-apps-menu (title action)
  (let ((menu))
    (ui:add-menu-items  *pw-menu-apps* 
       (setq menu (new-leafmenu title action)))
    menu))

;;___________

(setf *apps-lisp-menu-item* 
      (add-apps-item-to-apps-menu "Lisp"
                                  #'(lambda () 
                                     (let ((listener (find-if #'(lambda (w) (subtypep (type-of w) 'listener)) (windows))))
                                       (if listener  (window-SELECT listener)
                                           ))
                                     (enable-all-apps-menu-items)
                                     (menu-item-disable *apps-lisp-menu-item*))))

(setf *apps-PW-menu-item*
   (add-apps-item-to-apps-menu "PW"
     #'(lambda ()
        (if (not *active-patch-window*) 
           (make-new-pw-window t) 
           (if (not (wptr *active-patch-window*)) 
              (search-for-next-pw-window)
              (window-select *active-patch-window*))) 
        (enable-all-apps-menu-items)
        (menu-item-disable *apps-PW-menu-item*))))

(defun search-for-next-pw-window ()
  (setq *active-patch-window* (ask *pw-window-list* 'top-level-patch-win?))
  (if  *active-patch-window* (window-select *active-patch-window*)(make-new-pw-window t)))

;;=========================================
;; file

(defvar *pw-menu-file* (new-menu "File"))

(defvar *pw-menu-file-close-item* ())
(defvar *pw-menu-file-only-Save-item* ())
(defvar *pw-menu-file-only-SaveMN-item* ())
(defvar *pw-menu-file-Save-item* ())
(defvar *pw-menu-file-SaveMN-item* ())

(let ((menu-now))
  (add-menu-items  *pw-menu-file* 
     (setq menu-now (new-leafmenu "New" #'(lambda() (make-new-pw-window t)))))
  (set-command-key menu-now #\N)
  (add-menu-items  *pw-menu-file* (setq menu-now (new-leafmenu "Open patch..." 
     #'(lambda () (PW-LOAD-PATCH)))))
  (set-command-key menu-now #\O)
  (add-menu-items  *pw-menu-file* 
     (setf *pw-menu-file-close-item*
        (new-leafmenu "Close" 
           #'(lambda () (kill-patch-window *active-patch-window*)))))
  (set-command-key *pw-menu-file-close-item* #\W)
  (add-menu-items  *pw-menu-file* 
    (setf *pw-menu-file-only-Save-item*
      (new-leafmenu "Save" 
        #'(lambda () (PW-WINDOW-SAVE *active-patch-window*)))))
  (set-command-key *pw-menu-file-only-Save-item* #\S)
  (add-menu-items  *pw-menu-file* 
    (setf *pw-menu-file-only-SaveMN-item*
      (new-leafmenu "Save with MN" 
        #'(lambda () (PW-WINDOW-SAVE-MN *active-patch-window*)))))
  (add-menu-items  *pw-menu-file* 
     (setf *pw-menu-file-Save-item*
        (new-leafmenu "Save as..." 
          #'(lambda () (PW-WINDOW-SAVE-as *active-patch-window*)))))
  (add-menu-items  *pw-menu-file* 
     (setf *pw-menu-file-SaveMN-item*
        (new-leafmenu "Save with MN as..." 
          #'(lambda () (PW-WINDOW-SAVE-MN-as *active-patch-window*))))))

;;=========================================
;; edit

(defvar *pw-menu-edit* (new-menu "Edit"))

(let ((menu-now))
  (add-menu-items  *pw-menu-edit* 
     (setq menu-now (new-leafmenu "Cut" 
       #'(lambda () (cut *active-patch-window*)))))
   (set-command-key menu-now #\X)
   (add-menu-items  *pw-menu-edit* 
      (setq menu-now (new-leafmenu "Copy" 
       #'(lambda () (copy *active-patch-window*)))))
   (set-command-key menu-now #\C)
   (add-menu-items  *pw-menu-edit* 
      (setq menu-now (new-leafmenu "Paste" 
       #'(lambda () (paste *active-patch-window*)))))
   (set-command-key menu-now #\V)
   (add-menu-items  *pw-menu-edit* 
      (setq menu-now (new-leafmenu "Duplicate" 
       #'(lambda () (duplicate *active-patch-window*)))))
   (set-command-key menu-now #\D)
   (add-menu-items  *pw-menu-edit* 
      (setq menu-now (new-leafmenu "Select All" 
     #'(lambda () (activate-all *active-patch-window*) ))))
   (set-command-key menu-now #\A))

;;;=====================================
;;the PW Menu-bar menus
;;======================================

(defvar *PWoper-menu* (new-menu "PWoper"))

(defvar *pw-kernel-menu* (new-menu "Kernel"))
  (defvar *pw-data-menu* (new-menu "Data"))
  (defvar *pw-Arith-menu* (new-menu "Arithmetic"))
  (defvar *pw-Num-series-menu* (new-menu "Num-series"))
  (defvar *pw-Num-Fun-Gen-menu* (new-menu "Function"))
  (defvar *pw-control-menu* (new-menu "control"))
  (defvar *pw-usual-lisp-menu* (new-menu "LISP"))
  (defvar *pw-List-menu* (new-menu "List"))
              (defvar *pw-set-menu* (new-menu "Set Operations"))
              ;(defvar *pw-list-gen-menu* (new-menu "Generation"))
              ;(defvar *pw-list-trans-menu*  (new-menu "Transformation"))
              (defvar *pw-list-combin-menu* (new-menu "Combinatorial"))
  (defvar *pw-Abs-menu* (new-menu "Abs"))
  (defvar *pw-BPF-menu* (new-menu "BPF"))
  (defvar *pw-Vision-menu* (new-menu "Vision"))
  (defvar *pw-Extern-menu* (new-menu "Extern"))
  (defvar *pw-Multidim-menu* (new-menu "Multidim"))
(add-menu-items *pw-kernel-menu* 
           *pw-data-menu* *pw-Arith-menu* *pw-Num-series-menu* *pw-Num-Fun-Gen-menu*
           *pw-control-menu* *pw-usual-lisp-menu*
           *pw-List-menu* *pw-set-menu* *pw-list-combin-menu* *pw-Abs-menu* *pw-BPF-menu*
           ;;*pw-Vision-menu* 
           *pw-Extern-menu*
           *pw-Multidim-menu*)

(defvar *pw-menu-patch* (new-menu "UserLib"))

(defun the-user-menu () *pw-menu-patch*)

(defvar *pw-windows-menu* (new-menu "Wins"))

;;============================================
;; PW

(add-menu-items  *PWoper-menu* 
            (new-leafmenu "Documentation"
                          #'(lambda() 
                (tell (ask-all (active-patches *active-patch-window*) 'pw-function) 
                   'show-documentation)))
            (new-leafmenu "Definition"
               #'(lambda () 
                   (tell (ask-all (active-patches *active-patch-window*) 'pw-function) 'edit-definition)))
            (new-leafmenu "Window Comment"
                          #'(lambda() (get-window-text-box)))
            (new-leafmenu "-" nil)
            (new-leafmenu "Abstract"
                          #'(lambda() (make-abstraction-M *active-patch-window*))))

(add-menu-items *PWoper-menu*
                (new-leafmenu "Lisp function…"
                              #'(lambda () 
                                  (let ((string
                                         (get-string-from-user  "Lisp function" :size (make-point 200 85)
                                                                :position :centered
                                                                :initial-string "list")))
                                    (when string
                                      (setf *si-record* nil)
                                      (let* ((patch (make-lisp-pw-boxes (read-from-string string) 
                                                                        *active-patch-window*)))
                                        (setf *si-record* t)
                                        (when patch
                                        (record-patch "funlisp" (list (point-h (view-position patch)) (point-h (view-position patch))) string))
                                        )))))
                (new-leafmenu "-" nil)
                ;;; (new-leafmenu "Abort" #'(lambda () (toplevel)))
                (find-menu-item (find-menu "Lisp") "Abort")
                (find-menu-item (find-menu "Lisp") "Break")
                (find-menu-item (find-menu "Lisp") "Continue"))

(defvar *pw-debug-menu* ())

(defvar *g-option-c-major* 
  (new-leafmenu "C-major" #'(lambda() (set-globally-scale *c-major-scale*))))

(defvar *play-Pbend-menu* 
  (new-leafmenu "Pitch Bend" #'(lambda () (set-playing-option :pb))))

(defvar *play-Multichan-menu* 
  (new-leafmenu "Multi Channel" #'(lambda () (set-playing-option :mc))))

(defvar *g-option-chromatic* (new-leafmenu "Chromatic" 
                                 #'(lambda() (set-globally-scale *chromatic-scale*))))
(defvar *semitone-menu* (new-leafmenu "SemiTone" 
                              #'(lambda() (set-globally-scale *c-major-scale*))))
(defvar *quartertone-menu* (new-leafmenu "Quarter tone" 
                              #'(lambda() (set-globally-scale *1/4-tone-chromatic-scale*))))
(defvar *eighthtone-menu* (new-leafmenu "Eigth tone" 
                              #'(lambda() (set-globally-scale *1/8-tone-chromatic-scale*))))

(defvar *click-menu* (new-leafmenu "Click" 
                              #'(lambda() (set-eval-click nil))))

(defvar *option-click-menu* (new-leafmenu "Option-Click" 
                              #'(lambda() (set-eval-click t))))

(add-menu-items *PWoper-menu* 
         (new-leafmenu "-" nil)
         (setf *pw-debug-menu*
               (new-leafmenu "PW-debug-ON"
                       #'(lambda () (flip-pw-debug))))
         (new-leafmenu "show error box" 'activate-current-patch-value-patch)
         (new-leafmenu "-" nil)
         (new-menu "Global options"
            (new-menu "Scale" *g-option-c-major* *g-option-chromatic*)
            (new-menu "Approximation" *semitone-menu*
                   (prog1  *quartertone-menu*
                     (set-menu-item-check-mark *quartertone-menu* t))
                   *eighthtone-menu*)
            (new-menu "Play Option" *play-Pbend-menu* *play-Multichan-menu*)
            (new-menu "Evaluation" *option-click-menu* *click-menu*))
         (new-leafmenu "-" nil)
         (new-leafmenu "Load Library…"
                       #'(lambda () (load-library-config)))
         (new-leafmenu "Load Abstracts…"
                       #'(lambda () (load-abstr-config)))
         (new-leafmenu "Save Current Config"
                       #'(lambda () (remember-config)))
         (new-leafmenu "Delete Config"
                       #'(lambda () (forget-all-config)))
         (new-leafmenu "-" nil)
         (new-leafmenu "Save Image" #'(lambda () (save-special-pw-image))))

(defun save-special-pw-image ()
  (let ((file (choose-new-file-dialog
               :prompt "Save new image as:"
               :button-string  "Save"
               :directory "CL:images;Pw.image"))
        (sizes (list (* 8500 1024)
                     (* 6500  1024))))
    (when file
      ;(clear-patchwork)
      ;(setf ui::*lisp-cleanup-functions* (list (car ui::*lisp-cleanup-functions* )))
      (eval-enqueue        
       #'(lambda ()
           (save-application
            file
            :application-class (find-class 'ui::lisp-development-system)
            :size sizes
            ;aaa 140397 new protection
            :resources (ui::get-app-resources "CL:PW-inits;Drivers+Resources;CLPF.rsrc" :|CCL2|)
            ;:init-file "PW:PW-lib;PWscript;image-init" GA 230996
            :init-file "image-init" 
            :clear-clos-caches t
            :excise-compiler   nil ))))))
    

(defun dis/enable-menu-item (menu-item fl)
  (if fl
   (menu-item-enable menu-item)
   (menu-item-disable menu-item)))

(defun update-PW-file-menu-items (fl change-fl)
   ;(dis/enable-menu-item *pw-rename-menu-item* (not fl))
   (dis/enable-menu-item *pw-menu-file-close-item* fl)
   (dis/enable-menu-item *pw-menu-file-Save-item* fl)
   (dis/enable-menu-item *pw-menu-file-SaveMN-item* fl)
   (dis/enable-menu-item *pw-menu-file-only-Save-item* (and fl change-fl))
   (dis/enable-menu-item *pw-menu-file-only-SaveMN-item* (and fl change-fl)))
;;============================================
;;============================================
;; menubar for PW

(defvar *patch-work-menu-root*
  (list
     *pw-menu-apps*
     *pw-menu-file* *pw-menu-edit* 
     *PWoper-menu* *pw-kernel-menu* *pw-menu-patch*
     *pw-windows-menu*))

;;==================================================

(ui:set-menubar *default-CCL-menubar*)
(menu-item-disable *apps-lisp-menu-item*)
(set-command-key *apps-lisp-menu-item* #\L)
(set-command-key *apps-PW-menu-item* #\1)

(defun cleanup-PW-wins ()
  (setf *pw-window-list* (remove nil (remove nil *pw-window-list* :key #'wptr)
                                 :key #'abstract-box :test-not #'eq ))
  (tell  *pw-window-list* 'kill-patch-window))

(push  #'cleanup-PW-wins *lisp-cleanup-functions*)
