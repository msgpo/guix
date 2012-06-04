;;; Guix --- Nix package management from Guile.         -*- coding: utf-8 -*-
;;; Copyright (C) 2012 Ludovic Courtès <ludo@gnu.org>
;;;
;;; This file is part of Guix.
;;;
;;; Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Guix.  If not, see <http://www.gnu.org/licenses/>.


(define-module (test-derivations)
  #:use-module (guix derivations)
  #:use-module (guix store)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-64)
  #:use-module (rnrs io ports)
  #:use-module (ice-9 rdelim))

(define %store
  (false-if-exception (open-connection)))

(test-begin "derivations")

(test-assert "parse & export"
  (let* ((b1 (call-with-input-file "test.drv" get-bytevector-all))
         (d1 (read-derivation (open-bytevector-input-port b1)))
         (b2 (call-with-bytevector-output-port (cut write-derivation d1 <>)))
         (d2 (read-derivation (open-bytevector-input-port b2))))
    (and (equal? b1 b2)
         (equal? d1 d2))))

(test-skip (if %store 0 2))

(test-assert "derivation with no inputs"
  (let ((builder (add-text-to-store %store "my-builder.sh"
                                    "#!/bin/sh\necho hello, world\n"
                                    '())))
    (store-path? (derivation %store "foo" "x86_64-linux" builder
                             '() '(("HOME" . "/homeless")) '()))))

(test-assert "build derivation with 1 source"
  (let*-values (((builder)
                 (add-text-to-store %store "my-builder.sh"
                                    "#!/bin/sh\necho hello, world > \"$out\"\n"
                                    '()))
                ((drv-path drv)
                 (derivation %store "foo" "x86_64-linux"
                             "/bin/sh" `(,builder)
                             '(("HOME" . "/homeless"))
                             `((,builder))))
                ((succeeded?)
                 (build-derivations %store (list drv-path))))
    (and succeeded?
         (let ((path (derivation-output-path
                      (assoc-ref (derivation-outputs drv) "out"))))
           (string=? (call-with-input-file path read-line)
                     "hello, world")))))

(test-end)


(exit (= (test-runner-fail-count (test-runner-current)) 0))

;;; Local Variables:
;;; eval: (put 'test-assert 'scheme-indent-function 1)
;;; End:
