;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013, 2014 Ludovic Courtès <ludo@gnu.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (guix build-system trivial)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (guix derivations)
  #:use-module (guix packages)
  #:use-module (guix build-system)
  #:use-module (ice-9 match)
  #:export (trivial-build-system))

(define (guile-for-build store guile system)
  (match guile
    ((? package?)
     (package-derivation store guile system))
    ((and (? string?) (? derivation-path?))
     guile)
    (#f                                         ; the default
     (let* ((distro (resolve-interface '(gnu packages commencement)))
            (guile  (module-ref distro 'guile-final)))
       (package-derivation store guile system)))))

(define* (trivial-build store name source inputs
                        #:key
                        outputs guile system builder (modules '())
                        search-paths)
  "Run build expression BUILDER, an expression, for SYSTEM.  SOURCE is
ignored."
  (build-expression->derivation store name builder
                                #:inputs (if source
                                             `(("source" ,source) ,@inputs)
                                             inputs)
                                #:system system
                                #:outputs outputs
                                #:modules modules
                                #:guile-for-build
                                (guile-for-build store guile system)))

(define* (trivial-cross-build store name target source inputs native-inputs
                              #:key
                              outputs guile system builder (modules '())
                              search-paths native-search-paths)
  "Like `trivial-build', but in a cross-compilation context."
  (build-expression->derivation store name builder
                                #:system system
                                #:inputs
                                (let ((inputs (append native-inputs inputs)))
                                  (if source
                                      `(("source" ,source) ,@inputs)
                                      inputs))
                                #:outputs outputs
                                #:modules modules
                                #:guile-for-build
                                (guile-for-build store guile system)))

(define trivial-build-system
  (build-system (name 'trivial)
                (description
                 "Trivial build system, to run arbitrary Scheme build expressions")
                (build trivial-build)
                (cross-build trivial-cross-build)))
