;;;; -*- mode:lisp; coding:utf-8 -*-
(in-package :PW)

;;===========================================================

(defun  make-measure-midi-file-list  (midi-data measures)
  (let ((time-list (cumul-diff-lst-sum-from-0 (ask-all measures 'calc-measure-length 1 t))) 
        midi-list)
    (while measures
      (push (list 
                 (pop time-list) #xff #x58 #x04
                 (read-from-string (high (car measures)))
                 (case (read-from-string (low (car measures)))
                     (1 0)(2 1)(4 2)(8 3)(16 4)(32 5))
                 24 8)  ;24 8
              midi-list)
      (pop measures))
     (make-variable-length-midi-delta-times
       (sort (append (nreverse midi-list) midi-data) '< :key #'(lambda (a) (car a))))))

;;===========================================================

(defun make-rtm-midi-file-0 (measure-line)
  (let* ((data (make-midi-file-list (ask-all (collect-all-chord-beat-leafs measure-line) #'beat-chord) t)) 
;;         (high (read-from-string (high (car (measures measure-line)))))
;;         (low (case (read-from-string (low (car (measures measure-line))))
;;                 (1 0)(2 1)(4 2)(8 3)(16 4)(32 5)))
;;         (track-info
;;          (list #x00 #xff #x58 #x04  high low  #x18 #x08
;;                #x00 #xff #x51 #x03 #x07 #xa1 #x20))
        (track-end '(#x0 #xff #x2f #x0)))
     (setq data (make-measure-midi-file-list data (measures measure-line)))
    (append     
     '(#x4D #x54 #x68 #x64 
       #x00 #x00 #x00 #x06  
       #x00 #x00   
       #x00 #x01
       #x00 #x60
 
      #x4D #x54 #x72 #x6B) 
      (covert-length-to-4-byte-list (+ (length data)(length track-end)))
;;      track-info
      data
      track-end))) 

(defun RTM-midi-file-SAVE ()
 (let ((editor-view (editor-collection-object *active-RTM-window*))
         midi-data-list new-name)
   (tell (ask-all (beat-editors editor-view) 'measure-line) 'calc-t-time-measure-line 1)
   (setq midi-data-list
;;     (if (monofonic-mn? editor-view)
      (make-rtm-midi-file-0 (measure-line (car (beat-editors editor-view)))))
;;      (make-midi-file-1
;;         (ask-all (ask-all (editor-objects editor-view) 'chord-line) 'chords))))
   (setq new-name (choose-new-file-dialog :directory "MIDI FILE" :prompt "Save Midi file As…"))
   (delete-file new-name)  
   (WITH-OPEN-FILE  
       (out new-name :direction :output  :if-does-not-exist :create :if-exists :supersede
         :element-type 'unsigned-byte)
     (while midi-data-list
       (write-byte  (pop midi-data-list) out)))
   (set-mac-file-type new-name "Midi")))
