;;; tlon-babel.el --- A collection of convenience functions for the Tlön babel project. -*- lexical-binding: t -*-

;; Author: Pablo Stafforini
;; Maintainer: Pablo Stafforini
;; Version: 0.1.13
;; Homepage: https://tlon.team
;; Keywords: convenience tools


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
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

;;; Code:
(require 'org)
(require 'org-clock)
(require 'bibtex)
(require 'cl-lib)
(require 'transient)
(require 'subr-x)
(require 'ebib)

;;; Version

(defvar tlon-babel-version "0.1.13")

(defun tlon-babel-version ()
  "Return the version of the `tlon-babel' package."
  (interactive)
  (message "`tlon-babel' version %s" tlon-babel-version))

(defun tlon-babel-update ()
  "Update `tlon-babel' package."
  (interactive)
  (let* ((default-directory (file-name-concat user-emacs-directory "elpaca/repos/tlon-babel/"))
	 (builds-directory (file-name-concat user-emacs-directory "elpaca/builds/tlon-babel/"))
	 (tlon-babel-file (file-name-concat default-directory "tlon-babel.el")))
    (shell-command "git pull")
    (with-current-buffer (find-file-noselect tlon-babel-file)
      (eval-buffer))
    (dired-delete-file builds-directory 'always t)
    (message "Package updated. %s" tlon-babel-version)))

;;; Vars

;;;; files

(defvar tlon-babel-dir-babel
  (expand-file-name  "~/Library/CloudStorage/Dropbox/repos/babel/")
  "Directory where the babel project is stored.")

(defvar tlon-babel-dir-originals
  (file-name-concat tlon-babel-dir-babel "originals/")
  "Directory where originals are stored.")

(defvar tlon-babel-dir-translations
  (file-name-concat tlon-babel-dir-babel "translations/")
  "Directory where translations are stored.")

(defvar tlon-babel-dir-original-posts-dir
  (file-name-concat tlon-babel-dir-originals "posts/")
  "Directory where original posts are stored.")

(defvar tlon-babel-dir-translated-posts-dir
  (file-name-concat tlon-babel-dir-translations "posts/")
  "Directory where translated posts are stored.")

(defvar tlon-babel-dir-original-tags-dir
  (file-name-concat tlon-babel-dir-originals "tags/")
  "Directory where original tags are stored.")

(defvar tlon-babel-dir-translated-tags-dir
  (file-name-concat tlon-babel-dir-translations "tags/")
  "Directory where translated tags are stored.")

(defvar tlon-babel-dir-etc
  (file-name-concat tlon-babel-dir-babel "etc/")
  "Directory where miscellaneous files are stored.")

(defvar tlon-babel-dir-refs
  (file-name-concat tlon-babel-dir-babel "refs/")
  "Directory where BibTeX files are stored.")

(defvar tlon-babel-dir-locales
  (file-name-concat tlon-babel-dir-refs "locales/")
  "Directory where CSL locale files are stored.")

(defvar tlon-babel-dir-styles
  (file-name-concat tlon-babel-dir-refs "styles/")
  "Directory where CSL style files are stored.")

(defvar tlon-babel-file-manual
  (file-name-concat tlon-babel-dir-babel "manual.org")
  "File containing the manual.")

(defvar tlon-babel-file-readme
  (file-name-concat tlon-babel-dir-babel "readme.md")
  "File containing the readme.")

(defvar tlon-babel-file-jobs
  (file-name-concat tlon-babel-dir-babel "jobs.org")
  "File containing the glossary.")

(defvar tlon-babel-file-contacts
  (file-name-concat tlon-babel-dir-babel "contacts.json")
  "File containing the contacts.")

(defvar tlon-babel-file-glossary
  (file-name-concat tlon-babel-dir-dict "Glossary.csv")
  "File containing the glossary.")

(defvar tlon-babel-file-fluid
  (file-name-concat tlon-babel-dir-refs "fluid.bib")
  "File containing the fluid bibliography.")

(defvar tlon-babel-file-stable
  (file-name-concat tlon-babel-dir-refs "stable.bib")
  "File containing the stable bibliography.")

(defvar tlon-babel-file-contacts
  (file-name-concat tlon-babel-dir-etc "contacts.json")
  "File containing the contacts.")

(defvar tlon-babel-file-tags
  (file-name-concat tlon-babel-dir-etc "tags.txt")
  "File containing the tags.")

;;;; org ids

(defvar tlon-babel-manual-processing-id
  "60251C8E-6A6F-430A-9DB3-15158CC82EAE"
  "ID of the `processing' heading in `manual.org'.")

(defvar tlon-babel-jobs-id
  "820BEDE2-F982-466F-A391-100235D4C596"
  "ID of the `jobs' heading in the `jobs.org' file.")

;;;; misc

(defvar tlon-babel-projects
  '("bae" "largoplacismo" "utilitarismo")
  "List of Tlon-Babel projects.")

(defvar tlon-babel-label-actions
  '(("Awaiting processing" . "Process")
    ("Awaiting translation" . "Translate")
    ("Awaiting revision" . "Revise")
    ("Awaiting check" . "Check")
    ("Awaiting review" . "Review")
    ("Awaiting publication" . "Publish")
    ("Awaiting rewrite" . "Rewrite")
    ("Glossary" . "Respond")
    ("Misc" . "Misc"))
  "Alist of topic labels and corresponding actions.")

(defvar tlon-babel-label-bindings
  '(("Awaiting processing" . "p")
    ("Awaiting translation" . "t")
    ("Awaiting check" . "c")
    ("Awaiting revision" . "r")
    ("Awaiting review" . "v")
    ("Awaiting publication" . "u")
    ("Awaiting rewrite" . "w")
    ("Glossary" . "g")
    ("Misc" . "m"))
  "Alist of topic labels and corresponding key bindings.")

(defvar tlon-babel-label-assignees
  '(("Awaiting processing" . "worldsaround")
    ("Awaiting translation" . "benthamite")
    ("Awaiting revision" . "worldsaround")
    ("Awaiting check" . "worldsaround")
    ("Awaiting review" . "benthamite")
    ("Awaiting publication" . ""))
  "Alist of topic labels and corresponding assignees.")

(defvar tlon-babel-github-users
  '(("fstafforini" . "Federico Stafforini")
    ("worldsaround" . "Leonardo Picón")
    ("benthamite" . "Pablo Stafforini"))
  "Alist of GitHub usernames and corresponding full names.")

(defvar tlon-babel-system-users
  '(("Federico Stafforini" . "Federico Stafforini")
    ("cartago" . "Leonardo Picón")
    ("Pablo Stafforini" . "Pablo Stafforini"))
  "Alist of system usernames and corresponding full names.")

(defvar tlon-babel-post-correspondence nil
  "Alist of English and Spanish posts.")

(defvar tlon-babel-tag-correspondence nil
  "Alist of English and Spanish tags.")

(defvar tlon-babel-work-correspondence nil
  "Alist of original and Spanish works.")

(defvar tlon-babel-tag-slugs nil
  "List of EA Wiki slugs.")

(defvar tlon-babel-wiki-urls nil
  "List of EA Wiki URLs.")

;;;

(defun tlon-babel-forge ()
  "Launch the Forge dispatcher in the Tlon-Babel directory."
  (interactive)
  (let ((default-directory tlon-babel-dir-babel))
    (call-interactively 'forge-dispatch)))

(defun tlon-babel-orgit-capture ()
  "Capture a new org mode task for topic at point."
  (interactive)
  (let ((assignee (alist-get
		   (tlon-babel-forge-get-assignee-at-point)
		   tlon-babel-github-users nil nil 'string=))
	(label (tlon-babel-forge-get-label-at-point)))
    ;; when the topic has neither a label nor an assignee, we offer to
    ;; process it as a new job
    (if (not (or assignee label))
	(if (y-or-n-p "Process issue as a new job (this will assign the issue to you, add the label 'Awaiting processing', and create a new master TODO in your org mode file)?")
	    (progn
	      (tlon-babel-start-job t)
	      (sleep-for 4)
	      (tlon-babel-orgit-capture))
	  (user-error "Aborted"))
      ;; else we prompt for an assignee...
      (unless (string= user-full-name assignee)
	(if (y-or-n-p
	     (format "The assignee of this topic is %s. Would you like to become the assignee?" assignee))
	    (progn
	      (tlon-babel-set-assignee (tlon-babel-find-key-in-alist user-full-name tlon-babel-github-users))
	      (sleep-for 2))
	  (user-error "Aborted")))
      ;; ...or for a label
      (unless label
	(if (y-or-n-p "The topic has no label. Would you like to add one?")
	    (tlon-babel-set-label (tlon-babel-select-label))
	  (tlon-babel-set-assignee (tlon-babel-find-key-in-alist user-full-name tlon-babel-github-users))
	  (user-error "Aborted")))
      (orgit-store-link nil)
      (magit-pull-from-upstream nil)
      (if-let* ((org-link (ps/org-nth-stored-link 0))
		(refile-position (org-find-exact-headline-in-buffer
				  (cadr (nth 0 org-stored-links))
				  (find-file-noselect ps/file-tlon-bae))))
	  (let ((action (alist-get label tlon-babel-label-actions nil nil #'string=))
		(binding (upcase (alist-get label tlon-babel-label-bindings nil nil #'string=))))
	    (kill-new (format "%s %s" action org-link))
	    (org-capture nil (concat "tb" binding))
	    ;; refile under job
	    (org-refile nil nil (list nil (buffer-file-name) nil refile-position))
	    (ps/org-refile-goto-latest))
	(when (y-or-n-p "No master TODO found for this topic. Create?")
	  (tlon-babel-start-job)
	  (tlon-babel-orgit-capture))))))

(defun tlon-babel-start-job (&optional set-topic)
  "Create new job.
If SET-TOPIC is non-nil, set topic label to `Awaiting processing'
and assignee to the current user."
  (save-window-excursion
    (when set-topic
      (tlon-babel-set-initial-label-and-assignee))
    (orgit-store-link nil)
    (let ((job-name (cadr (nth 0 org-stored-links))))
      (kill-new (format "%s" job-name)))
    (org-capture nil "tbJ")))

;;; File processing

(defun tlon-babel-generate-file-path (&optional lastname title tag translation)
  "Return a file name based on user supplied information.
TITLE is the title of the work. If TAG is 'tag, use `tag' as
LASTNAME. If TRANSLATION is non-nil, use `translatons' in the
file path."
  (let* ((tag (or (eq tag 'tag)
		  (string= lastname "tag")))
	 (lastname (or lastname (if tag
				    "tag"
				  (read-string "Last name (only first author if multi-authored): "))))
	 (title (or title (tlon-babel-shorten-title (read-string "Title (in English): "))))
	 (slug-lastname (tlon-core-slugify lastname))
	 (slug-title (tlon-core-slugify title))
	 (file-name (file-name-with-extension (concat slug-lastname "--" slug-title) "md"))
	 (file-path (file-name-concat
		     tlon-babel-dir-babel
		     (if translation "translations" "originals")
		     (if tag "tags" "posts")
		     file-name)))
    file-path))

(defun tlon-babel-extract-lastname-from-author (author)
  "Try to extract a last name from AUTHOR."
  (let* ((case-fold-search nil)
	 (uncameled-author (replace-regexp-in-string "\\([A-Z]\\)" " \\1" author))
	 (lastname (car (last (split-string uncameled-author "[ _-]")))))
    lastname))

(defun tlon-babel-review-filename (filename)
  "Review FILENAME."
  (let* ((choices '((?a . "ccept") (?e . "dit") (?r . "egenerate")))
	 (keys (mapcar 'car choices))
	 (key-description (mapconcat (lambda (choice)
				       (format "[%c]%s" (car choice) (cdr choice)))
				     choices " "))
	 (prompt (format "%s %s" filename key-description))
	 (choice (read-char-choice prompt keys)))
    (pcase choice
      (?a filename)
      (?e (read-string "Job name: " filename))
      (?r (file-name-nondirectory (tlon-babel-generate-file-path))))))

(defun tlon-babel-latest-user-commit-in-file (&optional file)
  "Return latest commit by the current user in FILE.
If no FILE is provided, use the file visited by the current buffer."
  (let* ((default-directory tlon-babel-dir-babel)
	 (file (or file (buffer-file-name)))
	 (user (tlon-babel-find-key-in-alist user-full-name tlon-babel-system-users))
	 ;; get most recent commit in FILE by USER
	 (output (shell-command-to-string (format "git log --pretty=format:'%%h %%an %%s' --follow -- '%s' | grep -m 1 '%s' | awk '{print $1}'" file user)))
	 (commit (car (split-string output "\n"))))
    commit))

(defun tlon-babel-log-buffer-latest-user-commit (&optional file)
  "Show changes to FILE since the latest commit by the current user.
If no FILE is provided, use the file visited by the current buffer."
  (interactive)
  (let* ((file (or file (buffer-file-name)))
	 (commit (tlon-babel-latest-user-commit-in-file file)))
    (magit-diff-range commit nil (list file))))

(defun tlon-babel-log-buffer-latest-user-commit-ediff (&optional file)
  "Run an `ediff' session for FILE and its state when last committed by current user.
If FILE is not provided, use the file visited by the current
buffer."
  (interactive)
  (let* ((file (or file (buffer-file-name)))
	 (commit (tlon-babel-latest-user-commit-in-file file))
	 (commit-file (tlon-babel-create-file-from-commit file commit)))
    (ediff-files commit-file file)))

(defun tlon-babel-shorten-title (title)
  "Return a shortened version of TITLE."
  (string-match "\\([[:alnum:] ,'‘’“”@#$%*\\^`~&\"]*\\)" title)
  (match-string 1 title))

(defvar tlon-babel-markdown-eawiki-footnote-source
  "\\[\\^\\[\\\\\\[\\([[:digit:]]\\{1,2\\}\\)\\\\\\]\\](#.+?)\\^\\]{#.+? .footnote-reference role=\"doc-noteref\"}"
  "Regexp to match footnotes in the main body.")

(defvar tlon-babel-markdown-eawiki-footnote-source2
  "\\[\\^\\[\\\\\\[\\([[:digit:]]\\)\\\\\\]\\](#.+?)\\^\\]{#\\\\\\\\\\\\\".+?\\\\\\\\\\\\\" .\\\\\\\\\\\\\\\"footnote-reference\\\\\\\\\\\\\" role=\"\\\\\\\\\\\\\"doc-noteref\\\\\\\\\\\\\"\"}"
  "Regexp to match footnotes in the main body.")

(defvar tlon-babel-markdown-eawiki-footnote-target
  "\\([[:digit:]]\\{1,3\\}\\). +?\\[\\[^\\*\\*\\[\\\\^\\](#[[:alnum:]]\\{12,18\\})\\*\\*^\\]\\]{#[[:alnum:]]\\{10,15\\}}

    footnote-content.*?"
  "Regexp to match footnotes in the footnote section.")

(defvar tlon-markdown-eawiki-links
  "\\[\\(.+?\\)\\](\\\\%22\\(.+?\\)\\\\%22)"
  "Regexp to match links.")

(defun tlon-babel-markdown-eaf-cleanup (&optional buffer)
  "Cleanup the BUFFER visiting an EAF entry."
  (interactive)
  (when (not (eq major-mode 'markdown-mode))
    (user-error "Not in a Markdown buffer"))
  (save-excursion
    (unfill-region (point-min) (point-max))
    (goto-char (point-min))
    (while (re-search-forward "{.underline}" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward "\\[\\[\\(.*?\\)\\]\\](" nil t)
      (replace-match (format "[%s]("
			     ;; remove extra backslashes in replacement text to avoid elisp errors
			     (replace-regexp-in-string "\\\\" "" (match-string-no-properties 1)))))
    (goto-char (point-min))
    ;; remove asterisks surrounding links
    (while (re-search-forward " ??\\* ??\\[\\*\\[\\(.*?\\)\\]\\*\\](\\(.*?\\)) ??\\* ??" nil t)
      (replace-match (format " [%s](%s)" (match-string-no-properties 1) (match-string-no-properties 2))))
    (goto-char (point-min))
    ;; move double asterisks outside of link
    (while (re-search-forward "\\[\\*\\*\\[\\(.*?\\)\\]\\*\\*\\](\\(.*?\\))" nil t)
      (replace-match (format "**[%s](%s)**" (match-string-no-properties 1) (match-string-no-properties 2))))
    (goto-char (point-min))
    (while (re-search-forward "{.footnote-back-link}" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward " " nil t)
      (replace-match " "))
    (goto-char (point-min))
    (while (re-search-forward " :::" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward "{.underline}" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward tlon-babel-markdown-eawiki-footnote-source nil t)
      (replace-match (format "[^%s] " (match-string-no-properties 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-babel-markdown-eawiki-footnote-source2 nil t)
      (replace-match (format "[^%s]: " (match-string-no-properties 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-babel-markdown-eawiki-footnote-target nil t)
      (replace-match (format "[^%s]:" (match-string-no-properties 1))))
    (goto-char (point-min))
    (while (re-search-forward tlon-markdown-eawiki-links nil t)
      (replace-match (format "[%s](%s)" (match-string-no-properties 1) (match-string-no-properties 2)) nil t))
    (goto-char (point-min))
    ;; remove double asterisks surrounding headings
    (while (re-search-forward "# \\*\\*\\(.*\\)\\*\\* *?$" nil t)
      (replace-match (format "# %s" (match-string-no-properties 1))))
    (tlon-babel-non-eaf-cleanup)
    (save-buffer)))

(defun tlon-babel-non-eaf-cleanup ()
  "Cleanup the buffer visiting a non-EAF entry."
  (interactive)
  ;; TODO: Move this to a common function called by both the EAF and non-EAF commands.
  (goto-char (point-min))
  ;; unescape double quotes
  (while (re-search-forward "\\\\\"" nil t)
    (replace-match "\""))
  (goto-char (point-min))
  ;; unescape single quotes
  (while (re-search-forward "\\\\'" nil t)
    (replace-match "'"))
  (goto-char (point-min))
  ;; unescape vertical bars
  (while (re-search-forward "\\\\|" nil t)
    (replace-match "|"))
  (goto-char (point-min))  ;; remove extra line breaks
  (while (re-search-forward "\n\n\n" nil t)
    (replace-match "\n\n"))
  (goto-char (point-min)))

(defun tlon-babel-convert-to-markdown ()
  "Convert a file from EA Wiki to Markdown."
  (interactive)
  (dolist (file (directory-files "." nil "\\.html$"))
    (let ((md-file (file-name-with-extension file "md")))
      (shell-command (format "pandoc -s '%s' -t markdown -o '%s'"
			     file
			     md-file)))))

(defun tlon-babel-cleanup-markdown-multiple ()
  "Clean up html files imported from EA Wiki."
  (interactive)
  (dolist (file (directory-files "." nil "\\.md$"))
    (with-current-buffer (find-file-noselect file)
      (message "Cleaning up %s" (buffer-name))
      (tlon-babel-markdown-eaf-cleanup))))

;;; csv and txt parsing

(defun tlon-babel-parse-csv-line (line &optional separator)
  "Split CSV LINE into fields, considering quotes, using SEPARATOR."
  (let ((index 0)
	(separator (or separator ?,))
	(quote-char ?\")
	(len (length line))
	(in-quote nil)
	start
	fields)
    (while (< index len)
      (setq start index)
      (while (and (< index len)
		  (not (and (not in-quote) (char-equal (elt line index) separator))))
	(when (char-equal (elt line index) quote-char)
	  (setq in-quote (not in-quote)))
	(setq index (1+ index)))
      (let ((field (substring-no-properties line start index)))
	(when (and (> (length field) 1)
		   (char-equal (elt field 0) ?\")
		   (char-equal (elt field (1- (length field))) ?\"))
	  (setq field (substring-no-properties field 1 -1)))
	(push field fields))
      (setq index (1+ index)))
    (nreverse fields)))

(defun tlon-babel-csv-file-to-alist (file-path)
  "Convert CSV in FILE-PATH to an alist."
  (let ((file-content (with-temp-buffer
			(insert-file-contents file-path)
			(buffer-string))))
    (let* ((lines (split-string file-content "[\r\n]+" t))
	   (content lines)
	   alist)
      (dolist (row content)
	(let* ((fields (tlon-babel-parse-csv-line row))
	       (entry (cons (car fields) (cadr fields))))
	  (setq alist (push entry alist))))
      (nreverse alist))))

(defun tlon-babel-read-urls-from-file (file-path)
  "Read URLs from a plain text FILE-PATH into an Emacs Lisp list."
  (with-temp-buffer
    (insert-file-contents file-path)
    (split-string (buffer-string) "\n" t)))

(defun tlon-babel-insert-tag ()
  "Insert a TAG slug at point."
  (interactive)
  (unless (eq major-mode 'markdown-mode)
    (user-error "Not in a Markdown buffer"))
  (let* ((tag (if (markdown-inside-link-p)
		  (ps/markdown--delete-link)
		(completing-read "URL: " tlon-babel-tags)))
	 (slug (tlon-core-slugify tag))
	 (ref (concat "../tags/" slug ".md"))
	 (link (format "[%s](%s)" tag ref)))
    (if (markdown-link-url)
	(insert ref)
      (insert link))))

(defun tlon-babel-insert-cite-tag ()
  "Insert a CITE tag at point."
  (interactive)
  (unless (eq major-mode 'markdown-mode)
    (user-error "Not in a Markdown buffer"))
  (insert "<cite></cite>")
  (backward-char 7))

(defun tlon-babel-get-original-translated (bib-file)
  "Parse BIB-FILE and return an alist of original-translation key pairs."
  ;; Check if a buffer is visiting the file.
  ;; If not, open the file in a new buffer.
  (let ((translations-alist '())
	(bib-buffer (find-buffer-visiting bib-file)))
    ;; for some reason, `bibtex-map-entries' returns nil if a buffer is
    ;; already visiting BIB-FILE, so we kill it if it exists
    (when bib-buffer
      (kill-buffer bib-buffer))
    (with-current-buffer (find-file-noselect bib-file)
      (bibtex-map-entries
       (lambda (key _beg _end)
	 (if (not key) (message "Found empty key at %s" (point)))
	 (bibtex-narrow-to-entry)
	 (when-let* ((translation (bibtex-autokey-get-field "translation")))
	   (unless (string-empty-p translation)
	     (setq translations-alist (cons (cons translation key) translations-alist))))
	 (widen))))
    translations-alist))

(defun tlon-babel-convert-keys-to-files (input-alist)
  "Take INPUT-ALIST of keys and return an a list of corresponding files."
  (let ((output-alist '()))
    (dolist (cons-cell input-alist output-alist)
      (let* ((original-key (car cons-cell))
	     (translation-key (cdr cons-cell))
	     (original-file (file-name-with-extension original-key "md"))
	     (translation-file (file-name-with-extension translation-key "md")))
	(setq output-alist (cons (cons original-file translation-file) output-alist))))))

;;; correspondences

(defun tlon-babel-load-post-correspondence ()
  "Refresh alist of original-translation file pairs."
  (interactive)
  (let* ((key-alist-stable (tlon-babel-get-original-translated tlon-babel-file-stable))
	 (key-alist-fluid (tlon-babel-get-original-translated tlon-babel-file-fluid))
	 (input-alist (tlon-babel-convert-keys-to-files (append key-alist-stable key-alist-fluid))))
    (setq tlon-babel-post-correspondence input-alist)))

(defun tlon-babel-get-translation-file (original-filename)
  "Return file that translates ORIGINAL-FILENAME."
  (or (alist-get original-filename tlon-babel-post-correspondence nil nil #'equal)
      (alist-get original-filename tlon-babel-tag-correspondence nil nil #'equal)))

(defun tlon-babel-get-translation-file-robustly (original-filename &optional noerror)
  "Return file that translates ORIGINAL-FILENAME, handling potential failures.
Reload variables if necessary and signal an error if the file is
still not returned, unless NOERROR is non-nil."
  (if-let ((translation-file (tlon-babel-get-translation-file original-filename)))
      translation-file
    (tlon-babel-load-post-correspondence)
    (if-let ((translation-file (tlon-babel-get-translation-file original-filename)))
	translation-file
      (unless noerror
	(error "No translation file found for %s" original-filename)))))

(defun tlon-babel-get-original-file (translation-filename)
  "Return file that TRANSLATION-FILENAME translates."
  (cl-loop for (key . val) in (append
			       tlon-babel-post-correspondence
			       tlon-babel-tag-correspondence)
	   when (equal val translation-filename)
	   return key))

(defun tlon-babel-get-counterpart-filename (file-path)
  "Return the counterpart filename of file in FILE-PATH."
  (let ((filename (file-name-nondirectory file-path)))
    (if (or (string-match tlon-babel-dir-original-posts-dir file-path)
	    (string-match tlon-babel-dir-original-tags-dir file-path))
	(tlon-babel-get-translation-file-robustly filename)
      (tlon-babel-get-original-file filename))))

(defun tlon-babel-get-counterpart-dirname (file-path)
  "Get the counterpart directory name of file in FILE-PATH."
  (let* ((dirname (file-name-directory file-path))
	 (counterpart-dirname (if (string-match "/originals/" dirname)
				  (replace-regexp-in-string
				   "/originals/" "/translations/" dirname)
				(replace-regexp-in-string
				 "/translations/" "/originals/" dirname))))
    counterpart-dirname))

(defun tlon-babel-get-counterpart (file-path)
  "Get the counterpart file path of file in FILE-PATH."
  (let* ((counterpart-filename (tlon-babel-get-counterpart-filename file-path))
	 (counterpart-dirname (tlon-babel-get-counterpart-dirname file-path))
	 (counterpart (concat counterpart-dirname counterpart-filename)))
    counterpart))

(defun tlon-babel-open-counterpart (&optional print-message file-path)
  "Open the counterpart of file in FILE-PATH and move point to matching position.
If FILE-PATH is nil, open the counterpart of the file visited by
the current buffer.

When called interactively, PRINT-MESSAGE is
non-nil, and the function signals an error if the current buffer
is not in `markdown-mode' and FILE-PATH is nil."
  (interactive "p")
  (when (and print-message
	     (not (eq major-mode 'markdown-mode)))
    (user-error "Not in markdown-mode"))
  (let* ((counterpart (tlon-babel-get-counterpart
		       (or file-path (buffer-file-name))))
	 (paragraphs (- (tlon-babel-count-paragraphs file-path (point-min) (+ (point) 2)) 1)))
    (find-file counterpart)
    (goto-char (point-min))
    (forward-paragraph paragraphs)))

(defun tlon-babel-count-paragraphs (&optional file-path start end)
  "Return number of paragraphs between START and END in FILE-PATH.
If either START or END is nil, default to the beginning and end
of the buffer. If FILE-PATH is nil, count paragraphs in the
current buffer."
  (interactive)
  (let ((file-path (or file-path (buffer-file-name))))
    (with-temp-buffer
      (insert-file-contents file-path)
      (let ((start (or start (point-min)))
	    (end (or end (point-max))))
	(narrow-to-region start end)
	(goto-char (point-min))
	(- (buffer-size) (forward-paragraph (buffer-size)))))))

(defun tlon-babel-check-paragraph-number-match (&optional file-path)
  "Check that FILE-PATH and its counterpart have the same number of paragraphs.
If FILE-PATH is not provided, use the current buffer."
  (interactive)
  (let* ((part (or file-path (buffer-file-name)))
	 (counterpart (tlon-babel-get-counterpart part))
	 (paras-in-part (tlon-babel-count-paragraphs part))
	 (paras-in-counterpart (tlon-babel-count-paragraphs counterpart)))
    (if (= paras-in-part paras-in-counterpart)
	t
      (message "Paragraph number mismatch: \n%s has %s paragraphs\n%s has %s paragraphs"
	       (file-name-nondirectory part) paras-in-part
	       (file-name-nondirectory counterpart) paras-in-counterpart))))

(defun tlon-babel-check-paragraph-number-match-in-dir (dir &optional extension)
  "Check that files in DIR and counterparts have the same number of paragraphs.
If EXTENSION is provided, only check files with that extension.
Otherwise, default to \".md\"."
  (let* ((extension (or extension ".md"))
	 (files (directory-files dir t (concat ".*\\" extension "$"))))
    (cl-loop for file in files
	     do (tlon-babel-check-paragraph-number-match file))))

;;; EAF validation

(defvar tlon-babel-eaf-p
  "forum\\.effectivealtruism\\.org/"
  "Regular expression for validating EAF URLs.")

(defvar tlon-babel-eaf-post-id-regexp
  "\\([[:alnum:]]\\{17\\}\\)"
  "Regular expression for validating post IDs.")

(defvar tlon-babel-eaf-tag-slug-regexp
  "\\([[:alnum:]-]*\\)"
  "Regular expression for validating tag slugs.")

(defun tlon-babel-eaf-p (url)
  "Return t if URL is an EAF URL, nil otherwise."
  (not (not (string-match tlon-babel-eaf-p url))))

(defun tlon-babel-eaf-post-id-p (identifier)
  "Return t if IDENTIFIER is a post ID, nil otherwise."
  (not (not (string-match (format "^%s$" tlon-babel-eaf-post-id-regexp) identifier))))

(defun tlon-babel-eaf-tag-slug-p (identifier)
  "Return t if IDENTIFIER is a tag slug, nil otherwise."
  (not (not (string-match (format "^%s$" tlon-babel-eaf-tag-slug-regexp) identifier))))

(defun tlon-babel-eaf-get-id-or-slug-from-identifier (identifier)
  "Return the EAF post ID or tag slug from IDENTIFIER, if found.
IDENTIFIER can be an URL, a post ID or a tag slug."
  (interactive "sURL: ")
  (if (ps/string-is-url-p identifier)
      (or (tlon-babel-eaf-get-id-from-identifier identifier)
	  (tlon-babel-eaf-get-slug-from-identifier identifier))
    ;; return id or slug if identifier is an id or slug
    (pcase identifier
      ((pred tlon-babel-eaf-post-id-p) identifier)
      ((pred tlon-babel-eaf-tag-slug-p) identifier))))

(defun tlon-babel-eaf-get-id-from-identifier (identifier)
  "Return the EAF post ID from IDENTIFIER, if found."
  (when-let ((id (or (when (string-match (format "^.+?forum.effectivealtruism.org/posts/%s"
						 tlon-babel-eaf-post-id-regexp)
					 identifier)
		       (match-string-no-properties 1 identifier))
		     (when (string-match (format "^.+?forum.effectivealtruism.org/s/%s/p/%s"
						 tlon-babel-eaf-post-id-regexp tlon-babel-eaf-post-id-regexp)
					 identifier)
		       (match-string-no-properties 2 identifier)))))
    id))

(defun tlon-babel-eaf-get-slug-from-identifier (identifier)
  "Return the EAF tag slug from IDENTIFIER, if found."
  (when (string-match (format "^.+?forum.effectivealtruism.org/topics/%s"
			      tlon-babel-eaf-tag-slug-regexp)
		      identifier)
    (match-string-no-properties 1 identifier)))

(defun tlon-babel-eaf-get-object (id-or-slug)
  "Return the EAF object in ID-OR-SLUG."
  (let ((object (cond ((tlon-babel-eaf-post-id-p id-or-slug)
		       'post)
		      ((tlon-babel-eaf-tag-slug-p id-or-slug)
		       'tag)
		      (t (user-error "Not an ID or slug: %S" id-or-slug)))))
    object))

;;; Clocked heading

(defun tlon-babel-get-clock-file ()
  "Return file name in clocked heading.
Assumes file name is enclosed in backticks."
  (unless org-clock-current-task
    (user-error "No clock running"))
  (let ((clock (substring-no-properties org-clock-current-task)))
    (if (string-match "`\\(.+?\\)`" clock)
	(match-string 1 clock)
      (user-error "I wasn't able to find a file in clocked heading"))))

(defun tlon-babel-get-clock-topic ()
  "Get topic GID from `orgit-forge' link in heading at point."
  (unless org-clock-heading
    (user-error "No clock running"))
  (save-window-excursion
    (org-clock-goto)
    (org-narrow-to-subtree)
    (when (re-search-forward org-link-bracket-re)
      (let ((raw-link (org-link-unescape (match-string-no-properties 1))))
	(string-match "orgit-topic:\\(.+\\)" raw-link)
	(match-string 1 raw-link)))))

(defun tlon-babel-open-clock-topic ()
  "Open the topic from `orgit-forge' link in heading at point."
  (interactive)
  (let ((default-directory tlon-babel-dir-babel)
	(topic (tlon-babel-get-clock-topic)))
    (forge-visit-issue topic)))

(defun tlon-babel-get-clock-action ()
  "Return action in heading at point.
Assumes action is first word of clocked task."
  ;; as rough validation, we check that the clocked heading contains a file
  (tlon-babel-get-clock-file)
  (let ((action (car (split-string (substring-no-properties org-clock-current-task))))
	(actions (mapcar #'cdr tlon-babel-label-actions)))
    (if (member action actions)
	action
      (user-error "I wasn't able to find a relevant action in clocked heading"))))

(defun tlon-babel-get-clock-label ()
  "Return label associated with action in heading at point."
  (let ((label (car (rassoc (tlon-babel-get-clock-action) tlon-babel-label-actions))))
    label))

(defun tlon-babel-get-clock-next-label ()
  "Return label associated with the action after the one in heading at point."
  (tlon-babel-get-next-car (tlon-babel-get-clock-label)
			 tlon-babel-label-actions))

(defun tlon-babel-get-clock-next-assignee (label)
  "Return assignee associated with LABEL."
  (alist-get label tlon-babel-label-assignees nil nil 'string=))

(defun tlon-babel-get-action-in-label (label)
  "Return action associated with LABEL."
  (let ((action (cadr (split-string label))))
    action))

(defun tlon-babel-get-forge-file-path ()
  "Get the file path of the topic at point or in current forge buffer."
  (unless (or (derived-mode-p 'magit-status-mode)
	      (derived-mode-p 'forge-topic-mode))
    (user-error "I'm not in a forge buffer"))
  (let* ((inhibit-message t)
	 (captured (cadr (call-interactively #'orgit-store-link))))
    (setq org-stored-links (cdr org-stored-links))
    (if (string-match "`\\(.+?\\)`" captured)
	(tlon-babel-set-original-path (match-string 1 captured))
      (user-error "I wasn't able to find a file at point or in the forge buffer"))))

(defun tlon-babel-open-forge-file ()
  "Open the file of the topic at point or in the current forge buffer."
  (interactive)
  (find-file (tlon-babel-get-forge-file-path)))

(defun tlon-babel-open-forge-counterpart ()
  "Open the file counterpart of the topic at point or in the current forge buffer."
  (interactive)
  (tlon-babel-open-counterpart (tlon-babel-get-forge-file-path)))

(defun tlon-babel-copy-buffer (&optional file deepl)
  "Copy the contents of FILE to the kill ring.
Defaults to the current buffer if no FILE is specified. If DEEPL
is non-nil, open DeepL."
  (let ((file (or file (buffer-file-name))))
    (with-current-buffer (find-file-noselect file)
      (copy-region-as-kill (point-min) (point-max)))
    (message "Copied the contents of `%s' to kill ring" (file-name-nondirectory file)))
  (when deepl
    (shell-command "open '/Applications/DeepL.app/Contents/MacOS/DeepL'")))

(defun tlon-babel-copy-region (beg end)
  "Copy the contents between BEG and END to the kill ring."
  (save-excursion
    (save-restriction
      (narrow-to-region beg end)
      (copy-region-as-kill (point-min) (point-max))))
  (message "Copied the contents of the region to kill ring"))

(defun tlon-babel-copy-dwim ()
  "Copy the contents of the region or buffer to the kill ring."
  (interactive)
  (if (region-active-p)
      (tlon-babel-copy-region (region-beginning) (region-end))
    (tlon-babel-copy-buffer)))

(defun tlon-babel-set-original-path (filename)
  "Return full path of FILENAME."
  (let* ((type (if (string-match "[[:digit:]]" filename) "posts/" "tags/"))
	 (dir (file-name-concat tlon-babel-dir-originals type))
	 (file-path (file-name-concat dir filename)))
    file-path))

(defun tlon-babel-open-clock-file ()
  "Open file of clocked task."
  (interactive)
  (let ((file-path (tlon-babel-set-original-path (tlon-babel-get-clock-file))))
    (find-file file-path)))

(defun tlon-babel-set-paths ()
  "Return paths for original and translation files from ORIGINAL-FILE."
  (let* ((original-file (tlon-babel-get-clock-file))
	 (original-path (tlon-babel-set-original-path original-file))
	 (translation-file (tlon-babel-get-translation-file-robustly original-file))
	 (dir (tlon-babel-post-or-tag original-file))
	 (translation-path (file-name-concat tlon-babel-dir-translations dir translation-file)))
    (cl-values original-path translation-path original-file translation-file)))

(defun tlon-babel-post-or-tag (file)
  "Return `posts' or `tags' depending on FILE."
  (if (string-match "[[:digit:]]" file)
      "posts"
    "tags"))

(defun tlon-babel-set-windows (original-path translation-path)
  "Open ORIGINAL-PATH and TRANSLATION-PATH in windows 1 and 2."
  (ps/window-split-if-unsplit)
  (winum-select-window-1)
  (find-file original-path)
  (winum-select-window-2)
  (find-file translation-path))

;;; Main functions

(defun tlon-babel-magit-status ()
  "Show the status of the Tlon-Babel repository in a buffer."
  (interactive)
  (magit-status tlon-babel-dir-babel))

(defun tlon-babel-magit-get-filename ()
  "Get filename of file to commit."
  (save-window-excursion
    (let (found)
      (catch 'done
	(mapc (lambda (x)
		(when (with-current-buffer x (eq major-mode 'magit-diff-mode))
		  (switch-to-buffer x)
		  (setq found t)
		  (throw 'done nil)))
	      (buffer-list))
	(unless found
	  (user-error "Magit buffer not found"))))
    (goto-char (point-min))
    (let ((regex "modified.*/\\(.*\\.*\\)"))
      (when (eq (count-matches regex) 1)
	(save-excursion
	  (re-search-forward regex nil t)
	  (match-string-no-properties 1))))))

(defun tlon-babel-create-job ()
  "Create a new job for IDENTIFIER based on Ebib entry at point.
Creating a new job means (1) importing a document and (2)
creating a record for it. A record is (a) an issue in GitHub
and (b) a heading in `jobs.org'.

IDENTIFIER can be a URL or a PDF file path.

Note: this command cannot be used to create new tag jobs, because
 we don't add tags to Ebib. To create a new tag job, use
 `tlon-babel-create-tag-job'."
  (interactive)
  (tlon-babel-create-translation-entry)
  (tlon-babel-import-document)
  (tlon-babel-create-record-for-job))


(defun tlon-babel--create-entry-from-current (fields)
  "Create a BibTeX entry based on the current one with FIELDS."
  (unless (eq major-mode 'ebib-entry-mode)
    (user-error "This command must be run in Ebib"))
  (ps/ebib-valid-key-p)
  (let* ((key (ebib--get-key-at-point))
	 (file (file-name-with-extension key "md"))
	 (db ebib--cur-db)
	 (new-db-num (ps/ebib-get-db-number tlon-babel-file-fluid)))
    (ebib-switch-to-database-nth new-db-num)
    (ebib-add-entry)
    (let ((new-key (ebib--get-key-at-point))
	  (new-db ebib--cur-db))
      (dolist (field fields)
	(ebib-set-field-value (car field) (cdr field) new-key new-db)))
    (ebib--update-entry-buffer)
    (ebib-generate-autokey)
    (set-buffer-modified-p nil)
    (ebib--set-modified t db t (seq-filter (lambda (dependent)
					     (ebib-db-has-key key dependent))
					   (ebib--list-dependents db)))))

(defun tlon-babel-create-translation-entry (&optional title)
  "Create a BibTeX entry for the translation of the current entry.
Prompt the user for a title, unless TITLE is non-nil."
  (interactive)
  (let* ((key (ebib--get-key-at-point))
	 (file (file-name-with-extension key "md"))
	 (fields `(("author" . ,(ps/ebib-get-field-value "author"))
		   ("title" . ,(or title (read-string "Translated title: ")))
		   ("date" . "2023")
		   ("journaltitle" . "Biblioteca Altruismo Eficaz")
		   ("translator" . "Tlön")
		   ("translation" . ,key)
		   ("langid" . "spanish")
		   ;; TODO: prompt user to select from a list of keywords and add them to the entry
		   )))
    (when (tlon-babel-get-translation-file-robustly file 'noerror)
      (user-error "There is already a translation for this entry"))
    (tlon-babel--create-entry-from-current fields)))

(defun tlon-babel-create-section-entry (&optional title)
  "Create a BibTeX entry for the section of the current entry.
Prompt the user for a title, unless TITLE is non-nil."
  (interactive)
  (let* ((fields `(("title" . ,(or title (read-string "Section title: ")))
		   ("eventtitle" . ,(ps/ebib-get-field-value "title"))
		   ("url" . ,(read-string "URL: " (ps/ebib-get-field-value "url")))
		   ("crossref" . ,(ebib--get-key-at-point))
		   ("author" . ,(ps/ebib-get-field-value "author"))
		   ("date" . ,(ps/ebib-get-field-value "")))))
    (tlon-babel--create-entry-from-current fields)))

(defun tlon-babel-import-document (&optional identifier target)
  "Import a document with IDENTIFIER to TARGET.
IDENTIFIER can be a URL or a PDF file path.
To import a tag, use `tlon-babel-import-tag'."
  (interactive)
  (unless (eq major-mode 'ebib-entry-mode)
    (user-error "You must be in an Ebib buffer"))
  (if-let* ((key (ebib--get-key-at-point))
	    (value (or (ps/ebib-get-field-value "url")
		       (ps/ebib-get-field-value "file")))
	    (identifier (or identifier (replace-regexp-in-string "\n\\s-*" "" value)))
	    (target (or target (file-name-concat tlon-babel-dir-original-posts-dir
						 (file-name-with-extension key "md")))))
      (if (ps/string-is-url-p identifier)
	  (tlon-babel-import-html identifier target)
	(tlon-babel-import-pdf (expand-file-name identifier) target))
    (user-error "Document was not imported because no URL or file found in Ebib entry")))

(defun tlon-babel-import-tag (url-or-slug)
  "Import an EA Forum tag with URL-OR-SLUG."
  (interactive "sTag url or slug (if you are not importing a tag, please re-run `tlon-babel-import-document' from an Ebib buffer): ")
  (let* ((slug (tlon-babel-eaf-get-id-or-slug-from-identifier url-or-slug))
	 (target (file-name-concat tlon-babel-dir-original-tags-dir
				   (file-name-with-extension slug ".md"))))
    (tlon-babel-import-html-eaf slug target)))

(defun tlon-babel-import-html (url target)
  "Import the HTML in URL to TARGET and convert it to Markdown."
  (if-let ((id-or-slug (tlon-babel-eaf-get-id-or-slug-from-identifier url)))
      (tlon-babel-import-html-eaf id-or-slug target)
    (tlon-babel-html-to-markdown url target)))

(defun tlon-babel-import-html-eaf (id-or-slug target)
  "Import the HTML of EAF entity with ID-OR-SLUG to TARGET and convert it to MD."
  (let* ((response (tlon-babel-eaf-request id-or-slug))
	 (object (tlon-babel-eaf-get-object id-or-slug))
	 (html (pcase object
		 ('post (tlon-babel-eaf-get-post-html response))
		 ('tag (tlon-babel-eaf-get-tag-html response))))
	 (html-file (tlon-babel-save-html-to-file html)))
    (tlon-babel-html-to-markdown html-file target)
    (with-current-buffer (find-file-noselect target)
      (tlon-babel-markdown-eaf-cleanup))
    (find-file target)))

(defun tlon-babel-html-to-markdown (source target)
  "Convert HTML text in SOURCE to Markdown text in TARGET.
SOURCE can be a URL or, like TARGET, a file path."
  (let ((pandoc (if (ps/string-is-url-p source)
		    tlon-babel-pandoc-convert-from-url
		  tlon-babel-pandoc-convert-from-file)))
    (shell-command
     (format pandoc source target))
    (find-file target)))

(defvar tlon-babel-pdf2md
  (file-name-concat ps/dir-source "pdf2md/lib/pdf2md-cli.js")
  "Path to `pdf2md-cli.js' executable.")

(defvar tlon-babel-pdftotext
  (file-name-concat ps/dir-source "xpdf-tools-mac-4.04/bin64/pdftotext")
  "Path to `pdftotext' executable.")

(defun tlon-babel-import-pdf (path target)
  "Import the PDF in PATH to TARGET and convert it to Markdown.
This command requires the user to supply values for the header
and footer elements to be excluded from the conversion, which are
different for each PDF. To determine these values, measure the
distance between the top/bottom of the PDF (which will open in
the other window) and note the number of pixels until the end of
the header/footer. (You can measure the number of pixels between
two points by taking a screenshot: note the numbers next to the
pointer.) Then enter these values when prompted."
  (find-file-other-window path)
  (let ((header (read-string "Header: "))
	(footer (read-string "Footer: ")))
    (shell-command (format "'%s' -margint %s -marginb %s '%s' '%s'"
			   tlon-babel-pdftotext header footer path target))
    (find-file target)))

;; This function is not currently used because we now use pdftotext, rather
;; than pdf2md, to convert PDFs to Markdown.
(defun tlon-babel-import-pdf-to-markdown (path target)
  "Import the PDF in PATH to TARGET and convert it to Markdown."
  (let* ((path (or path (read-file-name "PDF: ")))
	 (expanded-path (expand-file-name path))
	 (temp-source-dir (make-temp-file "pdf-source" t))
	 (temp-source-file (file-name-concat temp-source-dir "source.pdf"))
	 (temp-target-dir (make-temp-file "pdf-target" t))
	 (temp-target-file (file-name-concat temp-target-dir "source.md")))
    (unwind-protect
	(progn
	  (copy-file expanded-path temp-source-file)
	  (shell-command (format "node %s --inputFolderPath='%s' --outputFolderPath='%s'"
				 tlon-babel-pdf2md temp-source-dir temp-target-dir))
	  (copy-file temp-target-file target)
	  (delete-directory temp-source-dir t)
	  (delete-directory temp-target-dir t)))))

(defun tlon-babel-create-record-for-job (&optional filename)
  "Create an record based on FILENAME.
Creates a new record in the Tlon-Babel Github repository (with the
format `Job: FILENAME`) and a new heading in the file `jobs.org'."
  (interactive)
  (unless (eq major-mode 'ebib-entry-mode)
    (user-error "You must be in an Ebib buffer"))
  (tlon-babel-check-ebib-entry-is-original)
  (let* ((key (if filename
		  (file-name-base filename)
		(ps/ebib-valid-key-p)
		(ebib--get-key-at-point)))
	 (filename (or filename
		       (file-name-with-extension key "md"))))
    (tlon-babel-create-issue-for-job filename)
    (tlon-babel-create-heading-for-job key 'commit)))

(defun tlon-babel-create-issue-for-job (filename)
  "Create an issue based on FILENAME in the Tlon-Babel GitHub repository."
  (let ((default-directory tlon-babel-dir-babel))
    (call-interactively #'forge-create-issue)
    (insert (format "Job: `%s`" filename))
    (call-interactively #'forge-post-submit)
    (sleep-for 2)
    (forge-pull)
    (magit-status tlon-babel-dir-babel)
    ;; needs to be done twice for some reason; FIXME
    (forge-pull)))

(defun tlon-babel-create-heading-for-job (&optional key commit)
  "Create a heading based on KEY in `jobs.org'.
If COMMIT is non-nil, commit the change."
  (interactive)
  (let* ((key (or key (ebib--get-key-at-point)))
	 (heading (format "[cite:@%s]" key))
	 (project (completing-read-multiple
		   "Project (multiple comma-separated selections allowed): "
		   tlon-babel-projects)))
    (with-current-buffer (or (find-buffer-visiting tlon-babel-file-jobs)
			     (find-file-noselect tlon-babel-file-jobs))
      (widen)
      (goto-char (point-min))
      (unless (search-forward heading nil t)
	(goto-char (point-min))
	(re-search-forward tlon-babel-jobs-id nil t)
	(while (and (not (org-at-heading-p)) (not (eobp)))
	  (forward-line))
	(org-insert-heading)
	(insert heading)
	(org-todo 'todo)
	(org-set-tags project)
	(org-sort-entries nil ?o) ; sort entries by t(o)do order
	(save-buffer)))
    (when commit
      (tlon-babel-commit-and-push "Update" tlon-babel-file-jobs))))

(defun tlon-babel-mark-clocked-task-done ()
  "Mark the currently clocked task as DONE."
  (save-window-excursion
    (org-clock-goto)
    (org-todo "DONE")
    (save-buffer)))

(defun tlon-babel-mark-clocked-task-parent-done ()
  "Mark the parent task of currently clocked task as DONE."
  (save-window-excursion
    (org-clock-goto)
    (widen)
    (org-up-heading-safe)
    (org-todo "DONE")
    (save-buffer)))

(defun tlon-babel-get-key-in-heading ()
  "Get the key of the currently clocked task."
  (unless (org-at-heading-p)
    (user-error "Not in an org-mode heading"))
  (let ((heading (substring-no-properties (org-get-heading t t t t))))
    (if (string-match "\\[cite:@\\(.+?\\)\\]\\|Job: `\\(.+?\\)\\.md`" heading)
	(or (match-string 1 heading)
	    (match-string 2 heading))
      (user-error "I wasn't able to find a key in clocked heading"))))

(defun tlon-babel-mark-clocked-heading-done (&optional commit)
  "Mark the heading of the currently clocked task as DONE.
If COMMIT is non-nil, commit and push the changes."
  (let ((key (file-name-sans-extension (tlon-babel-get-clock-file))))
    (with-current-buffer (or (find-buffer-visiting tlon-babel-file-jobs)
			     (find-file-noselect tlon-babel-file-jobs))
      (tlon-babel-goto-heading key)
      (org-todo "DONE")
      (org-sort-entries nil ?o) ; sort entries by t(o)do order
      (save-buffer))
    (when commit
      (tlon-babel-commit-and-push "Update " tlon-babel-file-jobs))))

(defun tlon-babel-goto-heading (key)
  "Move point to the heading in `jobs.org' with KEY."
  (with-current-buffer (find-file-noselect (file-name-concat tlon-babel-dir-babel "etc/jobs.org"))
    (org-element-map (org-element-parse-buffer) 'headline
      (lambda (headline)
	(when (string= (org-element-property :raw-value headline) (format "[cite:@%s]" key))
	  (goto-char (org-element-property :begin headline)))))))

;;; initialize & finalize functions

(defun tlon-babel-dwim ()
  "Initialize or finalize process based on clocked task."
  (interactive)
  (when (eq major-mode 'org-mode)
    (org-clock-in))
  (save-buffer)
  (let* ((action (tlon-babel-get-action-in-label (tlon-babel-get-clock-label)))
	 (stage (pcase major-mode
		  ('org-mode 'initialize)
		  ('markdown-mode 'finalize)
		  (_ (user-error "I don't know what to do in `%s`" major-mode))))
	 (fun (intern (format "tlon-babel-%s" stage)))
	 (arg (intern (format "tlon-babel-%s-%s" stage action))))
    (if (eq stage 'initialize)
	(funcall fun arg)
      (funcall fun))))

(defun tlon-babel-initialize (fun)
  "Initialize process associated with FUN.
Runs all the general initialization functions, followed by the
specific function for the process that is being initialized."
  (tlon-babel-check-label-and-assignee)
  (tlon-babel-check-branch "main")
  (let ((default-directory tlon-babel-dir-babel))
    (magit-pull-from-upstream nil)
    (sleep-for 2)
    (cl-multiple-value-bind
	(original-path translation-path original-file translation-file)
	(tlon-babel-set-paths)
      (let ((topic (tlon-babel-get-clock-topic)))
	(tlon-babel-set-windows original-path translation-path)
	(write-file translation-path)
	(winum-select-window-2)
	(orgit-topic-open topic)
	(tlon-babel-copy-buffer original-path)
	(funcall fun)))))

(defun tlon-babel-finalize ()
  "Finalize current stage of translation process."
  (save-buffer)
  (tlon-babel-check-branch "main")
  (tlon-babel-check-label-and-assignee)
  (tlon-babel-check-file)
  (cl-multiple-value-bind
      (original-path translation-path original-file translation-file)
      (tlon-babel-set-paths)
    (let* ((current-action (tlon-babel-get-clock-action))
	   (next-label (tlon-babel-get-clock-next-label))
	   (next-assignee (tlon-babel-get-clock-next-assignee next-label)))
      (save-buffer)
      (if (string= current-action "Process")
	  (write-file original-path)
	(write-file translation-path))
      (when (string= current-action "Process")
	(tlon-babel-commit-and-push current-action original-path))
      (tlon-babel-commit-and-push current-action translation-path)
      (tlon-babel-act-on-topic original-file next-label next-assignee
			     (when (string= current-action "Review")
			       'close))
      (tlon-babel-mark-clocked-task-done)
      (message "Marked as DONE. Set label to `%s' and assignee to `%s'"
	       next-label next-assignee)
      (when (string= current-action "Review")
	(tlon-babel-mark-clocked-task-parent-done)
	(tlon-babel-mark-clocked-heading-done 'commit)))))

(defun tlon-babel-initialize-processing ()
  "Initialize processing."
  (cl-multiple-value-bind
      (original-path)
      (tlon-babel-set-paths)
    (tlon-babel-set-windows original-path tlon-babel-file-manual)
    (org-id-goto tlon-babel-manual-processing-id)
    (org-narrow-to-subtree)
    (ps/org-show-subtree-hide-drawers)
    (winum-select-window-2)
    (let ((topic (tlon-babel-get-clock-topic)))
      (orgit-topic-open topic))))

(defun tlon-babel-initialize-translation ()
  "Initialize translation.")

(defun tlon-babel-initialize-revision ()
  "Initialize stylistic revision.")

(defun tlon-babel-initialize-check ()
  "Initialize accuracy check."
  ;; we move the buffer displaying the issue to the right, to uncover
  ;; the original file
  (ps/window-buffer-move-dwim)
  (ps/switch-to-last-window)
  (markdown-preview)
  (read-aloud-buf))

(defun tlon-babel-initialize-review ()
  "Initialize review."
  (cl-multiple-value-bind
      (original-path translation-path original-file translation-file)
      (tlon-babel-set-paths)
    (tlon-babel-log-buffer-latest-user-commit-ediff translation-path)))

;;; TTS

(defun tlon-babel-read-target-buffer ()
  "Return the buffer that `read-aloud' should read."
  (let ((buffer-list (cl-remove-if-not
		      (lambda (buffer)
			(string-match-p (regexp-quote "**markdown-output* # eww*") (buffer-name buffer)))
		      (buffer-list)))
	buffer)
    (cond ((= (length buffer-list) 1)
	   (setq buffer (car buffer-list)))
	  ((< (length buffer-list) 1)
	   (user-error "No buffer found"))
	  ((> (length buffer-list) 1)
	   (user-error "More than one buffer found")))
    buffer))

(defvar tlon-babel-read-aloud-next-action
  'read-aloud-buf)

(defun tlon-babel-read-target-start-or-stop ()
  "Start or stop reading the target buffer."
  (interactive)
  (let ((buffer (tlon-babel-read-target-buffer))
	(current-buffer (current-buffer)))
    (pop-to-buffer buffer)
    (when read-aloud--c-bufpos
      (goto-char read-aloud--c-bufpos))
    (read-aloud-buf)
    ;; we move point to the previous chunk, using the chunk divider
    ;; defined in `read-aloud--grab-text'
    (re-search-backward "[,.:!;]\\|\\(-\\|\n\\|\r\n\\)\\{2,\\}" nil t)
    (pop-to-buffer current-buffer)))

(defun tlon-babel--read-backward-or-forward (direction)
  "Move in DIRECTION in the target buffer."
  (interactive)
  (let ((buffer (tlon-babel-read-target-buffer))
	(current-buffer (current-buffer))
	(fun (if (eq direction 'backward)
		 're-search-backward
	       're-search-forward)))
    (when read-aloud--c-bufpos
      (read-aloud-buf))
    (pop-to-buffer buffer)
    (funcall fun "[,.:!;]\\|\\(-\\|\n\\|\r\n\\)\\{2,\\}" nil t 1)
    (pop-to-buffer current-buffer)))

(defun tlon-babel-read-backward ()
  "Move backward in the target buffer."
  (interactive)
  (tlon-babel--read-backward-or-forward 'backward))

(defun tlon-babel-read-forward ()
  "Move forward in the target buffer."
  (interactive)
  (tlon-babel--read-backward-or-forward 'forward))

;;; Sentence highlighting

;; TODO: (1) highlight sentence in target window; (2) diagnose why first
;; two characters in a sentence are matched to the previous sentence;
;; (3) diagnose performance issues, or else disable `post-command-hook'
;; and rely on other triggers; (4) use `lin-blue' as face for highlighting))))
(defvar tlon-babel-sentence-highlight-offset 0
  "Number of sentences to offset the sentence count in the source window.")

(defun tlon-babel-sentence-highlight-offset-set ()
  "Set the sentence offset.
This command should be run from the source window."
  (interactive)
  (let ((source-window-sentences (count-sentences (point-min) (point)))
	target-window-sentences)
    (with-selected-window (cadr (window-list))
      (setq target-window-sentences (count-sentences (point-min) (point))))
    (setq tlon-babel-sentence-highlight-offset
	  (- source-window-sentences target-window-sentences))))

(defun tlon-babel-remove-source-overlays ()
  "Remove all existing overlays in the source window."
  (remove-overlays (point-min) (point-max)))

(defun tlon-babel-current-window-line ()
  "Get the current line number in the window."
  (save-excursion
    (let ((end (point)))
      (move-to-window-line 0)
      (count-screen-lines (point) end))))

(defun tlon-babel-highlight-corresponding-sentence ()
  "Highlight the corresponding sentence in the source text and unhighlight others."
  (interactive)
  (let* ((source-window (cadr (window-list)))
	 (target-window (car (window-list)))
	 (target-sentence-index)
	 (overlay (make-overlay (point) (point)))
	 (target-window-line (tlon-babel-current-window-line)))
    (with-selected-window target-window
      (save-excursion
	(backward-sentence)
	(setq target-sentence-index (count-sentences (point-min) (point)))))
    (with-selected-window source-window
      (tlon-babel-remove-source-overlays)
      (let ((beg)
	    (end))
	;; +1 because otherwise `count-sentences' throws an error
	(goto-char (1+ (point-min)))
	(while (< (count-sentences (point-min) (point))
		  (+ target-sentence-index tlon-babel-sentence-highlight-offset))
	  (forward-sentence))
	(setq beg (point))
	(forward-sentence)
	(setq end (point))
	(move-overlay overlay beg end (current-buffer))
	(overlay-put overlay 'face 'highlight)
	(backward-sentence)
	(recenter target-window-line)))))

(defvar tlon-babel-enable-automatic-highlighting nil
  "Whether to automatically highlight corresponding sentences.")

(defun tlon-babel-toggle-automatic-highlighting ()
  "Toggle automatic highlighting of corresponding sentences."
  (interactive)
  (if tlon-babel-enable-automatic-highlighting
      (progn
	(remove-hook 'post-command-hook 'tlon-babel-highlight-corresponding-sentence t)
	(setq tlon-babel-enable-automatic-highlighting nil)
	(with-selected-window (cadr (window-list))
	  (tlon-babel-remove-source-overlays))
	(message "Automatic sentence highlighting disabled."))
    (add-hook 'post-command-hook 'tlon-babel-highlight-corresponding-sentence nil t)
    (setq tlon-babel-enable-automatic-highlighting t)
    (message "Automatic sentence highlighting enabled.")))

;;; Checking

(defun tlon-babel-check-branch (branch)
  "Throw an error unless current buffer is in Tlon-Babel branch BRANCH."
  (let ((default-directory tlon-babel-dir-babel))
    (unless (string= (magit-get-current-branch) branch)
      (user-error "Please switch to the branch `%s' before proceeding" branch))
    t))

(defun tlon-babel-check-file ()
  "Throw an error unless current file matches file in clock."
  (unless (or (string= (file-name-nondirectory (buffer-file-name))
		       (tlon-babel-get-clock-file))
	      (string= (file-name-nondirectory (buffer-file-name))
		       (tlon-babel-get-translation-file (tlon-babel-get-clock-file))))
    (user-error "Current file does not match file in clock"))
  t)

(defun tlon-babel-check-label-and-assignee ()
  "Check that clocked action matches topic label and assignee matches user."
  (save-window-excursion
    (let* ((filename (tlon-babel-get-clock-file))
	   (topic (format "Job: `%s`" filename))
	   (clocked-label (tlon-babel-get-clock-label)))
      (tlon-babel-magit-status)
      (magit-section-show-level-3-all)
      (goto-char (point-min))
      (if (search-forward topic nil t)
	  (let ((label (tlon-babel-forge-get-label-at-point))
		(assignee (alist-get
			   (tlon-babel-forge-get-assignee-at-point)
			   tlon-babel-github-users nil nil 'string=)))
	    (unless (string= clocked-label label)
	      (user-error "The `org-mode' TODO says the label is `%s', but the actual topic label is `%s'"
			  clocked-label label))
	    (unless (string= user-full-name assignee)
	      (user-error "The `org-mode' TODO says the assignee is `%s', but the actual topic assignee is `%s'"
			  user-full-name assignee))
	    t)
	(user-error "No topic found for %s" filename)))))

(defun tlon-babel-check-staged-or-unstaged (file-path)
  "Check if there are staged or unstaged changes in repo involving FILE-PATH."
  (catch 'found
    (dolist (flag '("staged" ""))
      (let ((git-command (format "git diff --%s --name-only %s" flag file-path)))
	(when (not (string-empty-p (shell-command-to-string git-command)))
	  (throw 'found t))))))

(defun tlon-babel-check-staged-or-unstaged-other-than (file-path)
  "Check if there are staged or unstaged changes in repo not involving FILE-PATH."
  (let* ((default-directory tlon-babel-dir-babel)
	 (all-changes (magit-git-str "diff" "HEAD" "--" "."))
	 (filtered-changes (magit-git-str "diff" "HEAD" "--" file-path)))
    (unless (string= all-changes filtered-changes)
      (user-error "There are staged or unstaged changes in repo. Please commit or stash them before continuing"))))

(defun tlon-babel-check-ebib-entry-is-original ()
  "Check that the current Ebib entry is an original."
  (unless (eq major-mode 'ebib-entry-mode)
    (user-error "You must be in an Ebib buffer"))
  (let ((key (ebib--get-key-at-point))
	(langid (ps/ebib-get-field-value "langid")))
    (unless (member langid '("english" "american" "british" "UKenglish" "USenglish"))
      (user-error "This entry does not appear to be an original (make sure its `langid' field is present)"))))

(defun tlon-babel-act-on-topic (original-file label &optional assignee action)
  "Apply LABEL and ASSIGNEE to topic associated with ORIGINAL-FILE.
If ACTION is `convert', convert the existing issue into a pull
request. If ACTION is `close', close issue."
  (let ((topic (format "Job: `%s`" original-file))
	(default-directory tlon-babel-dir-babel))
    (tlon-babel-magit-status)
    (magit-section-show-level-3-all)
    (goto-char (point-min))
    (if (search-forward topic nil t)
	(progn
	  (tlon-babel-set-parameters topic label)
	  (when assignee (tlon-babel-set-parameters topic assignee))
	  (search-forward topic nil t)
	  (pcase action
	    (`convert (call-interactively 'forge-create-pullreq-from-issue))
	    (`close (call-interactively 'forge-edit-topic-state))))
      (user-error "Could not find topic `%s' in Magit buffer" topic))))

(defun tlon-babel-set-parameters (topic &optional label-or-assignee)
  "Docstring."
  (let ((assignee-p (member label-or-assignee (mapcar 'car tlon-babel-github-users))))
    (search-forward topic nil t)
    (if assignee-p
	(tlon-babel-set-assignee label-or-assignee)
      (tlon-babel-set-label label-or-assignee))
    (goto-char (point-min))))

;;; Search

(defun tlon-babel-search-topics (search-string)
  "Search for SEARCH-STRING in Tlon-Babel GitHub issues and pull requests."
  (interactive "sSearch string: ")
  (let ((default-directory tlon-babel-dir-babel))
    (forge-search search-string)))

(defun tlon-babel-search-commits (search-string)
  "Search for SEARCH-STRING in Tlon-Babel commit history."
  (interactive "sSearch string: ")
  (let ((default-directory tlon-babel-dir-babel))
    (magit-log-all (list "--grep" search-string))))

(defun tlon-babel-search-files (search-string)
  "Search for SEARCH-STRING in Tlon-Babel files."
  (interactive "sSearch string: ")
  (let ((default-directory tlon-babel-dir-babel))
    (consult-ripgrep tlon-babel-dir-babel search-string)))

(defun tlon-babel-search-multi (search-string)
  "Search for SEARCH-STRING in Tlon-Babel files, commit history, and GitHub issues."
  (interactive "sSearch string: ")
  (let ((win1 (selected-window)))
    (ps/window-split-if-unsplit)
    (tlon-babel-search-topics search-string)
    (split-window-below)
    (tlon-babel-search-commits search-string)
    (select-window win1)
    (tlon-babel-search-files search-string)))

(defun tlon-babel-commit-and-push (prefix file)
  "Commit and push changes in Tlon-Babel repo, with message 'PREFIX FILE'."
  (let ((default-directory tlon-babel-dir-babel))
    (tlon-babel-check-staged-or-unstaged-other-than file)
    (when (string= (magit-get-current-branch) "main")
      (magit-pull-from-upstream nil)
      (sleep-for 2))
    (magit-stage-file file)
    ;; we check for staged or unstaged changes to FILE because
    ;; `magit-commit-create' interrupts the process if there aren't
    (when (tlon-babel-check-staged-or-unstaged file)
      (magit-commit-create (list "-m" (format "%s %s" prefix (file-name-nondirectory file)))))
    (call-interactively #'magit-push-current-to-pushremote)))

;;; Change topic properties

(defun tlon-babel-select-label ()
  "Prompt the user to select a LABEL."
  (let ((label (completing-read "What should be the label? "
				tlon-babel-label-actions)))
    label))

(defun tlon-babel-set-label (label)
  "Apply LABEL to topic at point.
Note that this only works for topics listed in the main buffer."
  (interactive
   (list (tlon-babel-select-label)))
  (let* ((topic (forge-get-topic (forge-topic-at-point)))
	 (repo  (forge-get-repository topic))
	 (crm-separator ","))
    (forge--set-topic-labels
     repo topic (list label))))

(defun tlon-babel-select-assignee ()
  "Prompt the user to select an ASSIGNEE.
The prompt defaults to the current user."
  (let ((assignee (completing-read "Who should be the assignee? "
				   tlon-babel-github-users nil nil
				   (tlon-babel-find-key-in-alist
				    user-full-name
				    tlon-babel-github-users))))
    assignee))

(defun tlon-babel-set-assignee (assignee)
  "Make ASSIGNEE the assignee of topic at point."
  (interactive
   (list (tlon-babel-select-assignee)))
  (let* ((topic (forge-get-topic (forge-topic-at-point)))
	 (repo  (forge-get-repository topic))
	 (value (closql--iref topic 'assignees))
	 (choices (mapcar #'cadr (oref repo assignees)))
	 (crm-separator ","))
    (forge--set-topic-assignees
     repo topic
     (list assignee))))

(defun tlon-babel-set-initial-label-and-assignee ()
  "Set label to `Awaiting processing' and assignee to current user."
  (tlon-babel-set-label "Awaiting processing")
  (tlon-babel-set-assignee (tlon-babel-find-key-in-alist user-full-name tlon-babel-github-users)))

;; this is just a slightly tweaked version of `forge-edit-topic-labels'.
;; It differs from that function only in that it returns the selection
;; rather than submitting it.
(defun tlon-babel-forge-get-label (topic)
  "Return the label of the current TOPIC.
If the topic has more than one label, return the first."
  (interactive (list (forge-read-topic "Edit labels of")))
  (let* ((topic (forge-get-topic topic))
	 (repo  (forge-get-repository topic))
	 (crm-separator ","))
    (car (magit-completing-read-multiple
	  "Labels: "
	  (mapcar #'cadr (oref repo labels))
	  nil t
	  (mapconcat #'car (closql--iref topic 'labels) ",")))))

(defun tlon-babel-forge-get-assignee (topic)
  "Return the assignee of the current TOPIC.
If the topic has more than one assignee, return the first."
  (interactive (list (forge-read-topic "Edit assignees of")))
  (let* ((topic (forge-get-topic topic))
	 (repo  (forge-get-repository topic))
	 (value (closql--iref topic 'assignees))
	 (choices (mapcar #'cadr (oref repo assignees)))
	 (crm-separator ","))
    (car (magit-completing-read-multiple
	  "Assignees: " choices nil
	  (if (forge--childp repo 'forge-gitlab-repository)
	      t ; Selecting something else would fail later on.
	    'confirm)
	  (mapconcat #'car value ",")))))

;; This function simply confirms the selection offered to the user by
;; `tlon-babel-forge-get-label'. I don't know how to do this
;; properly with `magit-completing-read-multiple', so I just simulate a
;; RET keypress.
(defun tlon-babel-forge-get-label-at-point ()
  "Return the label of the topic at point.
If the topic has more than one label, return the first."
  (let ((exit-minibuffer-func (lambda () (exit-minibuffer))))
    (minibuffer-with-setup-hook
	(lambda ()
	  (add-hook 'post-command-hook exit-minibuffer-func t t))
      (tlon-babel-forge-get-label (forge-current-topic)))))

(defun tlon-babel-forge-get-assignee-at-point ()
  "Return the assignee of the topic at point.
If the topic has more than one assignee, return the first."
  (let ((exit-minibuffer-func (lambda () (exit-minibuffer))))
    (minibuffer-with-setup-hook
	(lambda ()
	  (add-hook 'post-command-hook exit-minibuffer-func t t))
      (tlon-babel-forge-get-assignee (forge-current-topic)))))

(defun tlon-babel-open-original-or-translation ()
  "Open the translation if visiting the original, and vice versa."
  (interactive)
  (let* ((current-file (file-name-nondirectory (buffer-file-name))))
    (alist-get current-file tlon-babel-translation-alist
	       (lambda (key default) default))))

(defun tlon-babel-find-key-in-alist (value alist)
  "Find the corresponding key for a VALUE in ALIST."
  (let ((pair (cl-find-if (lambda (x) (equal (cdr x) value)) alist)))
    (when pair
      (car pair))))

(defun tlon-babel-get-next-car (car alist)
  "Find the car in cons following CAR in ALIST."
  (catch 'result
    (let ((found nil))
      (dolist (pair alist)
	(when (and found (not (string= car (car pair))))
	  (throw 'result (car pair)))
	(when (string= car (car pair))
	  (setq found t)))
      nil))) ;; if CAR was the last in ALIST, there's no "next"

;;;; glossary

(defun tlon-babel-glossary-alist ()
  "Read `Glossary.csv` and return it as an alist."
  (with-temp-buffer
    (insert-file-contents tlon-babel-file-glossary)
    (let ((lines (split-string (buffer-string) "\n" t))
	  (result '()))
      (dolist (line lines result)
	(let* ((elements (split-string line "\",\""))
	       (key (substring (nth 0 elements) 1)) ; removing leading quote
	       (value (if (string-suffix-p "\"" (nth 1 elements))
			  (substring (nth 1 elements) 0 -1)   ; if trailing quote exists, remove it
			(nth 1 elements)))) ; otherwise, use as-is
	  (push (cons key value) result))))))

(defun tlon-babel-glossary-dwim ()
  "Add a new entry to the glossary or modify an existing entry."
  (interactive)
  (let* ((english-terms (mapcar 'car (tlon-babel-glossary-alist)))
	 (term (completing-read "Term: " english-terms)))
    (if (member term english-terms)
	(tlon-babel-glossary-modify term)
      (tlon-babel-glossary-add term))))

(defun tlon-babel-glossary-add (&optional english spanish)
  "Add a new entry to the glossary for ENGLISH and SPANISH terms."
  (interactive)
  (let ((english (or english (read-string "English term: ")))
	(spanish (or spanish (read-string "Spanish term: ")))
	(explanation (read-string "Explanation (optional; in Spanish): ")))
    (with-current-buffer (find-file-noselect tlon-babel-file-glossary)
      (goto-char (point-max))
      (insert (format "\n\"%s\",\"%s\",\"EN\",\"ES\"" english spanish))
      (goto-char (point-min))
      (flush-lines "^$")
      (save-buffer)
      (tlon-babel-glossary-commit "add" english explanation))))

(defun tlon-babel-glossary-modify (english)
  "Modify an entry in the glossary corresponding to the ENGLISH term."
  (let* ((spanish (cdr (assoc english (tlon-babel-glossary-alist))))
	 (spanish-new (read-string "Spanish term: " spanish))
	 (explanation (read-string "Explanation (optional; in Spanish): ")))
    (with-current-buffer (find-file-noselect tlon-babel-file-glossary)
      (goto-char (point-min))
      (while (re-search-forward (format "^\"%s\",\"%s\",\"EN\",\"ES\"" english spanish) nil t)
	(replace-match (format "\"%s\",\"%s\",\"EN\",\"ES\"" english spanish-new)))
      (goto-char (point-min))
      (flush-lines "^$")
      (save-buffer)
      (tlon-babel-glossary-commit "modify" english explanation))))

(defun tlon-babel-glossary-commit (action term &optional description)
  "Commit glossary changes.
ACTION describes the action (\"add\" or \"modify\") performed on
the glossary. TERM refers to the English glossary term to which
this action was performed. These two variables are used to
construct a commit message of the form \'Glossary: ACTION
\"TERM\"\', such as \'Glossary: add \"repugnant conclusion\"\'.
Optionally, DESCRIPTION provides an explanation of the change."
  (let ((default-directory tlon-babel-dir-babel)
	(description (if description (concat "\n\n" description) "")))
    ;; save all unsaved files in repo
    (magit-save-repository-buffers)
    (magit-pull-from-upstream nil)
    ;; if there are staged files, we do not commit or push the changes
    (unless (magit-staged-files)
      (tlon-babel-check-branch "main")
      (magit-run-git "add" tlon-babel-file-glossary)
      (let ((magit-commit-ask-to-stage nil))
	(magit-commit-create (list "-m" (format  "Glossary: %s \"%s\"%s"
						 action term description)))))))
;; (call-interactively #'magit-push-current-to-pushremote))))

;;;

(defmacro tlon-babel-create-file-opening-command (file-path)
  "Create a command to open file in FILE-PATH."
  (let* ((file-base (downcase (file-name-base file-path)))
	 (file-name (file-name-nondirectory file-path))
	 (command-name (intern (concat "tlon-babel-open-" file-base))))
    `(defun ,command-name ()
       ,(format "Open `%s'." file-name)
       (interactive)
       (find-file (file-name-concat
		   tlon-babel-dir-babel
		   ,file-path)))))

(defmacro tlon-babel-create-dir-opening-command (&optional dir-path)
  "Create a command to open file in DIR-PATH.
If DIR-PATH is nil, create a command to open the Tlon-Babel repository."
  (let* ((dir-path-hyphenated (when dir-path
				(s-replace "/" "-" dir-path)))
	 (command-name (if dir-path
			   (intern (concat "tlon-babel-open-" dir-path-hyphenated))
			 'tlon-babel-open-repo)))
    `(defun ,command-name ()
       ,(format "Open `%s'." dir-path)
       (interactive)
       (find-file (file-name-concat
		   tlon-babel-dir-babel
		   ,dir-path)))))

(tlon-babel-create-file-opening-command "etc/Glossary.csv")
(tlon-babel-create-file-opening-command "etc/new.bib")
(tlon-babel-create-file-opening-command "etc/old.bib")
(tlon-babel-create-file-opening-command "etc/finished.bib")
(tlon-babel-create-file-opening-command "etc/pending.bib")
(tlon-babel-create-file-opening-command "etc/tags.txt")
(tlon-babel-create-file-opening-command "manual.org")
(tlon-babel-create-file-opening-command "readme.md")

(tlon-babel-create-dir-opening-command)
(tlon-babel-create-dir-opening-command "originals/posts")
(tlon-babel-create-dir-opening-command "originals/tags")
(tlon-babel-create-dir-opening-command "translations/posts")
(tlon-babel-create-dir-opening-command "translations/tags")
(tlon-babel-create-dir-opening-command "etc")


(transient-define-prefix tlon-babel-dispatch ()
  "Dispatch a `tlon-babel' command."
  [["Main"
    ("j" "job"                            tlon-babel-create-job)
    ("r" "dwim"                           tlon-babel-dwim)
    ("m" "magit"                          tlon-babel-magit-status)
    ("n" "forge"                          tlon-babel-forge)
    """Package"
    ("p p" "update"                       tlon-babel-update)
    ("p l" "load variables"               tlon-babel-load-variables)
    ("p v" "version"                      tlon-babel-version)
    ]
   ["Add"
    ("a a" "to glossary"                  tlon-babel-glossary-dwim)
    """Search"
    ("s s" "multi"                        tlon-babel-search-multi)
    ("s c" "commits"                      tlon-babel-search-commits)
    ("s f" "files"                        tlon-babel-search-files)
    ("s t" "topics"                       tlon-babel-search-topics)
    ]
   ["Open file"
    ("f f" "counterpart"                  tlon-babel-open-counterpart)
    ("f g" "Glossary.csv"                 tlon-babel-open-glossary)
    ("f n" "new.bib"                      tlon-babel-open-new)
    ("f o" "old.bib"                      tlon-babel-open-old)
    ("f m" "manual.md"                    tlon-babel-open-manual)
    ("f r" "readme.md"                    tlon-babel-open-readme)
    ]
   ["Open directory"
    ("d d" "repo"                         tlon-babel-open-repo)
    ("d P" "originals > posts"            tlon-babel-open-originals-posts)
    ("d T" "originals > tags"             tlon-babel-open-originals-tags)
    ("d p" "translations > posts"         tlon-babel-open-translations-posts)
    ("d t" "translations > tags"          tlon-babel-open-translations-tags)
    ("d e" "etc"                          tlon-babel-open-etc)
    ]
   ["Browse"
    ("b b" "file"                         tlon-babel-browse-file)
    ("b r" "repo"                         tlon-babel-browse-repo)
    """File changes"
    ("h h" "Log"                          magit-log-buffer-file)
    ("h d" "Diffs since last user change" tlon-babel-log-buffer-latest-user-commit)
    ("h e" "Ediff with last user change"  tlon-babel-log-buffer-latest-user-commit-ediff)]
   ["Clock"
    ("c c" "Issue"                        tlon-babel-open-clock-topic)
    ("c f" "File"                         tlon-babel-open-clock-file )
    ("c o" "Heading"                      org-clock-goto)
    """Issue"
    ("i i" "Open counterpart"             tlon-babel-open-forge-counterpart)
    ("i I" "Open file"                    tlon-babel-open-forge-file)
    ]
   ]
  )

(defun tlon-babel-browse-file ()
  "Browse the current file in the Tlon-Babel repository."
  (interactive)
  (let* ((url-suffix (file-relative-name (buffer-file-name) tlon-babel-dir-babel))
	 (url-prefix "https://github.com/tlon-team/biblioteca-altruismo-eficaz/blob/main/"))
    (browse-url (concat url-prefix url-suffix))))

(defun tlon-babel-browse-repo ()
  "Browse the Tlon-Babel repository."
  (interactive)
  (browse-url "https://github.com/tlon-team/biblioteca-altruismo-eficaz"))

;;; request

(defconst tlon-babel-eaf-api-url
  "https://forum.effectivealtruism.org/graphql"
  "URL for the EAF GraphQL API endpoint.")

(defvar tlon-babel-eaf-objects
  '(post tag)
  "List of entities supported by the EAF GraphQL API.")

(defun tlon-babel-eaf-post-query (id)
  "Return an EA Forum GraphQL query for post whose ID is ID."
  (concat "{\"query\":\"{\\n  post(\\n    input: {\\n      selector: {\\n        _id: \\\""
	  id
	  "\\\"\\n      }\\n    }\\n  ) {\\n    result {\\n      _id\\n      postedAt\\n      url\\n      canonicalSource\\n      title\\n      contents {\\n        markdown\\n        ckEditorMarkup\\n      }\\n      slug\\n      commentCount\\n      htmlBody\\n      baseScore\\n      voteCount\\n      pageUrl\\n      legacyId\\n      question\\n      tableOfContents\\n      author\\n      user {\\n        username\\n        displayName\\n        slug\\n        bio\\n      }\\n      coauthors {\\n        _id\\n        username\\n        displayName\\n        slug\\n      }\\n    }\\n  }\\n}\\n\"}"))

(defun tlon-babel-eaf-tag-query (slug)
  "Return an EA Forum GraphQL query for tag whose slug is SLUG."
  (concat "{\"query\":\"{\\n  tag(input: { selector: { slug: \\\""
	  slug
	  "\\\" } }) {\\n    result {\\n      name\\n      slug\\n      description {\\n        html\\n      }\\n      parentTag {\\n        name\\n      }\\n    }\\n  }\\n}\\n\"}"))

(defun tlon-babel-eaf-request (id-or-slug &optional async)
  "Run an EAF request for ID-OR-SLUG.
If ASYNC is t, run the request asynchronously."
  (let* ((object (tlon-babel-eaf-get-object id-or-slug))
	 (fun (pcase object
		('post 'tlon-babel-eaf-post-query)
		('tag 'tlon-babel-eaf-tag-query)
		(_ (error "Invalid object: %S" object))))
	 (query (funcall fun id-or-slug))
	 response)
    (request
      tlon-babel-eaf-api-url
      :type "POST"
      :headers '(("Content-Type" . "application/json"))
      :data query
      :parser 'json-read
      :sync (not async)
      :success (cl-function
		(lambda (&key data &allow-other-keys)
		  (setq response (cdr (assoc 'data data)))))
      :error (cl-function
	      (lambda (&rest args &key error-thrown &allow-other-keys)
		(message "Error: %S" error-thrown))))
    response))

(defun tlon-babel--eaf-get-post-result (response)
  "docstring"
  (let* ((post (cdr (assoc 'post response)))
	 (result (cdr (assoc 'result post))))
    result))

(defun tlon-babel-eaf-get-post-id (response)
  "docstring"
  (let* ((result (tlon-babel--eaf-get-post-result response))
	 (id (cdr (assoc '_id result))))
    id))

(defun tlon-babel-eaf-get-post-html (response)
  "docstring"
  (let* ((result (tlon-babel--eaf-get-post-result response))
	 (html (cdr (assoc 'htmlBody result))))
    html))

(defun tlon-babel-eaf-get-post-title (response)
  "docstring"
  (let* ((result (tlon-babel--eaf-get-post-result response))
	 (title (cdr (assoc 'title result))))
    title))

(defun tlon-babel-eaf-get-post-author (response)
  "docstring"
  (let* ((result (tlon-babel--eaf-get-post-result response))
	 (author (cdr (assoc 'author result))))
    author))

(defun tlon-babel-eaf-get-post-username (response)
  "docstring"
  (let* ((result (tlon-babel--eaf-get-post-result response))
	 (user (cdr (assoc 'user result)))
	 (username (cdr (assoc 'username user))))
    username))

(defun tlon-babel--eaf-get-tag-result (response)
  "docstring"
  (let* ((tag (cdr (assoc 'tag response)))
	 (result (cdr (assoc 'result tag))))
    result))

(defun tlon-babel-eaf-get-tag-slug (response)
  "docstring"
  (let* ((result (tlon-babel--eaf-get-tag-result response))
	 (slug (cdr (assoc 'slug result))))
    slug))

(defun tlon-babel-eaf-get-tag-html (response)
  "docstring"
  (let* ((result (tlon-babel--eaf-get-tag-result response))
	 (description (cdr (assoc 'description result)))
	 (html (cdr (assoc 'html description))))
    html))

(defun tlon-babel-eaf-get-tag-title (response)
  "docstring"
  (let* ((result (tlon-babel--eaf-get-tag-result response))
	 (title (cdr (assoc 'name result))))
    (tlon-babel-shorten-title title)))

;;; html import

(defvar tlon-babel-pandoc-convert-from-file
  "pandoc -s '%s' -t markdown -o '%s'"
  "Command to convert from HTML file to Markdown.")

(defvar tlon-babel-pandoc-convert-from-url
  "pandoc -s -r html '%s' -o '%s'"
  "Command to convert from URL to Markdown.")

(defun tlon-babel-save-html-to-file (html)
  "Save the HTML string HTML to a temporary file."
  (let ((filename (make-temp-file "tlon-babel-request-" nil ".html")))
    (with-temp-file filename
      (insert html))
    filename))

;;; translation

(defun tlon-babel-search-translation (string)
  "Search for a Spanish translation of English STRING."
  (interactive "sString to translate: ")
  (let ((urls '("https://spanish.stackexchange.com/search?q=%s"
		"https://es.bab.la/diccionario/ingles-espanol/%s"
		"https://en.wikipedia.org/w/index.php?fulltext=Search&profile=default&search=%s"
		"https://context.reverso.net/traduccion/ingles-espanol/%s"
		"https://www.linguee.com/english-spanish/search?query=%s")))
    (dolist (url urls)
      (browse-url (format url (url-hexify-string string)) 'new-buffer)))
  (ps/goldendict-search-input string))

(defun tlon-babel-file-to-string (file-path)
  "Read the contents of FILE-PATH and return it as a string."
  (with-temp-buffer
    (insert-file-contents file-path)
    (unfill-region (point-min) (point-max))
    (buffer-string)))

(defun tlon-babel-gpt-rewrite ()
  "Docstring."
  (interactive)
  (let* ((text (if (region-active-p)
		   (buffer-substring-no-properties (region-beginning) (region-end))
		 (read-string "Text to rewrite: "))))
    (require 'gptel)
    (gptel-request
     (format "Por favor, genera las mejores diez variantes del siguiente texto castellano: '%s'. Por favor, devuelve todas las variantes en una única linea, separadas por '|'. No insertes un espacio ni antes ni después de '|'. No agregues ningún comentario aclaratorio: solo necesito la lista de variantes. A modo de ejemplo, para la expresión 'búsqueda de poder' el texto a devolver sería: 'ansia de poder|ambición de poder|búsqueda de autoridad|sed de poder|afán de poder|aspiración de poder|anhelo de poder|deseo de control|búsqueda de dominio|búsqueda de control' (esta lista solo pretende ilustrar el formato en que debes presentar tu respuesta). Gracias!" text)
     :callback
     (lambda (response info)
       (if (not response)
	   (message "gptel-quick failed with message: %s" (plist-get info :status))
	 (let* ((variants (split-string response "|"))
		(variant (completing-read "Variant: " variants)))
	   (delete-region (region-beginning) (region-end))
	   (kill-new variant)))))))

(defun tlon-babel-gpt-translate (text)
  "Docstring."
  (interactive "sText to translate: ")
  (require 'gptel)
  (gptel-request
   (format "Generate the best ten Spanish translations of the following English text: '%s'. Please return each translation on the same line, separated by '|'. Do not add a space either before or after the '|'. Do not precede your answer by 'Here are ten Spanish translations' or any comments of that sort: just return the translations. An example return string for the word 'very beautiful' would be: 'muy bello|muy bonito|muy hermoso|muy atractivo' (etc). Thanks!" text)
   :callback
   (lambda (response info)
     (if (not response)
	 (message "gptel-quick failed with message: %s" (plist-get info :status))
       (let ((translations (split-string response "|")))
	 (kill-new (completing-read "Translation: " translations)))))))

(defun tlon-babel-gpt-translate-file (file)
  "Docstring."
  (let* ((counterpart (tlon-babel-get-counterpart-filename file))
	 (target-path (concat
		       (file-name-sans-extension counterpart)
		       "--gpt-translated.md")))
    (gptel-request
     (concat "Translate the following text into Spanish:\n\n"
	     (tlon-babel-file-to-string file))
     :callback
     (lambda (response info)
       (if (not response)
	   (message "gptel-quick failed with message: %s" (plist-get info :status))
	 (with-temp-buffer
	   (insert response)
	   (write-region (point-min) (point-max) target-path)))))))

(defun tlon-babel-create-file-from-commit (file-path commit-hash)
  "Create a temporary file with the state of the FILE-PATH at the COMMIT-HASH and return this path."
  (let* ((file-name (file-name-nondirectory file-path))
	 (file-directory (file-name-directory file-path))
	 (repo-root (locate-dominating-file file-path ".git"))
	 (relative-file-path (file-relative-name file-path repo-root))
	 (new-file-name (format "%s_%s" commit-hash file-name))
	 (new-file-path (make-temp-file new-file-name nil ".md"))
	 (git-command
	  (format "git show %s:\"%s\""
		  commit-hash
		  (shell-quote-argument relative-file-path))))
    (let ((default-directory repo-root))
      (with-temp-buffer
	(insert (shell-command-to-string git-command))
	(write-file new-file-path)))
    (message "File created: %s" new-file-path)
    new-file-path))

;;; Markdown cleanup

(defun tlon-babel-split-footnotes-into-separate-paragraphs ()
  "Split footnotes into separate paragraphs."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\\(\\[\\^[[:digit:]]\\{1,3\\}\\]:\\)" nil t)
      (replace-match "\n\n\\1"))))

(defun tlon-babel-fix-list ()
  "Format the current paragraph into a proper list."
  (interactive)
  (save-excursion
    (let ((beg (progn (backward-paragraph) (point)))
	  (end (progn (forward-paragraph) (point))))
      (goto-char beg)
      (replace-regexp-in-region " - " "\n- " beg end))))

(defun tlon-babel-fix-footnote-punctuation ()
  "Place footnotes after punctuation mark."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    ;; we add a character at the beginning to avoid matching the footnote targets
    (while (re-search-forward "\\(.\\)\\(\\[\\^[[:digit:]]\\{1,3\\}\\]\\)\\([[:punct:]]\\)" nil t)
      (replace-match "\\1\\3\\2"))))

(defun tlon-babel-post-translation-cleanup ()
  "Cleanup processes to be run after a translation is completed."
  (interactive)
  (tlon-babel-fix-footnote-punctuation)
  ;; potentially add more cleanup processes here
  )

;;; load vars

(defun tlon-babel-load-variables ()
  "Load the variables to reflect changes to the files in the `etc' directory."
  (interactive)
  (setq tlon-babel-tags (tlon-babel-read-urls-from-file tlon-babel-file-tags)
	tlon-babel-wiki-urls (list ""))
  (dolist (slug tlon-babel-tag-slugs)
    (add-to-list 'tlon-babel-wiki-urls
		 (format "https://forum.effectivealtruism.org/topics/%s" slug)))
  (tlon-babel-load-post-correspondence)
  (message "Variables loaded."))

(tlon-babel-load-variables)

(provide 'tlon-babel)
;;; tlon-babel.el ends here
