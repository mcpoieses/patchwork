;;;; -*- mode:lisp; coding:utf-8 -*-
(in-package :pw)

;;=======================================

(defvar *rtm-win-1st-numbox* ())
(defvar *rtm-win-2nd-numbox* ())
(defvar *rtm-editor-dialog-window* ())

;;=======================================

(defun open-rtm-win (mode text-text function &key (min1 0) (max1 127) (val1 100) (min2 0)(max2 127) (val2 100))
  (setf *rtm-editor-dialog-window* (make-instance 'dialog
                                                  :window-type :double-edge-box :window-show nil 
                                                  :view-position :centered
                                                  :view-size (make-point 200 100)))
  (add-subviews *rtm-editor-dialog-window*
                (make-instance 'static-text-dialog-item 
                               :view-font '("monaco" 9)
                               :view-position (make-point 5 5)
                               :dialog-item-text text-text)
                (setf *rtm-win-1st-numbox*
                   (if (string=  "Unit   Metronome" text-text)
                      (make-instance 'C-menubox-val 
                                     :view-position (make-point 5 20)
                                     :view-size (make-point 36 22)
                                     :value val1
                                     :view-font '("MusNot-j"  18  :srcor)
                                     :menu-box-list '(("  w ." . 2/3)("  w" . 1)
                                                      ("  h ." . 4/3)("  h" . 2)
                                                      ("  q ." . 8/3)("  q" . 4)
                                                      ("  e ." . 16/3)("  e" . 8)
                                                      ("  x ." . 32/3)("  x" . 16)
                                                      ("  ≈ ." . 64/3)("  ≈" . 32)))
                      (make-instance 'C-numbox 
                                    :view-position (make-point 5 25)
                                     :min-val min1 :max-val max1  :value val1)))
                (make-instance 'default-button-dialog-item 
                               :view-position (make-point 5 50)
                               :dialog-item-text "OK"
                               :dialog-item-action function)
                (make-instance 'button-dialog-item 
                               :view-position (make-point 80 50)
                               :dialog-item-text "Cancel"
                               :dialog-item-action #'(lambda (item) item (return-from-modal-dialog nil))))
  (case mode
    ('range 
     (add-subviews *rtm-editor-dialog-window*
                   (setf *rtm-win-2nd-numbox*
                         (make-instance 'C-numbox 
                                        :view-position (make-point 50 25)
                                        :min-val min2 :max-val max2  :value val2)))))
  
  (when (string=  "Unit   Metronome" text-text)
     (set-view-font  *rtm-win-1st-numbox* '("MusNot-j"  13  :srcor)))
  (modal-dialog *rtm-editor-dialog-window*))

;;================================================================================================
;; selection editing
;;================================================================================================

(defvar *RTM-selection-menu* (new-menu "Edit selection"))
(ui:add-menu-items *RTM-menu* *RTM-selection-menu*)

;;========================================
;;velocity

(defun edit-rtm-editor-velocity-menu ()
   (open-rtm-win 'range "Velocity" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-velocity *active-rtm-window*  (value *rtm-win-1st-numbox*) (value *rtm-win-2nd-numbox*))
      (return-from-modal-dialog ()))))

(defmethod edit-rtm-editor-velocity ((self C-rtm-editor-window) vmin vmax)
   (with-cursor *watch-cursor* 
            (let* ((chords (give-rtm-range-chords (editor-collection-object self) t))
                   (vels (get-every-nth-item-of-list *rtm-editor-velocity-list* (length chords) vmin vmax))) 
              (while (and vels chords) 
                   (set-all-vels (pop chords)(pop vels)))
              (when (check-box-checked-p (car (rtm-radio-ctrls (editor-collection-object self))))
                ;; GA 12/4/94 crashes otherwise
                (invalidate-corners self (make-point 0 0) (view-size self))
                ;(erase+view-draw-contents (current-rtm-editor (editor-collection-object self)))
                ))))

(ui:add-menu-items  *RTM-selection-menu*                        
   (new-leafmenu "Velocity..." #'edit-rtm-editor-velocity-menu))

;;========================================
;;transpose

(defun edit-rtm-editor-transpose-menu ()
   (open-rtm-win 'simple "Transpose (in cents)" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-transpose *active-rtm-window*  (value *rtm-win-1st-numbox*))
            (return-from-modal-dialog ()))
       :min1 -3600 :max1 3600 :val1 100))

(defmethod edit-rtm-editor-transpose ((self C-rtm-editor-window) cents)
  (with-cursor *watch-cursor*
    (let ((chords (give-rtm-range-chords (editor-collection-object self) t)))
      (tell chords #'transpose-all-notes cents)
      ;; GA 12/4/94 crashes otherwise
      (invalidate-corners self (make-point 0 0) (view-size self))
      ;(erase+view-draw-contents (current-rtm-editor (editor-collection-object self)))
      )))

(ui:add-menu-items  *RTM-selection-menu*                        
   (new-leafmenu "Transpose..." #'edit-rtm-editor-transpose-menu))

;;========================================
;;chans

(defun edit-rtm-editor-chans-menu ()
   (open-rtm-win 'simple "Midi channel" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-chans *active-rtm-window*  (value *rtm-win-1st-numbox*))
           (return-from-modal-dialog ()))
       :min1 1 :max1 16 :val1 1))

(defmethod edit-rtm-editor-chans ((self C-rtm-editor-window) chan)
  (with-cursor *watch-cursor*
     (let ((chords (give-rtm-range-chords (editor-collection-object self) t)))
        (tell chords #'set-all-chans chan))))

(ui:add-menu-items  *RTM-selection-menu*                        
   (new-leafmenu "Channel..." #'edit-rtm-editor-chans-menu))

;;========================================
;;duration

#|
(defun edit-rtm-editor-duration-menu ()
   (open-rtm-win 'simple "Duration (in %)" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-duration *active-rtm-window*  (value *rtm-win-1st-numbox*))
           (return-from-modal-dialog ()))
       :min1 1 :max1 1000 :val1 90))
|#

;;changed by aaa 28-08-95 from pw-modif
(defun edit-rtm-editor-duration-menu ()
  (open-rtm-win 'simple "Duration (in %)" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-duration *active-rtm-window*  (value *rtm-win-1st-numbox*))
           (return-from-modal-dialog ()))
       :min1 1 :max1 1000 :val1 100))


(defmethod edit-rtm-editor-duration ((self C-rtm-editor-window) dur1)
  (with-cursor *watch-cursor* 
    (let ((chords (give-rtm-range-chords (editor-collection-object self) t)))
      (when chords
        (setf *rtm-duration-scaler* (float (/ dur1 100)))
        (calc-t-time-measure-line  
         (measure-line (current-rtm-editor (editor-collection-object self)))
         (get-play-speed (editor-collection-object self)) chords)
        ;; GA 12/4/94 crashes otherwise
        (invalidate-corners self (make-point 0 0) (view-size self))
        ;(erase+view-draw-contents self)
        ))))

(ui:add-menu-items  *RTM-selection-menu*                        
   (new-leafmenu "Duration..." #'edit-rtm-editor-duration-menu))

;;========================================
;;Metronome

(defun edit-rtm-editor-Metronome-menu ()
   (open-rtm-win 'range "Unit   Metronome" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-Metronome *active-rtm-window*  (patch-value  *rtm-win-1st-numbox* ())(value *rtm-win-2nd-numbox*))
            (return-from-modal-dialog ()))
       :min1 1 :max1 32 :val1 5 :min2 10 :max2 360 :val2 60))

(defmethod edit-rtm-editor-Metronome ((self C-rtm-editor-window) unit metronome)
  (with-cursor *watch-cursor* 
    (let ((measure-line? (eq 'C-measure-line (class-name (class-of (rtm-selection-1 (editor-collection-object self)))))))
      (when (or measure-line?
                (and (eq 'C-measure (class-name (class-of (rtm-selection-1 (editor-collection-object self)))))
                     (eq 'C-measure (class-name (class-of (rtm-selection-2 (editor-collection-object self))))))
                (eq 'C-measure (class-name (class-of (rtm-selection-1 (editor-collection-object self))))))
        (let* ((measures (measures (measure-line (current-rtm-editor (editor-collection-object self)))))
               (pos1 (position (rtm-selection-1 (editor-collection-object self)) measures)) 
               (pos2 (position (rtm-selection-2 (editor-collection-object self)) measures) ))
          (cond (measure-line? (tell measures 'set-unit+metronome unit metronome))
                ((and pos1 pos2)
                    (tell (subseq  measures (min pos1 pos2)(1+ (max pos1 pos2))) 'set-unit+metronome unit metronome))
                (pos1 (set-unit+metronome (nth pos1 measures) unit metronome)))
          ;; GA 12/4/94 crashes otherwise
          (invalidate-corners self (make-point 0 0) (view-size self))
          ;(erase+view-draw-contents (current-rtm-editor (editor-collection-object self)))
          )))))

(ui:add-menu-items  *RTM-selection-menu*                        
   (new-leafmenu "Metronome..." #'edit-rtm-editor-Metronome-menu))


;;================================================================================================
;; global editing
;;================================================================================================

(defvar *RTM-global-menu* (new-menu "Edit globally"))
(ui:add-menu-items *RTM-menu* *RTM-global-menu*)

;;========================================

(defmethod give-all-beat-chord-objects ((self C-rtm-editor-window))
  (let ((leaves-lst-lst  
           (ask-all (ask-all (beat-editors (editor-collection-object self)) #'measure-line)
                  #'collect-all-chord-beat-leafs)))
     (ask-all (apply #'append leaves-lst-lst) #'beat-chord)))

;;========================================
;;global transpose

(defun edit-rtm-editor-transpose-global-menu ()
   (open-rtm-win 'simple "Transpose (in cents)" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-transpose-global *active-rtm-window*  (value *rtm-win-1st-numbox*))
            (return-from-modal-dialog ()))
       :min1 -3600 :max1 3600 :val1 100))

(defmethod edit-rtm-editor-transpose-global ((self C-rtm-editor-window) cents)
  (with-cursor *watch-cursor*
      (tell (give-all-beat-chord-objects self) #'transpose-all-notes cents)
      ;; GA 12/4/94 crashes otherwise
      (invalidate-corners self (make-point 0 0) (view-size self))
      ;(erase+view-draw-contents (editor-collection-object self))
      ))

(ui:add-menu-items  *RTM-global-menu*                        
   (new-leafmenu "Transpose..." #'edit-rtm-editor-transpose-global-menu))

;;========================================
;;global chans

(defun edit-rtm-editor-chans-global-menu ()
   (open-rtm-win 'simple "Midi channel" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-chans-global *active-rtm-window*  (value *rtm-win-1st-numbox*))
           (return-from-modal-dialog ()))
       :min1 1 :max1 16 :val1 1))

(defmethod edit-rtm-editor-chans-global ((self C-rtm-editor-window) chan)
  (with-cursor *watch-cursor*
     (tell (give-all-beat-chord-objects self) #'set-all-chans chan)))

(ui:add-menu-items  *RTM-global-menu*                        
   (new-leafmenu "Channel..." #'edit-rtm-editor-chans-global-menu))

;;======

(defmethod edit-rtm-editor-chans-global-2 ((self C-rtm-editor-window))
   (with-cursor *watch-cursor*
         (let ((leaves-lst-lst  
                 (ask-all (ask-all (beat-editors (editor-collection-object self)) #'measure-line)
                      #'collect-all-chord-beat-leafs))
                   chords)
         (for (chan 1 1 (length leaves-lst-lst))
            (setq chords (ask-all (nth (1- chan) leaves-lst-lst) #'beat-chord))
            (tell chords #'set-all-chans chan)))))

(ui:add-menu-items  *RTM-global-menu*                        
   (new-leafmenu "Increment channel" #'(lambda () (edit-rtm-editor-chans-global-2 *active-rtm-window*))))

;;========================================
;;global duration

;;changed by aaa 28-08-95 from pw-modif
(defun edit-rtm-editor-duration-global-menu ()
   (open-rtm-win 'simple "Duration (in %)" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-duration-global *active-rtm-window*  (value *rtm-win-1st-numbox*))
           (return-from-modal-dialog ()))
       :min1 1 :max1 1000 :val1 100))

#|
(defun edit-rtm-editor-duration-global-menu ()
   (open-rtm-win 'simple "Duration (in %)" 
       #'(lambda (item) (declare (ignore item))
           (edit-rtm-editor-duration-global *active-rtm-window*  (value *rtm-win-1st-numbox*))
           (return-from-modal-dialog ()))
       :min1 1 :max1 1000 :val1 90))
|#

(defmethod edit-rtm-editor-duration-global ((self C-rtm-editor-window) dur1)
  (with-cursor *watch-cursor* 
    (setf *rtm-duration-scaler* (float (/ dur1 100)))
    (tell (ask-all (beat-editors (editor-collection-object self)) #'measure-line)
          #'calc-t-time-measure-line (get-play-speed (editor-collection-object self)))
    ;; GA 12/4/94 crashes otherwise
    (invalidate-corners self (make-point 0 0) (view-size self))
    ;(erase+view-draw-contents self)
    ))

(ui:add-menu-items  *RTM-global-menu*                        
   (new-leafmenu "Duration..." #'edit-rtm-editor-duration-global-menu))


;;========================================
;;Metronome

(defun edit-rtm-editor-Metronome-global-menu ()
  (without-interrupts
   (open-rtm-win 'range "Unit   Metronome"
                 #'(lambda (item) (declare (ignore item))
                    (edit-rtm-editor-Metronome-global *active-rtm-window*  (patch-value *rtm-win-1st-numbox* ())
                                                      (value *rtm-win-2nd-numbox*))
                    (return-from-modal-dialog ()))
                 :min1 1 :max1 32 :val1 5 :min2 10 :max2 360 :val2 60)
   (print "dialog has returned")))

(defmethod edit-rtm-editor-Metronome-global ((self C-rtm-editor-window) unit metronome)
  (with-cursor *watch-cursor* 
    (let ((measures (apply #'append (ask-all (ask-all (beat-editors (editor-collection-object self)) #'measure-line) #'measures))))
      (when measures
        (tell measures 'set-unit+metronome unit metronome)
        ;; GA 12/4/94 crashes otherwise
        (invalidate-corners self (make-point 0 0) (view-size self))
        ;(erase+view-draw-contents self)
        ))))

(ui:add-menu-items  *RTM-global-menu*                        
   (new-leafmenu "Metronome..." #'edit-rtm-editor-Metronome-global-menu))

;;================================================================================================================
;;layout
;;================================================================================================================

(defmethod edit-rtm-editor-staff-layout ((self C-rtm-editor-window) staff)
  (when (current-rtm-editor (editor-collection-object self))
    (setf (staff-number (current-rtm-editor (editor-collection-object self))) staff)
    (erase+view-draw-contents (current-rtm-editor (editor-collection-object self)))))

(defmethod edit-rtm-editor-staffs-layout ((self C-rtm-editor-window) staff)
  (let ((editors (beat-editors (editor-collection-object self))))
     (while editors (setf (staff-number (pop editors))  staff)))
   (erase+view-draw-contents self))

(ui:add-menu-items  *RTM-menu*    
   (new-menu "Choose Staff"
      (new-menu "Selected staff"
                           (new-leafmenu "G2-G" #'(lambda()     (edit-rtm-editor-staff-layout *active-rtm-window* 1)))  
                           (new-leafmenu "G" #'(lambda()        (edit-rtm-editor-staff-layout *active-rtm-window* 2))) 
                           (new-leafmenu "G F" #'(lambda()      (edit-rtm-editor-staff-layout *active-rtm-window* 3)))  
                           (new-leafmenu "F" #'(lambda()        (edit-rtm-editor-staff-layout *active-rtm-window* 4)))  
                           (new-leafmenu "G F F2" #'(lambda()   (edit-rtm-editor-staff-layout *active-rtm-window* 5)))  
                           (new-leafmenu "G2 G F F2" #'(lambda()(edit-rtm-editor-staff-layout *active-rtm-window* 6)))  
                           (new-leafmenu "Empty" #'(lambda()     (edit-rtm-editor-staff-layout *active-rtm-window* 7)))) 
      (new-menu "All staffs"
                           (new-leafmenu "G2-G" #'(lambda()     (edit-rtm-editor-staffs-layout *active-rtm-window* 1)))  
                           (new-leafmenu "G" #'(lambda()        (edit-rtm-editor-staffs-layout *active-rtm-window* 2))) 
                           (new-leafmenu "G F" #'(lambda()      (edit-rtm-editor-staffs-layout *active-rtm-window* 3)))  
                           (new-leafmenu "F" #'(lambda()        (edit-rtm-editor-staffs-layout *active-rtm-window* 4)))  
                           (new-leafmenu "G F F2" #'(lambda()   (edit-rtm-editor-staffs-layout *active-rtm-window* 5)))  
                           (new-leafmenu "G2 G F F2" #'(lambda()(edit-rtm-editor-staffs-layout *active-rtm-window* 6)))  
                           (new-leafmenu "Empty" #'(lambda()     (edit-rtm-editor-staffs-layout *active-rtm-window* 7))))))
                                                                                                       

