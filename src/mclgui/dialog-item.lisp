;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               dialog-item.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;    
;;;;    Dialog-item.
;;;;    
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2012-05-19 <PJB> Created.
;;;;BUGS
;;;;LEGAL
;;;;    GPL3
;;;;    
;;;;    Copyright Pascal J. Bourguignon 2012 - 2012
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


(in-package "MCLGUI")


(defgeneric dialog-item-action-function (item)
  (:documentation "
The generic function DIALOG-ITEM-ACTION-FUNCTION returns the value set
by the :dialog-item-action initialization argument or the
set-dialog-item-action-function generic function.  Unless it is NIL,
this function is called with a single argument, item, by the
DIALOG-ITEM-ACTION method for DIALOG-ITEM.

This generic function is called by the view-click-event-handler method
for DIALOG-ITEM when the user clicks a dialog item.

ITEM:           A dialog item.
"))


(defgeneric dialog-item-enabled-p (item)
  (:documentation "
The generic function DIALOG-ITEM-ENABLED-P returns T if the dialog
item is enabled, and NIL if it is disabled.
"))


;; (defgeneric dialog-item-handle (item)
;;   (:documentation "
;; The generic function DIALOG-ITEM-HANDLE retrieves the handle
;; associated with item.  Dialog items are often associated with handles to
;; Macintosh data structures, such as control records.  By convention, this
;; handle is stored in the location referenced by dialog-item-handle and
;; modified by SET-DIALOG-ITEM-HANDLE.  The handle is usually NIL
;; when the dialog item is not contained in a window.  It is generally set by
;; INSTALL-VIEW-IN-WINDOW and is reset to NIL by REMOVE-VIEW-FROM-WINDOW.
;; "))



(defgeneric dialog-item-width-correction (item)
  (:documentation "
The generic function DIALOG-ITEM-WIDTH-CORRECTION returns an integer
representing the number of pixels of white space added to the left and
right of the text of a dialog item.  The default method for
DIALOG-ITEM returns 0.  Users can write methods for
DIALOG-ITEM-WIDTH-CORRECTION if they wish to specialize it for their
own classes of dialog items.
"))




(defclass dialog-item (simple-view)
  ((width-correction            :allocation :class
                                :initform 0 
                                :accessor dialog-item-width-correction)
   (dialog-item-text            :initarg :dialog-item-text
                                :initform ""
                                :accessor dialog-item-text)
   ;; (dialog-item-handle          :initarg :dialog-item-handle
   ;;                              :initform nil
   ;;                              :accessor dialog-item-handle)
   (dialog-item-enabled-p       :initarg :dialog-item-enabled-p
                                :initform t
                                :accessor dialog-item-enabled-p)
   (dialog-item-action-function :initarg :dialog-item-action
                                :initform nil
                                :accessor dialog-item-action-function))
  (:default-initargs :view-position nil :view-size nil)
  (:documentation "
The class DIALOG-ITEM provides the basic functionality shared by all
dialog items. It is built on SIMPLE-VIEW.
"))



(defmacro reference-method (generic-function (&rest classes))
  (niy reference-method generic-function classes)
  `(niy reference-method ',generic-function ',classes))


(defgeneric dialog-item-action-p (item)
  (:method ((item dialog-item))
    (or (dialog-item-action-function item)
        (not (eq (find-1st-arg-combined-method (function dialog-item-action) item)
                 (method-function (reference-method dialog-item-action (dialog-item))))))))


(defmacro do-dialog-items ((item-var dialog &optional (item-class ''dialog-item) must-be-enabled)
                           &body body)
  (let* ((enabled-var (gensym)))
    `(let ((,enabled-var ,must-be-enabled))
       (do-subviews (,item-var ,dialog ,item-class)
         (when (or (not ,enabled-var) (dialog-item-enabled-p ,item-var))
           ,@body)))))


(defgeneric call-with-focused-dialog-item (item fn &optional container)
  (:method (item fn &optional container)
    (call-with-focused-view (or container (view-container item))
                            (lambda (container)
                              (declare (ignore container))
                              (funcall fn item))
                            item)))


(defmacro with-focused-dialog-item ((item &optional container) &body body)
  "
The macro WITH-FOCUSED-DIALOG-ITEM executes body with the drawing
environment set up in the coordinate system of container and the font
of item. This is the correct environment for calling VIEW-DRAW-CONTENTS
on a dialog item.  When the body exits (normally or abnormally), the
old drawing environment is restored.

ITEM:           A dialog item (or any simple view).

CONTAINER:      The view focused on whose coordinate system body will
                run.
"
  (let ((item-var (if (symbolp item) item (gensym))))
    `(call-with-focused-dialog-item ,item
                                    (lambda (,item-var)
                                      (declare (ignorable ,item-var))
                                      ,@body)
                                    ,@(when container `(,container)))))





(defgeneric dialog-items (view &optional item-class must-be-enabled)
  (:documentation "
The DIALOG-ITEMS generic function returns a list of the dialog items
in view.

VIEW:           A view.

ITEM-CLASS:     If the value of item-class is specified and non-nil,
                then only dialog items matching item-class are
                returned. The default value is NIL.

MUST-BE-ENABLED:
                If the value of must-be-enabled is true, then only
                dialog items that are enabled are returned.  The
                default value is NIL.
")
  (:method ((view view) &optional (item-class 'dialog-item) (must-be-enabled nil))
    (let ((result '()))
      (do-dialog-items (this-item view item-class must-be-enabled)
        (push this-item result))
      (nreverse result))))


(defun make-dialog-item (class position size text &optional action &rest attributes)
  "
The MAKE-DIALOG-ITEM function creates a dialog item using makeinstance.

CLASS:          The class of the dialog item.

POSITION:       The position of the dialog item with respect to its
                container.

SIZE:           The size of the dialog item.

TEXT:           The text included within the dialog item.

ACTION:         The action associated with the dialog item.

ATTRIBUTES:     One or more attributes belonging to the dialog
                item. The number and nature of these depend on the
                type of dialog item.
"
  (apply (function make-instance) class
         (append (when position (list :view-position      position))
                 (when size     (list :view-size          size))
                 (when text     (list :dialog-item-text   text))
                 (when action   (list :dialog-item-action action))
                 attributes)))


(defgeneric dialog-item-action (item)
  (:documentation "
The generic function DIALOG-ITEM-ACTION is called whenever the user
clicks a dialog item.  The method for DIALOG-ITEM calls item’s
DIALOG-ITEM-ACTION-FUNCTION, if it is not NIL.  Otherwise, it does
nothing. 

The DIALOG-ITEM-ACTION function is normally called when the mouse
button is released, not when it is pressed. 

If an item is disabled, its action is not run. 

Since dialog-item-action is usually called by view-click-eventhandler
as a result of event processing, event processing is ordinarily
disabled while the DIALOG-ITEM-ACTION function is running.  This means
that other dialog items cannot be selected during the action.  To
avoid locking out other event processing, you can use EVAL-ENQUEUE to
insert forms into the read-eval-print loop.  For details, see Chapter
10: Events. 

ITEM:           A dialog item.
")
  (:method ((item dialog-item))
    (let ((fun (dialog-item-action-function item)))
      (when fun
        (funcall fun item)))))


(defgeneric set-dialog-item-action-function (item new-function)
  (:documentation "
The generic function DIALOG-ITEM-ACTION-FUNCTION sets the value it
accesses.

ITEM:           A dialog item.

NEW-FUNCTION:   A function of one argument or a symbol that has a global
                function binding or is NIL.
")
  (:method ((item dialog-item) new-function)
    (setf (dialog-item-action-function item) new-function)))


(defmethod view-click-event-handler ((item dialog-item) where)
  "
The generic function VIEW-CLICK-EVENT-HANDLER is called by the event
system when the user clicks the dialog item.  The method for
DIALOG-ITEM calls item’s DIALOG-ITEM-ACTION-FUNCTION with item as the
single argument.  If item’s DIALOG-ITEM-ACTION-FUNCTION is NIL,
nothing is done.

ITEM:           A dialog item.

WHERE:          The cursor position.
"
  (declare (ignore where))
  (dialog-item-action item))


(defmethod view-focus-and-draw-contents ((item dialog-item) &optional visrgn cliprgn)
  "
The method for dialog items of the generic function
VIEW-FOCUS-AND-DRAW-CONTENTS focuses on the container of the dialog
item, then calls VIEW-DRAW-CONTENTS.

ITEM:           A dialog item.

VISRGN:         Region records from the view’s wptr.  They are ignored.

CLIPRGN:        Region records from the view’s wptr.  They are ignored.
"
  (declare (ignore visrgn cliprgn))
  (unless (view-quieted-p item)
    (without-interrupts
     (with-focused-view (view-container item)
       (with-temp-rgns (visrgn cliprgn)
         (niy view-focus-and-draw-contents item visrgn cliprgn)
         ;; (get-window-visrgn  (wptr item) visrgn)
         ;; (get-window-cliprgn (wptr item) cliprgn)      
         (when (view-is-invalid-p item visrgn cliprgn)
           (call-with-focused-dialog-item item (function view-draw-contents))))))))


(defmethod set-view-position ((item dialog-item) h &optional v)
  (let ((new-position (make-point h v)))
    (unless (point= new-position (view-position item))
      (with-focused-dialog-item (item)
        (without-interrupts
            (let ((window (view-window item)))
              (when window
                (invalidate-view item t))
              (call-next-method)
              (invalidate-view item t)))))
    new-position))


(defmethod set-view-size ((item dialog-item) h &optional v)
  "
The method for dialog items of the generic function SET-VIEW-SIZE
changes the size of the dialog item to the width and height
represented by h and v, and returns the new size.
"
  (let ((new-size (make-point h v)))
    (unless (point= new-size (view-size item))
      (with-focused-dialog-item (item)
        (without-interrupts
            (let ((window (view-window item)))
              (when window
                (invalidate-view item t))
              (call-next-method)
              (invalidate-view item t)))))
    new-size))


(defgeneric set-dialog-item-text (item text)
  (:documentation "
The generic function SET-DIALOG-ITEM-TEXT sets the text associated
with the dialog item to text and returns text.
")
  (:method ((item dialog-item) text)
    (setf (slot-value item 'dialog-item-text) (copy-seq text))
    text)
  (:method :after ((item dialog-item) text)
           (declare (ignore text))
           (invalidate-view item)))



(defmethod set-view-font :after ((item dialog-item) font-spec)
  (declare (ignore font-spec))
  (invalidate-view item))


(defgeneric dialog-item-enable (item)
  (:documentation "
The generic function DIALOG-ITEM-ENABLE enables the dialog item.  The
item is not dimmed, and its action is run when the user clicks it.
The function returns NIL.
")
  (:method ((item dialog-item))
    (without-interrupts
        (unless (dialog-item-enabled-p item)
          (setf (dialog-item-enabled-p item) t)
          (invalidate-view item)))
    nil))


(defgeneric dialog-item-disable (item)
  (:documentation "
The generic function DIALOG-ITEM-DISABLE disables the dialog item.
The dialog item is dimmed; clicks in the item are ignored, and the
action of the item is never run.  Disabling a checkbox does not alter
its status as checked, and disabling a radio button does not alter its
status as clicked (you may want to remove the check or click
explicitly).  The function returns NIL. 
")
  (:method ((item dialog-item))
    (without-interrupts
        (when (dialog-item-enabled-p item)
          (setf (dialog-item-enabled-p item) nil)
          (invalidate-view item)))))


(defgeneric set-dialog-item-enabled-p (item enabled-p)
  ;; Not exported.
  (:documentation "
DO:             Enable or disable the dialog ITEM depending on ENABLED-P.
")
  (:method ((item dialog-item) enabled-p)
    (unless (eq (not enabled-p)
                (not (dialog-item-enabled-p item)))
      (if enabled-p
          (dialog-item-enable  item)
          (dialog-item-disable item)))))




(defmethod view-outer-size ((view simple-view))
  (let ((old-pos  (view-position view))
        (old-size (view-size view)))
    (unless old-pos  (setf (slot-value view 'view-position) 0))
    (unless old-size (setf (slot-value view 'view-size) (view-default-size view)))
    (multiple-value-bind (tl br) (view-corners view)        
      (setf (slot-value view 'view-position) old-pos)
      (subtract-points br tl))))


(defmethod view-find-vacant-position ((view view) subview)
  (let* ((size       (view-outer-size subview))
         (inner-size (view-size subview))
         (height     (point-v size))
         (width      (point-h size))
         (w-size     (view-size view))
         (w-height   (point-v w-size))
         (w-width    (point-h w-size))
         (rect-rgn   (new-rgn))
         (vacant-rgn (new-rgn))
         (v-list     (list 4))
         (h-list     (list 4))
         (h-delta    (ash (- (point-h size) (point-h inner-size)) -1))
         (v-delta    (ash (- (point-v size) (point-v inner-size)) -1)))
    (niy view-find-vacant-position view subview)
    ;; (unwind-protect
    ;;      (progn
    ;;        (rlet ((s-rect :rect :topleft #@(0 0) :bottomright w-size))
    ;;              (#_RectRgn vacant-rgn s-rect)
    ;;              (dovector (item (view-subviews view))
    ;;                        (let ((position (view-position item))
    ;;                              (size (view-outer-size item)))
    ;;                          (unless (or (eq item subview) (not position))                
    ;;                            (let ((lower-right (add-points position size)))
    ;;                              (rset s-rect :rect.topleft position)
    ;;                              (rset s-rect :rect.bottomright lower-right))
    ;;                            (#_InsetRect s-rect -4 -4)
    ;;                            (#_RectRgn rect-rgn s-rect)
    ;;                            (#_DiffRgn vacant-rgn rect-rgn vacant-rgn)
    ;;                            (pushnew (%i+ 6 (rref s-rect :rect.right)) h-list)
    ;;                            (pushnew (%i+ 6 (rref s-rect :rect.bottom)) v-list))))
    ;;              (setq v-list (sort v-list #'<)
    ;;                    h-list (sort h-list #'<))
    ;;              (dolist (v v-list)
    ;;                (dolist (h h-list)
    ;;                  (#_SetRectRgn rect-rgn h v (%i+ h width) (%i+ v height))
    ;;                  (#_UnionRgn  vacant-rgn rect-rgn rect-rgn)
    ;;                  (when (and (#_EqualRgn rect-rgn vacant-rgn)
    ;;                             (%i< (%i+ v height) w-height)
    ;;                             (%i< (%i+ h width) w-width))
    ;;                    (return-from view-find-vacant-position (make-point (+ h h-delta)(+ v v-delta)))))))
    ;;        (return-from view-find-vacant-position #@(0 0)))
    ;;   (#_disposergn vacant-rgn)
    ;;   (#_disposergn rect-rgn))
    (return-from view-find-vacant-position #@(0 0))))



(defun font-codes-string-width-with-eol (string ff ms)  
  (let ((pos 0)
        (nextpos 0)
        (nlines 1)
        (max 0))
    (declare (fixnum nlines))
    (loop
      (if (setq nextpos (string-eol-position string pos))
        (progn
          (setq max (max max (font-codes-string-width string ff ms pos nextpos)))
          (setq nlines (1+ nlines))
          (setq pos (1+ nextpos)))
        (return (values (max max (font-codes-string-width string ff ms pos))
                        nlines))))))


(defmethod view-default-size ((item dialog-item))
  "
The generic function VIEW-DEFAULT-SIZE is called by the default
version of INSTALL-VIEW-IN-WINDOW.  It is called for dialog items that
are not given an explicit size.  The DIALOG-ITEM method of
VIEW-DEFAULT-SIZE calculates a size according to the font and text of
the dialog item and the width correction associated with the class of
the dialog item. (See the documentation of
dialog-item-width-correction.)
"
  (multiple-value-bind (ff ms) (view-font-codes item)
    (let* ((text (dialog-item-text item)))
      (multiple-value-bind (string-width nlines)  (font-codes-string-width-with-eol text ff ms)
        (make-point (+ (dialog-item-width-correction item) string-width)
                    (* nlines (font-codes-line-height ff ms)))))))


(defmethod set-default-size-and-position ((view simple-view) &optional container)
  (when (view-size view)
    (setf (slot-value view 'view-size) (view-default-size view)))
  (when (view-position view)
    (let ((container (or container (view-container view)))) 
      (when container
        (setf (slot-value view 'view-position) (view-find-vacant-position container view))))))



(defmethod install-view-in-window ((item dialog-item) dialog)
  "
The generic function INSTALL-VIEW-IN-WINDOW is called by setview-
container when an item becomes part of a view.

This function performs initialization tasks that require the
containing window.  It should never be called directly by user
code. However, it may be shadowed.  Specialized versions of
INSTALL-VIEW-IN-WINDOW should always perform CALL-NEXT-METHOD.

The default method sets the size of the dialog item if it does not
already have one, and finds an empty position for the dialog item if
it does not already have a position.

"
  (declare (ignore dialog))
  (without-interrupts
      (let ((ok nil))
        (call-next-method)
        (unwind-protect
             (let ((container (view-container item)))
               (set-default-size-and-position item container)
               (set-part-color-loop item (part-color-list item))
               (unless (dialog-item-enabled-p item)
                 (dialog-item-disable item))
               (setq ok t))
          (unless ok
            (set-view-container item nil)))))
  nil)


(defmethod remove-view-from-window ((dialog-item dialog-item))
  "
The generic function remove-view-from-window is called when a
dialog item is removed from a view by a call to set-view-container.
It should never be called directly by user code. However, it may be
shadowed. Specialized versions of remove-view-from-window should
dispose of any Macintosh data the item uses (that is, data not subject to
garbage collection) and should always perform a call-next-method."
  (call-next-method))


;; (defmethod set-dialog-item-handle ((item dialog-item) new-value)
;; "
;; The generic function set-dialog-item-handle sets the dialog item
;; handle associated with item to a new handle.
;; "
;;   (setf (dialog-item-handle item) new-value))


(defmethod view-activate-event-handler :around ((item dialog-item))
  "
The generic function VIEW-ACTIVATE-EVENT-HANDLER is called when
the window containing the dialog item is activated.

If the appearance of the dialog item needs to change to indicate that it is
active, this is the method that should make that change.  For example, Fred
dialog items change their highlighting from a pixelwide box to a solid
rectangle and scroll bars make their arrows and scroll box visible.

The VIEW-ACTIVATE-EVENT-HANDLER generic function is called by
SET-VIEW-CONTAINER if the window in which the newly installed view
appears is active.
"
  (with-focused-dialog-item (item)
    (call-next-method)))


(defmethod view-deactivate-event-handler :around ((item dialog-item))
  "
The generic function VIEW-DEACTIVATE-EVENT-HANDLER is called when the
window containing the dialog items is deactivated.

If the appearance of the dialog item needs to change to indicate that
it is not active, this is the method that should make that change.
For example, Fred dialog items change their highlighting from a solid
rectangle to a 1-pixel-wide box and scroll bars become an empty
rectangle.

The VIEW-DEACTIVATE-EVENT-HANDLER generic function is called by
SET-VIEW-CONTAINER if the window in which the newly installed view
appears is not active.
"
  (with-focused-dialog-item (item)
    (call-next-method)))





;;;; THE END ;;;;