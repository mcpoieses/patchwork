;;;; -*- mode:lisp; coding:utf-8 -*-
(in-package :pw)           

;;================================================================
;;(defvar *selection-buttons-window* ())
(defvar *selection-buttons-x* ())
(defvar *selection-buttons-y* ())
;;(defvar  *global-pw-edit-control* ())
;;(defvar  *previous-global-pw-edit-control* ())
(defvar  *beat-leaf-objs* ())
;;================================================================
(defvar *selection-buttons-pool* ())
(defvar *rtm-struct-selection-scrap* ())
(defvar *measure-selection-scrap* ())
(defvar *measure-line-selection-scrap* ())
(defvar *beat-chord-scrap* ())
(defvar *rec-rtm-chs-list* ())

(defvar *current-rtm-editor* ())
(defvar *rtm-editor-velocity-list* ())
(defvar *active-RTM-window* ())

(defvar *rtm-last-chord-object* ())
(defvar *rtm-duration-scaler* 1.0)

(defvar *RTM-window-counter* 0)
(defvar *rtm-last-note-pixel* 0)
(defvar *measure-edit-mode* ()) ;???

(defvar *apps-RTM-menu-item* ())
(defvar *RTM-menu-root* ())
(defvar *rtm-help-window* ())

