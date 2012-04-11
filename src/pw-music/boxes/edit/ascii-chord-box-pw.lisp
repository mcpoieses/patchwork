;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

;; =============================================================================-======
;;                Ascii-Chord-Box-pw.Lisp
;; =============================================================================-======

;; Ascii Chord Box 

(in-package "EPW")


;; =============================================================================-======
;; From "CAO:From-Mika-910218:PW-CL:PatchWork:PW-Library:basic-library-boxes.Lisp" 
;; (in-package "PATCH-WORK")

(defclass C-pw-ascii-chord-box (C-pw-resize-x) ())

(defmethod patch-value ((self C-pw-ascii-chord-box) obj)
  (n->mc (let ((*readtable* *no-sharp-read-table*))
          (read-from-string (patch-value (car (input-objects self)) obj)))))

(defmethod compile-me ((self C-pw-ascii-chord-box) obj)
  (let ((ctrl (car (pw-controls self)))
        (in (car (input-objects self))))
    (if (eq ctrl in)
      `',(n->mc (let ((*readtable* *no-sharp-read-table*))
          (read-from-string (patch-value ctrl obj))))
      `(n->mc (let ((*readtable* *no-sharp-read-table*))
               (read-from-string ,(compile-me in obj)))))))

(defunp ascii-chord ((chord (absin (:dialog-item-text "()")))) midic
  "Double click the input and type in any list of ascii symbolic notes, for example:
\"(C3 C3+25 C+3 C#3-25 C#3 Db3 C#3+25)\"
The pw-ascii-chord-box will return the corresponding midic notes, in this case:
(6000 6025 6050 6075 6100 6100 6125). "
(declare (ignore chord)))
