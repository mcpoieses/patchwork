;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;=========================================================
;;;;
;;;;  PATCH-WORK
;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.
;;;;  © 1986-1992 IRCAM 
;;;;
;;;;=========================================================

;;;
;;;PW Data Boxes
;;;
(in-package :pw)

(defunp const ((const list (:type-list ()))) nil
  "This module controls numerical values or lists  (on many levels). It accepts 
either numerical values, symbols, or mixed values. It returns a list without 
evaluating it, and it can also be useful for control of many inputs that must have 
the same list."
  const)

(defunp evconst ((const (list (:value "()")))) nil
  "This module controls numerical values or lists (on many levels). It accepts 
either numerical values, symbols, or mixed values. It returns the evaluation of 
its input. This module behaves like the Lisp expression (eval const), where 
const is the input value of the module. For example, if one writes (+ 1 2) the 
output is 3. "
  (eval const))

(defunp numbox ((val fix/float)) number
"The numbox module accepts integers and floating-point values.
 It returns the value it receives on its input. 
This module is useful for controlling many inputs that must 
have the same value. 
"
 val)
