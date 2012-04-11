;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

(in-package :pw)

;;=================================

(defclass C-nargs-input-patch (C-patch) ())

(defmethod patch-value ((self C-nargs-input-patch) obj)
  (declare (ignore obj)) 
  (nth (give-nargs-place self)(input-objects self)))

(defmethod give-nargs-place ((self C-nargs-input-patch)) 0)

(defmethod disconnect-my-self ((self C-nargs-input-patch) patch)
   (for (i 0 1 (1- (length (input-objects self))))
      (if (listp (nth i (input-objects self)))
            (when  (member patch (nth i (input-objects self)) :test #'eq) 
               (setf (nth i (input-objects self))
                  (remove patch (nth i (input-objects self)) :test #'eq))
               (when (null (nth i (input-objects self)))
                 (setf (nth i (input-objects self))(nth i (pw-controls self)))
                 (setf (open-state (nth i (pw-controls self))) t)))
            (when  (eq (nth i (input-objects self)) patch)
                 (setf (nth i (input-objects self))(nth i (pw-controls self)))
                 (setf (open-state (nth i (pw-controls self))) t)))))

(defmethod connect-ctrl ((self C-nargs-input-patch) ctrl ctrl-panel)
  (let ((nargs-input (give-nargs-place self)))
   (if (not (eq ctrl (nth nargs-input (pw-controls self))))
     (setf (nth (find-nth-ctrl self ctrl) (input-objects self)) ctrl-panel)
     (if (not (nth-connected-p self nargs-input))
       (setf (nth nargs-input (input-objects self)) (list ctrl-panel))
       (setf (nth nargs-input (input-objects self))
            (adjoin ctrl-panel (nth nargs-input (input-objects self))))))))

;;       (push ctrl-panel (nth nargs-input (input-objects self)))))))

(defmethod connect-nth-control ((self C-nargs-input-patch) nth-ctrl ctrl-panel)
 (let ((nargs-input (give-nargs-place self)))
  (if (not (eq nth-ctrl nargs-input))
     (setf (nth nth-ctrl (input-objects self)) ctrl-panel)
     (if (not (nth-connected-p self nargs-input))
         (setf (nth nth-ctrl (input-objects self)) (list ctrl-panel))
         (setf (nth nth-ctrl (input-objects self))
            (adjoin ctrl-panel (nth nth-ctrl (input-objects self)))))))
  (setf (open-state (nth nth-ctrl (pw-controls self))) ()))


;;=================================
#|
(new-PW-sub-menu-item *Midi-menu* "nargs-test" 'C-nargs-input-patch  'nargs-test
    '(*fix-float-pw-type* "1st" *fix-float-pw-type* "2nd" ) '())

(new-PW-sub-menu-item *Midi-menu* "nargs-test" 'C-nargs-input-patch  'nargs-test2
    '(*fix-float-pw-type* "1st" *fix-float-pw-type* "2nd" *fix-float-pw-type* "3rd" ) '())
|#
