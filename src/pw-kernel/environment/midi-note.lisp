;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================
 
(in-package :pw)

(provide 'midi-note)
;;=======================


;;(export '(write-midi-note write-midicent-note update-cents-vector write-midicent-note
;;         write-pitch-bend-value write-controller-value write-program-change-value 
;;         write-program-change-value midi-only-attacks-pitches quantize-chords
;;         read-from-midi))

;;=========================

;;(require "LELISP-MACROS")
;;(use-package "LELISP-MACROS")
;;(eval-when (load eval compile)
;;     (require :LELISP-MACROS)
;;     (use-package "LELISP-MACROS"))

;;(require "MIDI")
;;(use-package "MIDI")

;;(require "SCHEDULER")
;;(use-package "SCHEDULER")

;;=================================================================================================
;;=================================================================================================

;;(latency) ??
(defun write-midi-note (dur chan key vel) 
  (unless (or (minusp key) (> key 127))
    (setq chan (1- chan))
    (setf dur (* 10 dur))
    (let ((event (midishare::MidiNewEv midishare::typeNote)))	
      (unless (ui::%null-ptr-p event)	
        (midishare::chan event chan)			
        (midishare::port event 0)			
        (midishare::field event 0 key)		
        (midishare::field event 1 vel)		
        (midishare::field event 2 dur)
        (midi::midi-write  event)))))


;;========================================================================
(defvar *cents-vector* (make-array '(100)))

(defun update-cents-vector (pitch-bend-range)
  (let ((steps (truncate (/  8192 pitch-bend-range))) ; 8192 = high (64) * low (128) -> 1 octave
        (temp))
    (for (i 0 1 99)
      (setq temp (/ (* i steps) 100))  
      (setf (svref *cents-vector* i)
        (cons 
          (+ 64 (truncate (/ temp 128)))    ; high
          (truncate (mod temp 128))))))) ; low

;; (for (i 0 1 99) (print (svref *cents-vector* i)))

(update-cents-vector 1)  ; pitch-bend-range +- 1 semitone

(defun write-midicent-note (dur chan key vel)
  (unless (or (minusp key) (> key 12700))
    (let ((cents (svref *cents-vector* (truncate (mod key 100)))))      ; 64 - 127
      (setq key (truncate (/ key 100)))
      (write-pitch-bend-value chan (car cents) (cdr cents))
      (setq chan (1- chan))
      (setf dur (* 10 dur))
      (let ((event (midishare::MidiNewEv midishare::typeNote)))	
        (unless (ui::%null-ptr-p event)	
          (midishare::chan event chan)			
          (midishare::port event 0)			
          (midishare::field event 0 key)		
          (midishare::field event 1 vel)		
          (midishare::field event 2 dur)
          (midi::midi-write  event))))))

;;========================================================================

(defun write-pitch-bend-value (chan value &optional (ls 0))
    (setq chan (1- chan))
    (let ((event (midishare::MidiNewEv midishare::typePitchWheel)))	
     (unless (%null-ptr-p event)	
       (midishare::chan event chan)			
       (midishare::port event 0)			
       (midishare::field event 0 ls)		
       (midishare::field event 1 value)		
       (midishare::MidiSendIm midi::*pw-refnum* event))))

(defun write-controller-value (chan controller value)
    (setq chan (1- chan))
    (let ((event (midishare::MidiNewEv midishare::typeCtrlChange)))	
     (unless (%null-ptr-p event)	
       (midishare::chan event chan)			
       (midishare::port event 0)			
       (midishare::field event 0 controller)		
       (midishare::field event 1 value)		
       (midishare::MidiSendIm midi::*pw-refnum* event))))
 

;; ????
(defun write-program-change-value (chan program) 
    (setq chan (1- chan))
    (let ((event (midishare::MidiNewEv midishare::typeProgChange)))	
     (unless (%null-ptr-p event)	
       (midishare::chan event chan)			
       (midishare::port event 0)			
       (midishare::field event 0 program)		
       (midishare::MidiSendIm midi::*pw-refnum* event))))


(defun write-pressure-value (chan key value)
  (setq chan (1- chan))
  (let ((event (midishare::MidiNewEv midishare::typeKeyPress)))	
    (unless (%null-ptr-p event)	
      (midishare::chan event chan)			
      (midishare::port event 0)			
      (midishare::field event 0 key)		
      (midishare::field event 1 value)
      (midishare::MidiSendIm midi::*pw-refnum* event))))

;;========================================================================
;; recording from midi



(defun parse-midi-stream (list)
  (let ((res)(temp)(status))
    (while list
      (cond 
         ((>= (caar list) #x80)
           (setq status (caar list))
           (setq temp (list (cadar list)))
           (push status temp)
           (pop list)
           (repeat 2 (push (car (pop list)) temp)))
         (t
           (setq temp (list (cadar list)))
           (push status temp)
           (repeat 2 (push (car (pop list)) temp))))
      (push (nreverse temp) res))
      (nreverse res)))

(defun read-from-midi ()
  (let ((res)(temp)(start-time)  res2)
    (when (car (setq temp (multiple-value-list (midi-read))))
      (setq start-time (cadr temp))
      (push (list (car temp) 0) res)
      (while (car (setq temp (multiple-value-list (midi-read))))
        (push (list (car temp) (- (cadr temp) start-time)) res)))
    (while res
      (unless (eq (car (first res)) 254)
        (push (first res) res2))
      (pop res))
    (parse-midi-stream  res2)))


(defun midi-only-attacks-pitches (lst-lst)
  (let ((pitches))
    (while lst-lst
      (when (< (1- 144) (second (car lst-lst)) (+ 16 144))
         (push (third (car lst-lst)) pitches))
      (pop lst-lst))
      (nreverse pitches)))

(defun quantize-chords (list)
  (let ((chords)(notes-on)(res-temp)(time-now)(tolerance 10))
    (while list
      (when (and (not (= 0 (fourth (car list))))(> (second (car list)) 143)) ;  only note-on   
        (push (car list) notes-on))
       (pop list))
    (setq notes-on (nreverse notes-on))
    (while notes-on
      (setq res-temp (list (setq time-now (caar notes-on))))
      (push (cdar notes-on) res-temp)
      (pop notes-on)
      (while (and notes-on (< (- (caar notes-on) time-now) tolerance)) 
         (push (cdar notes-on) res-temp)
         (pop notes-on))
      (push (nreverse res-temp) chords))
     (nreverse chords)))

#|
(defun rec-MN (midi-obj)
  (let ((mn-editor (give-MN-editor midi-obj))
        (midics)(t-time)
        (list (quantize-chords (read-from-midi))))
     (while list
        (setq t-time (caar list))
        (setq midics (mapcar #'* (mapcar #'second (cdar list)) (cirlist 100))) 
        (add-new-chord (chord-line mn-editor) (make-chord-object midics t-time))
        (pop list))
     (update-editor (give-MN-editor midi-obj) ())
     midi-obj))
|#
