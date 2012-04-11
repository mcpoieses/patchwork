;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

(in-package :pw)

;;================================================================================================================

(defvar *last-mouse-point* ())
(defvar *global-last-mouse-point* ())
(defvar *last-scroll-position* (make-point 0 0))
(defvar *BPF-scrap* ())

;;==================================================================================================================
;;==================================================================================================================

(defclass C-bpf-view (ui::scroller)
  ((break-point-function :initform nil :initarg :break-point-function 
     :accessor break-point-function)
   (edit-mode :initform "edit" :accessor edit-mode)
   (active-point :initform nil :accessor active-point)
   (mini-view :initform nil :accessor mini-view)
   (sel-start :initform 0 :accessor sel-start)
   (sel-end :initform 0 :accessor sel-end)
   (show-bpf-grid-fl :initform nil :accessor show-bpf-grid-fl)
   (h-view-scaler :initform 1.0 :initarg :h-view-scaler :accessor h-view-scaler)
   (v-view-scaler :initform 1.0 :initarg :v-view-scaler :accessor v-view-scaler)))


;;=====================================

;;(defmethod scroll-bar-limits ((view C-bpf-view))
;;  (ui::normal-scroll-bar-limits view 300 300))

(defmethod ui::normal-scroll-bar-limits ((view C-bpf-view) max-h &optional max-v)
  (declare (ignore max-h max-v))
  (values (make-point -500 500)
          (make-point -500 500)))

(defmethod ui::scroll-bar-page-size ((view C-bpf-view))
  (round (view-size view) 2))

(defmethod reset-active-point ((self C-bpf-view)) (setf (active-point self) nil))

;;=====================================
;; selection

(defmethod reset-selection-1 ((self C-bpf-view)) 
   (setf (sel-start self) 0)(setf (sel-end self) 0))

(defmethod reset-selection ((self C-bpf-view)) 
 (if (shift-key-p)
     (let ((x1-now (read-from-string (dialog-item-text (x-disp-ctrl (view-window self))))))
        (draw-selection self)
        (setf *last-mouse-point* 
           (make-point
             (if (< x1-now (sel-start self)) (sel-end self) (sel-start self)) 0))
        (setf (sel-start self) (min x1-now (sel-start self)))
        (setf (sel-end   self) (max x1-now (sel-end self)))
        (draw-selection self)
        (selection-rect-dragged self))
     (when (selection? self) 
       (draw-selection self)
       (setf (sel-start self) 0)(setf (sel-end self) 0))))

(defmethod selection? ((self C-bpf-view))
  (not (= (sel-start self) (sel-end self))))

(defmethod draw-selection ((self C-bpf-view))
  (with-focused-view self
   (with-pen-state (:mode :patxor)
     (let* ((x (round (sel-start self) (h-view-scaler self)))
            (w (- (round (sel-end self) (h-view-scaler self)) x)))
       (fill-rect* x (point-v (view-scroll-position self)) w (h self))))))

(defmethod selection-rect-dragged ((self C-bpf-view))
  (let ((x1-now (read-from-string (dialog-item-text (x-disp-ctrl (view-window self)))))
        (x2-now (point-h *last-mouse-point*)))
    (draw-selection self)
    (setf (sel-start self) (min x1-now x2-now))
    (setf (sel-end   self) (max x1-now x2-now))
;;    (print (list (sel-start self) (sel-end self)))
    (draw-selection self)))
     
;;=====================================
;; select-all cut copy paste
(defmethod select-all-bpf ((self C-bpf-view)) 
  (draw-selection self)
  (setf (sel-start self) (1- (car (x-points (break-point-function self)))))
  (setf (sel-end   self) (1+ (car (last (x-points (break-point-function self))))))
  (draw-selection self))

(defmethod cut-bpf ((self C-bpf-view)) 
  (let ((points (copy-bpf self)))
    (when points
      (while points (remove-point-from-bpf (break-point-function self) (pop points)))
      (add-constant-x-after-x-val (break-point-function self)
          (sel-end self)
          (- (sel-start self) (sel-end self)))
      (reset-selection-1 self)
;;      (print (x-points (break-point-function self)))
      (update-bpf-view self))))

(defmethod copy-bpf ((self C-bpf-view)) 
  (setf *BPF-scrap*
    (give-points-in-time-range (break-point-function self) (sel-start self) (sel-end self))))

(defmethod paste-bpf ((self C-bpf-view)) 
 (when *BPF-scrap*
  (when (selection? self)
    (let ((points  
            (give-points-in-time-range (break-point-function self) (sel-start self) (sel-end self))))
      (while points (remove-point-from-bpf (break-point-function self) (pop points)))))
  (let ((points (copy-list *BPF-scrap*)) (temp)(first-x)
        (cursor-x-now (read-from-string (dialog-item-text (x-disp-ctrl (view-window self))))))
    (setq first-x (point-h (car points)))
    (while points 
      (push 
         (make-point
           (+ (- (point-h (car points)) first-x) 
              (if (selection? self)
                (sel-start self)
                cursor-x-now))
           (point-v (car points)))
         temp)
       (pop points))
    (setq points (nreverse temp))
    (add-constant-x-after-x-val (break-point-function self) 
       (if (selection? self)
           (sel-end self)
           cursor-x-now)
        (+ (- (point-h (car (last points))) (point-h (car points)))
          (if (selection? self)
             (- (sel-start self)(sel-end self))
             0)))
    (while points (insert-point-by-h (break-point-function self) (pop points)))
    (reset-selection-1 self)
    (update-bpf-view self))))

