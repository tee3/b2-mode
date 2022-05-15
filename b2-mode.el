;;; b2-mode.el --- A major mode for the b2 build system.  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Thomas A. Brown

;; Author: Thomas Brown <tabsoftwareconsulting@gmail.com>
;; Keywords: languages, c, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for the B2 build system.

;; @todo add support for indentation
;;   - indentation offset -> 2
;;   - { and }
;;   - after "= *$" without ;
;;   - after ": +.+$" without ;

;;; Code:

(defvar b2-mode-indent-level 2
  "The basic indentation amount in b2-mode")

(defconst b2-mode-font-lock-keywords
  (eval-when-compile
    (let ((OPERATORS '("=" "!=" "<" ">" "<=" ">="
                       "!"
                       "&&" "||"))
          (BUILTINS '(
                      "DEPENDS"
                      "INCLUDE"
                      "ALWAYS"
                      "LEAVES"
                      "NOCARE"
                      "NOTFILE"
                      "NOUPDATE"
                      "TEMPORARY"
                      "FAIL_EXPECTED"
                      "RMOLD"
                      "ISFILE"
                      "ECHO" "Echo" "echo"
                      "EXIT" "Exit" "exit"
                      "GLOB"
                      "GLOB_ARCHIVE"
                      "MATCH"
                      "BACKTRACE"
                      "UPDATE"
                      "W32_GETREG"
                      "W32_GETREGNAMES"
                      "SHELL"
                      "MD5"
                      "SPLIT_BY_CHARACTERS"
                      "PRECIOUS"
                      "PAD"
                      "FILE_OPEN"
                      "UPDATE_NOW"

                      "RULENAMES"
                      "VARNAMES"
                      "IMPORT"
                      "EXPORT"
                      "CALLER_MODULE"
                      "DELETE_MODULE"))
          (VARIABLES '("BINDRULE"

                       "LOCATE"
                       "SEARCH"

                       "HDRRULE"
                       "HDRSCAN"

                       "OS"
                       "OSPLAT"
                       "MAC"
                       "NT"
                       "OS2"
                       "UNIX"
                       "VMS"

                       "JAMDATE"
                       "JAMUNAME"
                       "JAMVERSION"
                       "JAM_VERSION"

                       "JAMSHELL"

                       "__TIMING_RULE__"
                       "__ACTION_RULE__"
                       ))
          (KEYWORDS '("actions"
                      "break"
                      "case"
                      "class"
                      "continue"
                      "else"
                      "explicit"
                      "for"
                      "if"
                      "import"
                      "in"
                      "include"
                      "local"
                      "module"
                      "on"
                      "return"
                      "rule"
                      "switch"
                      "while"))
          (ACTIONSMODIFIERS '("bind"
                              "existing"
                              "ignore"
                              "piecemeal"
                              "quietly"
                              "together"
                              "updated"))
          (RULES '("alias"
                   "constant"
                   "build-project"
                   "doxygen"
                   "exe"
                   "lib"
                   "make"
                   "path-constant"
                   "project"
                   "run"
                   "using")))
      `(("\\!" . 'font-lock-negation-char-face)
        ("^\\s-*\\_<\\(?:path-\\)?constant\\_>\\s-+\\_<\\(\\(\\w\\|\\s_\\)+\\)\\_>"
         (1 font-lock-constant-face t))
        ("^\\s-*\\_<class\\_>\\s-+\\_<\\(?1:\\(\\w\\|\\s_\\)+\\)\\_>\\(?:\\s-+:\\s-+\\_<\\(?2:\\(\\w\\|\\s_\\)+\\)\\_>\\)"
         (1 font-lock-type-face)
         (2 font-lock-type-face))
        ("<\\([^>]+\\)>"
         (1 font-lock-constant-face))
        ("$(\\_<\\(\\(\\w\\|\\s_\\)+\\)\\_>\\([^)]*\\))"
         (1 font-lock-variable-name-face))
        ("^\\s-*\\(?:\\_<local\\_>\\s-+\\)?\\_<rule\\_>\\s-+\\_<\\(\\(\\w\\|\\s_\\)+\\)\\_>"
         (1 font-lock-function-name-face))
        ;; (,(concat "^\\s-*\\_<actions\\_>\\(\\s-+" (regexp-opt ACTIONSMODIFIERS 'symbols) "\\)*\\s-+\\_<\\(\\(\\w\\|\\s_\\)+\\)\\_>\\(\\s-+" (regexp-opt ACTIONSMODIFIERS 'symbols) "\\)*")
        ;;  (1 font-lock-keyword-face)
        ;;  (2 font-lock-function-name-face)
        ;;  (3 font-lock-keyword-face))
        ("^\\s-*\\_<actions\\_>\\s-+\\_<\\(\\(\\w\\|\\s_\\)+\\)\\_>"
         (1 font-lock-function-name-face))
        (,(regexp-opt ACTIONSMODIFIERS 'symbols) . font-lock-keyword-face)
        ("^\\s-*\\(?:\\_<local\\_>\\)\\s-+\\_<\\(\\(\\w\\|\\s_\\)+\\)\\_>\\s-+[=;]"
         (1 font-lock-variable-name-face))
        (,(regexp-opt BUILTINS 'symbols) . font-lock-builtin-face)
        (,(regexp-opt VARIABLES 'symbols) . font-lock-builtin-face)
        (,(regexp-opt KEYWORDS 'symbols) . font-lock-keyword-face)
        (,(concat "^\\s-*" (regexp-opt RULES 'symbols)) . font-lock-function-name-face)))))

(defvar b2-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?. "_" table)
    (modify-syntax-entry ?- "_" table)
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?: "." table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?# "< 14" table)
    (modify-syntax-entry ?| "> 23b" table)
    (modify-syntax-entry ?\n ">" table)
    table))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.jam\\'" . b2-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("[Jj]am\\(base\\|root\\|file\\)\\'" . b2-mode))

;;;###autoload
(define-derived-mode b2-mode prog-mode "B2"
  "A simple major mode for B2 (Boost.Build) files."
  :syntax-table b2-mode-syntax-table
  (setq-local tab-width 8)
  (setq-local indent-tabs-mode nil)
  (setq-local comment-start "#")
  (setq-local comment-end "")
  (setq-local font-lock-defaults '(b2-mode-font-lock-keywords))
  (setq-local imenu-generic-expression
              '(("*Imports*" "^\\s-*import\\s-+\\([-[:word:]]+\\) ;" 1)
                ("*Variables*" "^\\s-*\\(?:local \\)?\\([-[:word:]]+\\)\\s-+[=;]" 1)
                ("*Rules*" "^\\s-*\\(?:local \\)?rule +\\([-[:word:]]+\\) +" 1)
                ("*Actions*" "^\\s-*actions\\s-+\\([-[:word:]]+\\)" 1)
                )))

(provide 'b2-mode)
;;; b2-mode.el ends here
