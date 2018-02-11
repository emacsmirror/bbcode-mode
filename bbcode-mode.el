;;; bbcode-mode.el --- Major mode for writing BBCode markup
;;
;; Copyright 2012, 2013, 2014 Eric James Michael Ritz
;;
;; Author: Eric James Michael Ritz <lobbyjones@gmail.com>
;; URL: https://github.com/ejmr/bbcode-mode
;; Version: 2.0.0
;;
;;
;;
;;; License:
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.
;;
;;
;;
;;; Commentary:
;;
;; Put this file in your Emacs Lisp path (i.e. site-lisp) and add
;; this to your `.emacs' file:
;;
;;     (require 'bbcode-mode)
;;
;; Files with the '.bbcode' extension automatically enable
;; bbcode-mode.  No other extensions are associated with the mode.

;;; Code:

(defconst bbcode-mode-version-number "2.0.1"
  "BBCode Mode version number.")

(defun bbcode-make-tag-regex (tag)
  "Make a regular expression that matches the given TAG name.

The expression contains no capture groups."
  (assert (stringp tag))
  (format "\\(\\[%s\\]\\|\\[%s=\".+\"\\]\\)\\(.\\|\n\\)*?\\[/%s\\]"
          tag tag tag))

(defconst bbcode-tags
  '(("attachment" font-lock-variable-face)
    ("b" bold)
    ("*" font-lock-keyword-face)
    ("center" font-lock-keyword-face)
    ("code" font-lock-function-name-face)
    ("color" font-lock-variable-name-face)
    ("email" link)
    ("font" font-lock-variable-name-face)
    ("gvideo" font-lock-variable-name-face)
    ("i" italic)
    ("img" link)
    ("li" font-lock-keyword-face)
    ("list" font-lock-keyword-face)
    ("ol" font-lock-keyword-face)
    ("quote" font-lock-doc-face)
    ("s" default)
    ("size" font-lock-variable-name-face)
    ("table" font-lock-keyword-face)
    ("td" font-lock-variable-name-face)
    ("th" bold)
    ("tr" font-lock-keyword-face)
    ("u" underline)
    ("ul" font-lock-keyword-face)
    ("url" link)
    ("youtube" font-lock-variable-name-face)))

(defconst bbcode-font-lock-keywords
  (mapcar (lambda (spec)
            (let ((tag (nth 0 spec)) (face (nth 1 spec)))
              (cons (bbcode-make-tag-regex tag) face)))
          bbcode-tags)
  "Regular expressions to highlight BBCode markup.")

(defun bbcode-insert-tag (prefix tag)
  "Insert a pair of TAG in the buffer at the current point.

This function places the point in the middle of the tags.  The
tag will be wrapped around the points START and END if the user
has selected a region.  If the function is called with the
universal prefix argument then the point will be placed in the
opening tag so the user can enter any attributes."
  (interactive "PMTag: ")
  (let ((opening-tag (format "[%s%s]" tag (if prefix "=" "")))
        (closing-tag (format "[/%s]" tag))
        (between-tags "")
        start end)
    (when (use-region-p)
      (setq start (region-beginning) end (region-end))
      (setq between-tags (buffer-substring start end))
      (goto-char start)
      (delete-region start end))
    (setq start (point))
    (insert (concat opening-tag between-tags closing-tag))
    (deactivate-mark)
    (cond (prefix
           (set-mark (goto-char (+ start (1- (length opening-tag))))))
          (t
           (set-mark (+ start (length opening-tag)))
           (goto-char (+ start (length opening-tag) (length between-tags)))))))

;;;###autoload
(define-derived-mode bbcode-mode text-mode "BBCode"
  "Major mode for writing BBCode markup.

\\{bbcode-mode-map}"
  ;; Setup font-lock.
  (set (make-local-variable 'font-lock-defaults)
       '(bbcode-font-lock-keywords nil t))
  (set (make-local-variable 'font-lock-multiline) t)
  (font-lock-mode 1)
  ;; The most commonly predicted use-case for this mode is writing
  ;; text that will be posted on a website forum.  Those forum
  ;; programs automatically turn newlines into <br/> tags, which is
  ;; not what we want.  But we still want automatic newlines for
  ;; paragraphs as we write.  So we disable auto-fill-mode in order to
  ;; avoid actual newlines, but enable visual-line-mode so that text
  ;; is automatically wrapped for readability.
  (auto-fill-mode 0)
  (visual-line-mode 1))

(defmacro bbcode-make-key-binding (key tag)
  "Bind the sequence KEY to insert TAG into the buffer.

KEY must be a valid argument for the macro `kbd'."
  (let ((function-name (intern (format "bbcode-insert-tag-%s" tag))))
  `(progn
     (defun ,function-name (prefix)
       ,(format "Insert the [%s] tag at point or around the current region" tag)
       (interactive "P")
       (bbcode-insert-tag prefix ,tag))
     (define-key bbcode-mode-map (kbd ,key) ',function-name))))

;; Keys that insert most tags are prefixed with 'C-c C-t'.
(bbcode-make-key-binding "C-c C-t b" "b")
(bbcode-make-key-binding "C-c C-t c" "code")
(bbcode-make-key-binding "C-c C-t d" "del")
(bbcode-make-key-binding "C-c C-t e" "email")
(bbcode-make-key-binding "C-c C-t i" "i")
(bbcode-make-key-binding "C-c C-t l" "url")
(bbcode-make-key-binding "C-c C-t m" "img")
(bbcode-make-key-binding "C-c C-t n" "center")
(bbcode-make-key-binding "C-c C-t q" "quote")
(bbcode-make-key-binding "C-c C-t s" "s")
(bbcode-make-key-binding "C-c C-t u" "u")

;; Keys related to modifying font properties begin with 'C-c C-f'.
(bbcode-make-key-binding "C-c C-f c" "color")
(bbcode-make-key-binding "C-c C-f f" "font")
(bbcode-make-key-binding "C-c C-f s" "size")

;; Keys for creating lists begin with 'C-c C-l'.
(bbcode-make-key-binding "C-c C-l i" "li")
(bbcode-make-key-binding "C-c C-l l" "list")
(bbcode-make-key-binding "C-c C-l o" "ol")
(bbcode-make-key-binding "C-c C-l u" "ul")
(bbcode-make-key-binding "C-c C-l *" "*")

;; Keys for tables begin with 'C-c C-b'
(bbcode-make-key-binding "C-c C-b d" "td")
(bbcode-make-key-binding "C-c C-b h" "th")
(bbcode-make-key-binding "C-c C-b r" "tr")
(bbcode-make-key-binding "C-c C-b t" "table")

;; Keys for special, uncommon tags begin with 'C-c C-s'.
(bbcode-make-key-binding "C-c C-s a" "attachment")
(bbcode-make-key-binding "C-c C-s g" "gvideo")
(bbcode-make-key-binding "C-c C-s m" "manual")
(bbcode-make-key-binding "C-c C-s w" "wiki")
(bbcode-make-key-binding "C-c C-s y" "youtube")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.bbcode$" . bbcode-mode))

(provide 'bbcode-mode)

;;; bbcode-mode.el ends here