;;(mapcar 'point-h *BPF-scrap*)
;;(mapcar 'point-v *BPF-scrap*)
;;=====================================
;;   

#|(defmethod scale-selection-by-time ((self C-bpf-view) h-scaler)
  (when (selection? self)
    (let ((points (give-points-in-time-range (break-point-function self)
                                             (sel-start self)) (print(sel-end self))))
      (if points
        (let* ((h-points (mapcar #'point-h points))
               (min-v (apply #'min h-points))  
               (max-v (apply #'max h-points))
               new-xs new-selection-end)
          (setq new-xs (scale-low-high h-points min-v  (+ min-v (* h-scaler (- max-v min-v))) t))
          (add-constant-x-after-x-val (break-point-function self) 
                                      (sel-end self) 
                                      (- (setq new-selection-end (car (last new-xs))) (sel-end self)))
          (set-new-xs-in-range (break-point-function self) (sel-start self) (sel-end self) new-xs) 
          (setf (sel-end self) (1+ new-selection-end))
          (update-bpf-view self))))))|#

(defmethod scale-selection-by-time ((self C-bpf-view) h-scaler)
  (when (selection? self)
    (let ((points (give-points-in-time-range (break-point-function self)
                                             (sel-start self) (sel-end self))))
      (if points
        (let* ((h-points (mapcar #'point-h points))
               (min-v (apply #'min h-points))  
               (max-v (apply #'max h-points))
               (previous-points (get-points-range self min-v #'<))
               (after-points (get-points-range self max-v #'>))
               new-xs new-selection-end new-sel-begin)
          (setq new-xs
                (if (second points)
                  (scale-low-high h-points min-v  (+ min-v (* h-scaler (- max-v min-v))) t)
                  (list (round (* min-v h-scaler)))))
          (setq new-selection-end (car (last new-xs)) new-sel-begin (car new-xs))
          (set-break-point-function (break-point-function self)
              (nconc previous-points
                     (mapcar #'make-point new-xs (ask-all points #'point-v))
                     after-points))
          (setf (sel-end self) (1+ new-selection-end))
          (setf (sel-start self) (1- new-sel-begin))
          (update-bpf-view self))))))

(defmethod get-points-range ((self C-bpf-view) x-val (fun function))
  (let ((all-points (break-point-list (break-point-function self)))
        res)
    (dolist (point all-points (nreverse res))
      (if (funcall fun (point-h point) x-val) (push point res)))))

(defmethod expand-selection-by-time ((self C-bpf-view)) (scale-selection-by-time self 1.05))

(defmethod shrink-selection-by-time ((self C-bpf-view)) (scale-selection-by-time self 0.95))

(defmethod scale-selection-by-value ((self C-bpf-view) v-scaler)
  (when (selection? self)
    (let ((points (give-points-in-time-range (break-point-function self)
                                             (sel-start self) (sel-end self))))
      (if points
        (let* ((v-points (mapcar #'point-v points))
               (min-v (apply #'min v-points))  
               (max-v (apply #'max v-points))
               new-ys)  
          (setq new-ys (scale-low-high v-points min-v  (+ min-v (* v-scaler (- max-v min-v))) t))
          (set-new-ys-in-range (break-point-function self) (sel-start self) (sel-end self) new-ys) 
          (update-bpf-view self))))))

(defmethod expand-selection-by-value ((self C-bpf-view)) (scale-selection-by-value self 1.05))

(defmethod shrink-selection-by-value ((self C-bpf-view)) (scale-selection-by-value self 0.95))
      
;;=====================================
;;moved dragged 

;;??
(defmethod view-position-dragged ((self C-bpf-view))
   (let ((point-diff (subtract-points (view-mouse-position (view-window self))  
                                      *global-last-mouse-point*)))
     (set-view-scroll-position self
       (subtract-points *last-scroll-position*
         (make-point
           (round (point-h point-diff) (h-view-scaler self))
           (round (point-v point-diff) (v-view-scaler self)))))
     (update-bpf-origo-ctrls self)
     (update-bpf-scroll-bar-settings self)))

(defmethod draw-zoom-hair-line ((self C-bpf-view) where)
  (warn "~S ~S is not implemented" 'draw-zoom-hair-line 'C-bpf-view)
   ;; (rlet ((user-rect :rect))
   ;;    (#_pt2rect :long where
   ;;                :long (grow-gray-rect where 0 (wptr self) nil)
   ;;                :ptr user-rect)
   ;; (let ((rect-w (abs (- (point-h *last-mouse-point*)(point-h (view-mouse-position self)))))
   ;;       (rect-h (abs (- (point-v *last-mouse-point*)(point-v (view-mouse-position self))))))
   ;;   (setf (h-view-scaler self) (max 0.07 (/ rect-w (w self)))) 
   ;;   (setf (v-view-scaler self) (max 0.07 (/ rect-h (h self))))  
   ;;   (set-origin self 
   ;;       (make-point (round (point-h *last-mouse-point*) (h-view-scaler self)) 
   ;;                   (- (h self) (round (point-v *last-mouse-point*) (v-view-scaler self)))))
   ;;  (update-bpf-scroll-bar-settings self)
   ;;  (update-bpf-view self)))
   )

(defmethod view-mouse-dragged ((self C-bpf-view) mouse)
 (setq mouse (view-mouse-position self))
 (let* ((mouse-h (point-h mouse))
        (mouse-v (point-v mouse))
        (new-point (make-point mouse-h mouse-v)))
  (display-mouse-moved self mouse-h mouse-v)
  (cond 
    ((string= (edit-mode self) "sel") 
       (selection-rect-dragged self))
    ((string= (edit-mode self) "zoom") 
       (draw-zoom-hair-line self (view-mouse-position (view-window self))))
    ((string= (edit-mode self) "drag")
       (view-position-dragged self))
    (t (when (active-point self)
         (setf *bpf-view-draw-lock* nil)
         (when (<= *prev-point-h-val* (point-h new-point) *next-point-h-val*)
           (with-focused-view self
             (draw-bpf-function-xor self)
             (set-break-point-function (break-point-function self)
               (subst new-point (active-point self) 
                 (break-point-list (break-point-function self)) :test #'eql))        
             (setf (active-point self) new-point) 
             (draw-bpf-function-xor self))))))))

(defmethod view-mouse-up ((self C-bpf-view)) 
  (unless *bpf-view-draw-lock* (update-bpf-view self)))
;; (with-focused-view self
;;   (draw-bpf-function (break-point-function self) self t (h-view-scaler self)(v-view-scaler self))))

;;(unless *bpf-view-draw-lock* (update-bpf-view self)))

(defmethod display-mouse-moved ((self C-bpf-view) mouse-h mouse-v)
  (set-dialog-item-text  (x-disp-ctrl (view-window self)) (format nil "~5D" mouse-h))
  (set-dialog-item-text  (y-disp-ctrl (view-window self)) (format nil "~5D" mouse-v)))   

(defmethod view-mouse-moved ((self C-bpf-view) mouse)
  (setq mouse (view-mouse-position self))
  (let* ((mouse-h (point-h mouse))
         (mouse-v (point-v mouse)))
    (setf (active-point self) (find-mouse-point-in-bpf- self mouse-h mouse-v)) 
    (if (active-point self) 
       (progn  
          (display-mouse-moved self (point-h (active-point self))(point-v (active-point self))))
      (display-mouse-moved self mouse-h mouse-v)))) 

;;=====================================

(defmethod view-mouse-position ((self C-bpf-view))
  (let* ((mouse (call-next-method))
         (h-view-scaler (h-view-scaler self))
         (v-view-scaler (v-view-scaler self))
         (new-y (- (point-v (view-size self)) (point-v mouse))))
    (make-point (round (* h-view-scaler (point-h mouse)))
                (round (* v-view-scaler new-y)))))

(defmethod set-size-view-window-grown ((self C-bpf-view))
  (set-view-size self (subtract-points (view-size (view-window self)) (make-point 10 57)))) 

#|
(defmethod view-window-grown ((self C-bpf-view))
  (set-size-view-window-grown self) 
  (scale-to-fit-in-rect self)
  (update-bpf-scroll-bar-settings self)
  (update-bpf-view self))
|#

(defmethod view-window-grown ((self C-bpf-view))
  (set-size-view-window-grown self) 
  (scale-to-fit-in-rect self)
  (update-bpf-scroll-bar-settings self))


;;=====================================
;;draw
(defvar *axis-strings* ())

(progn
  (for (i -1000 100 1000) (push (format nil "~5D" i) *axis-strings*))
  (setq *axis-strings* (nreverse *axis-strings*)))

(defmethod draw-bpf-function-xor ((self C-bpf-view))
  (draw-bpf-function-from-point-1-to-2 (break-point-function self)
      self t (h-view-scaler self)(v-view-scaler self)
      *prev-point-h-val* *next-point-h-val*))

(defmethod view-draw-axis ((self C-bpf-view))
  (let* ((h-view-scaler (h-view-scaler self))
         (v-view-scaler (v-view-scaler self))
         (y (point-v (view-size self)))
         (x-off 3)(-x-off -3)
         (y-off (+ y 3))(-y-off (- y 3))
         temp-x temp-y 
         (axis-strings *axis-strings*))
  (with-pen-state (:pattern *gray-pattern*) 
   (draw-line (round -1000 h-view-scaler) y (round  1000 h-view-scaler) y)
   (draw-line 0 (- y (round  -1000 v-view-scaler)) 0 (- y (round 1000 v-view-scaler)))
   (for (i -1000 100 1000)
      (setq temp-x (round i h-view-scaler) temp-y (- y (round i v-view-scaler)))
      (draw-string (- temp-x 20) (+ y-off 10) (car axis-strings))
      (draw-line temp-x y-off temp-x -y-off)
      (when (not (zerop i)) (draw-string -32 (+ temp-y 5) (car axis-strings)))
      (pop axis-strings)
      (draw-line x-off temp-y -x-off temp-y)))))
       
(defmethod view-draw-contents ((self C-bpf-view))
  (let ((*no-line-segments* (display-only-points (view-container (mini-view self)))))
    (with-focused-view self
      (when (show-bpf-grid-fl self) (view-draw-axis self))
      (draw-bpf-function (break-point-function self) self t (h-view-scaler self)(v-view-scaler self))
      (call-next-method))
    (when (selection? self) (draw-selection self))))

(defmethod print-draw-contents ((self C-bpf-view))
    (with-focused-view self
      (when (show-bpf-grid-fl self) (view-draw-axis self))
      (draw-bpf-function (break-point-function self) self t (h-view-scaler self)(v-view-scaler self))))

;;=====================================
;; events

(defmethod insert-by-new-point ((self C-bpf-view) new-point)
  (setf (active-point self) new-point) 
  (insert-point-by-h (break-point-function self) new-point))

(defmethod find-mouse-point-in-bpf- ((self C-bpf-view) mouse-h mouse-v)
 (let* ((bps (break-point-list (break-point-function self)))
        (x-points (x-points (break-point-function self)))
        (y-points (y-points (break-point-function self)))
         active-point 
        (h-view-scaler (h-view-scaler self))
        (v-view-scaler (v-view-scaler self))
        point-h-now point-v-now
        (off-h (* h-view-scaler 3))
        (off-v (* v-view-scaler 3)))
   (while bps 
      (setq point-h-now (car x-points))
      (setq point-v-now (car y-points)) 
      (when (< (- point-h-now off-h) mouse-h (+ point-h-now off-h))
         (when (< (- point-v-now off-v) mouse-v (+ point-v-now off-v))
            (setq active-point (car bps))))
      (pop bps)(pop x-points)(pop y-points))
    active-point))

(defmethod view-click-event-handler ((self C-bpf-view) where)
 (declare (ignore where))
 (setf *bpf-view-draw-lock* t)
 (if (selection? self)
   (reset-selection self)
   (let ((new-point (view-mouse-position self)))
     (setf *last-mouse-point* new-point)
     (setf *global-last-mouse-point* (view-mouse-position (view-window self)))  
     (setf *last-scroll-position* (view-scroll-position self))
     (when (string= (edit-mode self) "edit")
       (unless (active-point self)
         (insert-by-new-point self new-point)
         (update-bpf-view self))
       (let ((x-range (give-prev+next-x (break-point-function self) (active-point self))))
           (setq *prev-point-h-val* (first x-range))
           (setq *next-point-h-val* (second x-range)))))))


#|(defmethod update-bpf-view ((self C-bpf-view) &optional mini-draw-lock)
  (with-focused-view self 
    (with-pen-state (:pattern *white-pattern*)
        (fill-rect*  (point-h (view-scroll-position self)) 
                     (point-v (view-scroll-position self)) (w self)(h self))))
  (view-draw-contents self)
  (update-bpf-origo-ctrls self)
  (unless mini-draw-lock
     (when (mini-view self) (update-mini-view (mini-view self)))))|#

(defmethod update-bpf-view ((self C-bpf-view) &optional mini-draw-lock)
  (let ((*no-line-segments* (and (pw-object (view-container self))
                                 (points-state (pw-object (view-container self))))))
    (with-focused-view self 
      (with-pen-state (:pattern *white-pattern*)
        (fill-rect*  (point-h (view-scroll-position self)) 
                     (point-v (view-scroll-position self)) (w self)(h self))))
    (view-draw-contents self)
    (update-bpf-origo-ctrls self)
    (unless mini-draw-lock
      (when (mini-view self) (update-mini-view (mini-view self))))))

(defmethod update-bpf-scroll-bar-settings ((self C-bpf-view))
   (set-scroll-bar-setting (ui::h-scroller self) (point-h (view-scroll-position self)))   
   (set-scroll-bar-setting (ui::v-scroller self) (point-v (view-scroll-position self))))   

(defmethod key-pressed-BPF-editor ((self C-bpf-view) char)
  (case char
    ((#\f) 
     (scale-to-fit-in-rect self)
     (update-bpf-scroll-bar-settings self)
     (update-bpf-zoom-ctrls self)
     (update-bpf-view self t)) 
    ((#\+)
     (setf (h-view-scaler self) (max 0.07 (* 0.9 (h-view-scaler self))))
     (setf (v-view-scaler self) (max 0.07 (* 0.9 (v-view-scaler self))))
     (update-bpf-zoom-ctrls self)
     (update-bpf-view self t)) 
    ((#\-) 
     (setf (h-view-scaler self) (* 1.1 (h-view-scaler self)))
     (setf (v-view-scaler self) (* 1.1 (v-view-scaler self)))
     (update-bpf-zoom-ctrls self)
     (update-bpf-view self t)) 
    ((#\K)
     (kill-all-except-first (break-point-function self))
     (update-bpf-view self)) 
    ((:backspace) 
     (when (active-point self)
       (remove-point-from-bpf (break-point-function self) (active-point self))
       (update-bpf-view self)))
    ((#\g) 
     (setf (show-bpf-grid-fl self) (not (show-bpf-grid-fl self)))
     (update-bpf-view self t)) 
    ((:BackArrow) (shrink-selection-by-time self))
    ((:ForwardArrow) (expand-selection-by-time self))
    ((:DownArrow) (shrink-selection-by-value self))
    ((:UpArrow) (expand-selection-by-value self))
    ((:Tab)
     (let* (ind 
            (ctrls (bpf-radio-ctrls (view-window self)))
            (len (length ctrls)))
       (for (i 0 1 (1- len))
            (when (radio-button-pushed-p (nth i ctrls))
              (setq ind (mod (1+ i) 4))
              (set-bpf-edit-mode (view-window self) (nth ind ctrls) (dialog-item-text (nth ind ctrls)))
              (setq i 100)))))
    ;;        ((#\e) (set-bpf-edit-mode (view-window self) 
    ;;             (first (bpf-radio-ctrls (view-window self))) "edit"))
    ;;        ((#\z) (set-bpf-edit-mode (view-window self) 
    ;;             (second (bpf-radio-ctrls (view-window self))) "zoom"))
    ;;        ((#\s) (set-bpf-edit-mode (view-window self) 
    ;;             (third (bpf-radio-ctrls (view-window self))) "sel"))
    ;;        ((#\d) (set-bpf-edit-mode (view-window self) 
    ;;             (fourth (bpf-radio-ctrls (view-window self))) "drag"))
    ;;        ((#\a) (select-all-bpf self)) 
    ;;        ((#\x) (cut-bpf self)) 
    ;;        ((#\c) (copy-bpf self)) 
    ;;        ((#\v) (paste-bpf self)) 
    (otherwise (ed-beep))))

(defmethod scroll-bar-changed :before ((view C-bpf-view) scroll-bar)
  (declare (ignore scroll-bar))
  (setf *bpf-view-draw-lock* t))

(defmethod scroll-bar-changed ((self C-bpf-view) scroll-bar)
  (declare (ignore scroll-bar))
  (call-next-method)
  (update-bpf-origo-ctrls self))

;;=====================================================
;; BPF window ctrls

(defmethod update-bpf-zoom-ctrls ((self C-bpf-view))  
  (set-dialog-item-text-from-dialog (x-zoom-ctrl (view-window self)) 
     (format nil "~5D" (round (* (w self)(h-view-scaler self)))))
  (set-dialog-item-text-from-dialog (y-zoom-ctrl (view-window self)) 
     (format nil "~5D" (round (* (h self)(v-view-scaler self))))))

(defmethod update-bpf-origo-ctrls ((self C-bpf-view))  
  (set-dialog-item-text-from-dialog (x-origo-ctrl (view-window self)) 
     (format nil "~5D" (round (* (point-h (view-scroll-position self)) (h-view-scaler self)))))
  (set-dialog-item-text-from-dialog (y-origo-ctrl (view-window self)) 
     (format nil "~5D" (- (round (* (point-v (view-scroll-position self)) (v-view-scaler self)))))))

(defmethod set-bpf-x-origo ((self C-bpf-view) ctrl)  
   (set-origin self 
       (make-point (round (value ctrl) (h-view-scaler self)) (point-v (view-scroll-position self))))
   (update-bpf-scroll-bar-settings self)
   (update-bpf-view self t))

(defmethod set-bpf-y-origo ((self C-bpf-view) ctrl)  
   (set-origin self 
       (make-point (point-h (view-scroll-position self)) 
                    (-  (round (value ctrl) (v-view-scaler self))) ))
   (update-bpf-scroll-bar-settings self)
   (update-bpf-view self t))

(defmethod set-bpf-x-zoom ((self C-bpf-view) ctrl) 
   (setf (h-view-scaler self) (/ (value ctrl) (w self))) 
   (update-bpf-view self t))

(defmethod set-bpf-y-zoom ((self C-bpf-view) ctrl)  
   (setf (v-view-scaler self) (/ (value ctrl) (h self))) 
   (update-bpf-view self t))
