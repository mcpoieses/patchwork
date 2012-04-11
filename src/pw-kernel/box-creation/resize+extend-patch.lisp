;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

(in-package :pw)

(provide 'resize+extend-patch)

;;====================================================================================================
;; resizable PW box in x direction 
(defclass  C-pw-resize-x (C-patch) ())

(defmethod resize-patch? ((self C-pw-resize-x)) t) 

(defmethod draw-patch-extra ((self C-pw-resize-x))
  (draw-rect (- (w self) 5) (- (h self) 5) 5 5))

(defmethod resize-patch-box ((self C-pw-resize-x) mp delta)
 (let ((point-now (make-point (point-h (add-points mp delta)) (h self)))
       (min-w 46))
   (when (< min-w (point-h point-now)) 
      (set-view-size self point-now)
      (set-view-size (car (pw-controls self)) 
          (make-point (- (point-h point-now) 10)(h (car (pw-controls self))))) 
      (set-view-position (out-put self) 
          (make-point (- (round (w self) 2) 6) (- (h self) 5))))))

;;Added 920412
(defmethod resize-patch-box :after ((self C-pw-resize-x) mp delta)
  (declare (ignore mp delta))
  (if (and *current-small-inBox* (eq (view-container *current-small-inBox*) self))
    (resize-text-item *current-small-inBox*)))      ;this function is in pw-controls

;;=========================================================================================================
;;===================================
;; a PW box that can be extended

(defclass C-pw-extend (C-patch)())  

(defmethod draw-patch-extra ((self C-pw-extend))
  (draw-char (+ -10 (w self)) (- (h self) 4) #\E)) 

(defmethod give-new-extended-title ((self C-pw-extend)) 
  (read-from-string 
    (concatenate 'string "pw::" (string 'arg) 
      (format () "~D" (length (pw-controls self))))))

(defmethod draw-function-name ((self C-pw-extend) x y)
  (if (second (pw-controls self))
    (call-next-method)
    (draw-string x y 
        (subseq (pw-function-string self) 0 (min 5 (length (pw-function-string self)))))))

(defmethod generate-extended-inputs ((self C-pw-extend)) 
  (make-pw-narg-arg-list (length (pw-controls self))))

(defmethod correct-extension-box ((self C-pw-extend) new-box values)
  (declare (ignore new-box values))) 

(defmethod mouse-pressed-no-active-extra ((self C-pw-extend) x y) 
  (declare (ignore x y) ) 
  (if (option-key-p) 
   (let ((box-now
           (make-patch-box  (class-name (class-of self)) (give-new-extended-title self)
              (generate-extended-inputs self) (type-list self)))
         (values)) 
    (set-view-position box-now (make-point (x self) (y self))) 
    (setq values (ask-all (pw-controls self) 'patch-value ()))
    (for (i 0 1 (1- (length values)))
      (set-dialog-item-text (nth i (pw-controls box-now)) 
        (if (numberp (nth i values))
          (format () "~D" (nth i values))
          (string (nth i values)))) 
      (when (not (eq (nth i (input-objects self)) (nth i (pw-controls self))))
        (setf (nth i (input-objects box-now)) (nth i (input-objects self)))
        (setf (open-state (nth i (pw-controls box-now))) nil)))
    (correct-extension-box self box-now values)
    (tell (controls (view-window self)) 'draw-connections t)
    (remove-subviews *active-patch-window* self)
    (add-patch-box *active-patch-window* box-now)
    (tell (controls *active-patch-window*) 'connect-new-patch? self box-now)
    (tell (controls *active-patch-window*) 'draw-connections))
    nil))







