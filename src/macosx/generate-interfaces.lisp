;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               generate-interfaces.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;
;;;;    Build the CCL Interface Databases.
;;;;
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2014-04-14 <PJB> Created.
;;;;BUGS
;;;;LEGAL
;;;;    GPL3
;;;;
;;;;    Copyright Pascal J. Bourguignon 2014 - 2014
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

(in-package :cl-user)
(require :asdf)
(require :parse-ffi)

(defparameter *additionnal-headers-directory*
  (make-pathname :name nil :type nil :version nil
                 :defaults (truename #.(or *compile-file-pathname* *load-pathname* #P"./"))))

(load (merge-pathnames "headers.lisp" *additionnal-headers-directory*))

(defun generate-interface (interface &key dependencies defines)
  (let* ((lc-interface (string-downcase interface))
         (kw-interface (intern (string-upcase interface) :keyword)))
    (add-headers-logical-pathname-translations lc-interface)
    (generate-populate.sh interface dependencies defines)
    (populate interface)
    (ccl::parse-standard-ffi-files kw-interface)
    (force-output)))

(generate-interface "CoreGraphics")
(generate-interface "CoreServices")
(generate-interface "MidiShare"  :defines '(("__Types__" 1)))
(generate-interface "Player"     :defines '(("__Types__" 1)) :dependencies '("MidiShare"))

;;;; THE END ;;;;
