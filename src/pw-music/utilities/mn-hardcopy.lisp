;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

;;
;; Printing MN windows 
;; 

(in-package :pw)

(eval-when (eval compile)
  ;; (require 'traps)
  (defconstant $PrintErr #x944)  
  (defconstant $prJob.bjDocLoop (+ 62 6))
  (defconstant $iPrStatSize 26)
  (defconstant $bSpoolLoop 1)
  (defconstant $err-printer 94)
  (defconstant $err-printer-load 95)
  (defconstant $err-printer-start 97)
)

(defmethod window-hardcopy ((self pw::C-MN-window) &optional show-fl)
  (warn "~S ~S is not implemented yet" 'window-hardcopy '((self pw::C-MN-window) &optional show-fl))
  ;; show-fl
  ;; (let* ((panels (pw::editor-objects (car (subviews self))))
  ;;        (last-time (max-time panels))
  ;;        (last-visible -1))
  ;;   (unwind-protect
  ;;     (with-cursor *arrow-cursor*
  ;;       (#_PrOpen)
  ;;       (prchk $err-printer-load)
  ;;       (let ((pRec (get-print-record)))
  ;;         (when (#_PrJobDialog :ptr (get-print-record) :boolean)
  ;;           (let ((*hc-page-open-p* nil) (ui::*inhibit-error* t)) ; err)
  ;;             (declare (special *hc-page-open-p* ui::*inhibit-error*))
  ;;             (without-interrupts
  ;;              (let* ((window-ptr (wptr self))
  ;;                     (hardcopy-ptr 
  ;;                      (#_PrOpenDoc :ptr (get-print-record) :long 0 :long 0 :ptr)))
  ;;                (unwind-protect
  ;;                  (with-dereferenced-handles ((ppRec PRec))
  ;;                    pprec
  ;;                    (prchk $err-printer-start)
  ;;                    (while (>= last-time last-visible)
  ;;                      (unwind-protect
  ;;                        (progn
  ;;                          (set-window-hardcopy-wptr self hardcopy-ptr)
  ;;                          (#_PrOpenPage :ptr hardcopy-ptr :long 0)
  ;;                          (with-port hardcopy-ptr
  ;;                            (print-all-subviews self))
  ;;                          (set-window-hardcopy-wptr self window-ptr)
  ;;                          )
  ;;                        (#_PrClosePage :ptr hardcopy-ptr)
  ;;                        )
  ;;                      (setq last-visible (pw::scroll-for-print self panels))))
  ;;                  (#_PrCloseDoc  :ptr hardcopy-ptr)))
  ;;              (when (print (eq (%hget-byte pRec $prJob.bjDocLoop)
  ;;                               $bSpoolLoop))
  ;;                (prchk)
  ;;                (%stack-block ((StRec $iPrStatSize))
  ;;                  (#_PrPicFile :ptr pRec :long 0 :long 0 :long 0 :ptr StRec))
  ;;                (prchk)))  ;))
  ;;             t))))
  ;;     (#_PrClose)))
  )

(defun max-time (panels)
  (let ((max-val -2) temp)
    (if (not (or (rest panels) (rest (pw::chords (pw::chord-line (first panels))))))
      0
      (dolist (panel panels max-val)
        (if (pw::chords (pw::chord-line panel)) 
          (if (> (setq temp (pw::t-time (car (last (pw::chords (pw::chord-line panel))))))
                 max-val)
            (setq max-val temp)))))))

(defmethod pw::scroll-for-print ((self pw::C-MN-window) panels)
  (let ((size (- (point-h (view-size (car panels))) pw::*MN-draw-offset*))
        (posn (view-scroll-position (car panels)))
        (mus-view (car (subviews self))))
    (set-scroll-bar-setting (ui::h-scroller mus-view)
          (+ (if (pw::monofonic-mn? mus-view)
               (* (length panels) size)
               size)
             (point-h posn)))
    (scroll-bar-changed (car (subviews self)) (ui::h-scroller (car (subviews self))))
    (get-last-chord self panels)))

(defmethod get-last-chord ((self pw::C-MN-window) panels)
  (truncate 
         (pw::scaled-mouse-h (car panels)
              (+ (origin (car  panels))
                 (point-h (view-scroll-position (car panels)))))))

(defmethod print-all-subviews ((self pw::C-MN-window))
  (let ((views (subviews (car (subviews self)))))
    (dolist (view views)
      (if (typep view 'pw::C-music-notation-panel)
        (pw::print-draw-contents view)))))

#|
(let* ((panels (pw::editor-objects (car (subviews pw::*active-mn-window*))))
       (last-time (max-time panels))
       (last-visible -1))
  (while (>= last-time last-visible)
    (print "draw")
    (setq last-visible (pw::scroll-for-print pw::*active-mn-window* panels))))


|#
