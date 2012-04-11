;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

(in-package :PW)

(provide 'BPF-MN-PW-interface)


;;=================================================================================================
;;=================================================================================================


(defun interpol5 (time t1 t2 v1 v2)
   (+ v1 (* (- time t1) (/ (- v2 v1) (- t2 t1)))) )

(defun bpf-out (bpf time times &optional float-fl)
  (let ((last-time)(last-value)
        (values (give-y-points bpf))
        res)
    (unless times (setq times (give-x-points bpf)))
    (if (not (>= time (car times)))
       (car times)
       (progn 
           (while (and times (>= time (car times))) 
           (setq last-time (pop times)) (setq last-value (pop values)))
           (setq res
             (if (not times)
               last-value
               (interpol5 time last-time (car times) last-value (car values))))
          (if (not float-fl) (round res) res)))))   
    
(defun bpf-out-osc (bpf time points)
  (bpf-out bpf (+ (mod time (- (car (last points)) (car points)))
                  (car points)) points))

(defun bpf-out-osc-period (bpf time period points)
  (let ((time-diff (- (car (last points)) (car points))))
    (bpf-out bpf 
       (+ (mod (* time-diff (/ time period)) time-diff)
                 (car points)) points)))

;;============================================
;; make-break-point-function from pointlists
;; tlist or vlist can be numbers or lists

(defun cumul-diff-lst-sum-from-0 (diff-lst)
  (let ((res) (sum 0))
     (while diff-lst (push sum res)(incf sum (pop diff-lst)))
     (push sum res)
     (nreverse res)))

#|(defun make-break-point-function (tlist vlist)
  (let ((points))
     (cond ((and (numberp tlist)(numberp vlist))
              (setq tlist (list tlist) vlist (list vlist))) 
           ((numberp tlist)
              (setq tlist (cumul-diff-lst-sum-from-0 (make-list (1- (length vlist)) :initial-element tlist))))   
           ((numberp vlist)
              (setq vlist (make-list (length tlist) :initial-element vlist))))   
     (while (and vlist tlist)
       (push (make-point (pop tlist) (pop vlist)) points))
     (make-instance 'C-break-point-function 
          :break-point-list (nreverse points))))|#

(defun make-break-point-function (tlist vlist)
  (let (points t-point v-point)
     (cond ((and (numberp tlist)(numberp vlist))
              (setq tlist (list tlist) vlist (list vlist))) 
           ((numberp tlist)
              (setq tlist (cumul-diff-lst-sum-from-0 (make-list (1- (length vlist)) :initial-element tlist))))   
           ((numberp vlist)
              (setq vlist (make-list (length tlist) :initial-element vlist))))   
     (while (and vlist tlist)
       (setq t-point (min #.(1- (expt 2 15)) (pop tlist))
             v-point (min #.(1- (expt 2 15)) (pop vlist)))
       (push (make-point t-point v-point) points))
     (make-instance 'C-break-point-function 
          :break-point-list (nreverse points))))

;;(setq bp (make-break-point-function '(0 10 30) '(0 100 0)))
;;(x-points bp)
;;(y-points bp)
;;========================================================
;; MN

 (defun make-instrument-note (midic dur chan vel instrument &optional win)
   (let ((note (make-instance 'C-note 
                   :midic midic :dur dur :chan chan :vel vel :instrument instrument)))
      (when instrument
        (make-super-note-connections instrument note win))
     note))

 (defun make-instrument-chord (clock notes)
    (make-instance 'C-chord :t-time clock :notes notes))

;; =======================================================


