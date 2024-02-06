;;; tlon-babel-org-ghub.el --- Org-GitHub integration -*- lexical-binding: t -*-

;; Copyright (C) 2024

;; Author: Pablo Stafforini
;; Homepage: https://github.com/tlon-team/tlon-babel
;; Version: 0.1

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-GitHub integration.

;;; Code:

(require 'forge)
(require 'org)
(require 'tlon-babel)

;;;; User options

(defcustom tlon-babel-warn-when-no-valid-label t
  "Whether to warn the user when the issue has no valid label.
If t, warn the user. If `prompt', prompt the user for a label. If nil, do
nothing."
  :type '(choice (const :tag "Warn" t)
                 (const :tag "Prompt" prompt)
                 (const :tag "Do nothing" nil))
  :group 'tlon-babel)

;;;; Main variables

(defconst tlon-babel-todo-statuses
  '("TODO" "IMPORTANT" "URGENT" "SOMEDAY" "MAYBE" "WAITING")
  "List of admissible TODO statuses.
Note that your `org-todo-keywords' user option should include these labels for
`org-mode' to recognize them, and that the buffer has to be refreshed after the
value of that option is reset.")

(defconst tlon-babel-todo-tags
  '("PendingReview" "Later")
  "List of admissible TODO tags.")

;;;; Functions

;;;;; Movement

(defun tlon-babel-visit-issue (&optional number repo)
  "Visit Github issue.
If NUMBER and REPO are nil, follow org link to issue if point is on an `orgit'
link, else get their values from the heading title, if possible."
  (interactive)
  (forge-visit-issue (tlon-babel-get-issue number repo)))

(defun tlon-babel-get-issue (&optional number repo)
  "Get Github issue.
If NUMBER and REPO are nil, follow org link to issue if point is on an `orgit'
link, else get their values from the heading title, if possible."
  (when-let* ((number (or number
			  (tlon-babel-get-issue-number-from-heading)))
	      (repo (or repo
			(tlon-babel-get-repo-from-heading)))
	      (default-directory repo)
	      (forge-repo (forge-get-repository nil))
	      (issue-id (caar (forge-sql [:select [id] :from issue
						  :where (and (= repository $s1)
							      (= number $s2))]
					 (oref forge-repo id)
					 number))))
    (forge-get-topic issue-id)))

(defun tlon-babel-get-issue-buffer (&optional number repo)
  "Get Github issue buffer.
If NUMBER and REPO are nil, follow org link to issue if point is on an `orgit'
link, else get their values from the heading title, if possible."
  (save-window-excursion
    (tlon-babel-visit-issue number repo)
    (current-buffer)))

(defun tlon-babel-visit-todo (&optional pos file)
  "Visit TODO at POS in FILE.
If POS is nil, use the position of the TODO associated with the issue at point.
If FILE is nil, use the file where the issue at point would be stored (depending
on whether or not is a job)."
  (if-let ((pos (or pos (tlon-babel-get-todo-position-from-issue)))
	   (file (or file (tlon-babel-get-todos-file-from-issue))))
      (tlon-babel-open-todo file pos)
    (user-error "No TODO found")))

(defun tlon-babel-open-todo (file position)
  "Open FILE at TODO POSITION."
  (find-file file)
  (widen)
  (org-kill-note-or-show-branches)
  (goto-char position))

(defun tlon-babel-visit-todo-or-capture ()
  "Visit the TODO associated with the current issue, creating one if necessary."
  (if-let ((pos (tlon-babel-get-todo-position-from-issue)))
      (tlon-babel-visit-todo pos)
    (tlon-babel-capture-issue)))

;;;###autoload
(defun tlon-babel-capture-issue (&optional issue)
  "Create a new `org-mode' TODO based on ISSUE.
If ISSUE is nil, use the issue at point or in the current buffer.

This command triggers one of two `org-capture' capture templates, depending on
whether the issue is or is not a job. If it is a job, it will process it as new
job if it has neither a label nor an assignee, else it will refile it under the
appropriate heading."
  (interactive)
  (let ((issue (or issue (forge-current-topic))))
    (if (tlon-babel-issue-is-job-p issue)
	(tlon-babel-create-job-todo-from-issue issue)
      (tlon-babel-create-generic-todo-from-issue issue))))

;;;###autoload
(defun tlon-babel-capture-all-issues ()
  "Capture all issues in the current repository."
  (interactive)
  (let ((default-directory (tlon-babel-get-repo 'error 'include-all))
	(current-user (tlon-babel-user-lookup :github :name user-full-name))
	(num-captured 0))
    (dolist (issue (tlon-babel-get-open-issues))
      (let ((assignee (tlon-babel-get-assignee issue))
	    (issue-name (tlon-babel-get-issue-name issue)))
	(when (not assignee)
	  (if (y-or-n-p (format "Issue `%s' has no assignee. Assign to you?" issue-name))
	      (progn
		(tlon-babel-assign-issue issue current-user)
		(while (not (string= current-user assignee))
		  (setq assignee (tlon-babel-get-assignee issue))
		  (sleep-for 1)))
	    (message "Issue `%s' skipped: assigned to no one." issue-name)))
	(if (and (string= current-user assignee)
		 (not (tlon-babel-get-todo-position-from-issue issue)))
	    (save-window-excursion
	      (tlon-babel-capture-issue issue)
	      (message "Issue `%s' captured." issue-name)
	      (setq num-captured (1+ num-captured)))
	  (message "Issue `%s' skipped: assigned to %s." issue-name assignee))))
    (message "%s issues captured." num-captured)))

(defun tlon-babel-assign-issue (&optional issue user)
  "Assign ISSUE to USER.
If ISSUE is nil, use the issue at point or in the current buffer."
  (interactive)
  (let ((issue (or issue (forge-current-topic))))
    (unless (tlon-babel-get-assignee issue)
      (let ((user (or user
		      (completing-read (format "Issue `%s' has no assignee. Assign to "
					       (tlon-babel-get-issue-name issue))
				       (tlon-babel-user-lookup-all :github)))))
	(tlon-babel-set-assignee `(,user) issue)))))

(defun tlon-babel-get-open-issues ()
  "Return a list of all open issues in the current repository."
  (let* ((repo (forge-get-repository nil))
	 (all-issues (forge-ls-topics repo 'forge-issue)))
    (seq-filter (lambda (issue)
		  (string= (oref issue state) "open"))
		all-issues)))

(defun tlon-babel-issue-is-job-p (&optional issue)
  "Return t if ISSUE at point is a job.
If ISSUE is nil, use the issue at point or in the current buffer."
  (let ((issue (or issue (forge-current-topic))))
    (when (string-match-p "^Job: " (oref issue title))
      t)))

(defun tlon-babel-create-job-todo-from-issue (&optional issue)
  "Create a new `org-mode' job TODO based on ISSUE.
If ISSUE is nil, use the issue at point or in the current buffer."
  (let ((issue (or issue (forge-current-topic))))
    (tlon-babel-check-label-or-assignee-present issue)
    (tlon-babel-check-label-present issue)
    (when (tlon-babel-capture-issue-p issue)
      (tlon-babel-store-or-refile-job-todo issue))))

;; TODO: revise so that it alerts the user when no label is present instead of
;; prompting for a label
(defun tlon-babel-create-generic-todo-from-issue (&optional issue)
  "Create a new `org-mode' generic TODO based on ISSUE.
If ISSUE is nil, use the issue at point or in the current buffer."
  (when (tlon-babel-capture-issue-p issue)
    (let* ((issue (or issue (forge-current-topic)))
	   (status (tlon-babel-get-status-in-issue issue)))
      (unless status
	(tlon-babel-when-no-valid-status issue))
      (tlon-babel-store-todo "tbG" nil issue))))

(defun tlon-babel-when-no-valid-status (issue)
  "Take appropriate action when ISSUE does not have a valid label.
A label is considered valid if it is a member of `tlon-babel-todo-statuses'."
  (pcase tlon-babel-warn-when-no-valid-label
    ('prompt (progn
	       (tlon-babel-set-labels (list (tlon-babel-set-status-label)) issue)
	       (forge-pull-topic issue)
	       (while (not (tlon-babel-is-valid-status-p nil issue))
		 (sleep-for 1))))
    ('t (message "Issue `%s' has no valid label." (oref issue title)))
    ('nil nil)))

(defun tlon-babel-store-todo (template &optional no-action issue)
  "Store a new TODO using TEMPLATE.
If TODO already exists, signal an error. If NO-ACTION is non-nil, store a master
TODO. If ISSUE is non-nil, use it instead of the issue at point."
  (let ((issue (or issue (forge-current-topic))))
    (when (tlon-babel-get-todo-position-from-issue issue)
      (user-error "TODO `%s' already exists" (tlon-babel-get-issue-name issue)))
    (let ((todo (tlon-babel-make-todo-name-from-issue no-action nil issue)))
      (kill-new todo)
      (org-capture nil template))))

(defun tlon-babel-store-master-job-todo (&optional set-issue issue)
  "Create a new job master TODO.
If SET-ISSUE is non-nil, set issue label to `Awaiting processing' and assignee
to the current user. If ISSUE is non-nil, use the issue at point or in the
current buffer."
  (let* ((issue (or issue (forge-current-topic)))
	 (todo (tlon-babel-make-todo-name-from-issue 'no-action 'no-status issue)))
    (if-let ((pos (tlon-babel-get-todo-position todo (tlon-babel-get-todos-jobs-file))))
	(tlon-babel-visit-todo pos)
      (save-window-excursion
	(when set-issue
	  (tlon-babel-set-initial-label-and-assignee))
	(tlon-babel-store-todo "tbJ" 'master-todo issue)))))

(defun tlon-babel-store-or-refile-job-todo (&optional issue)
  "Refile TODO under appropriate heading, or create new master TODO if none exists.
If ISSUE is nil, use the issue at point or in the current buffer."
  (if-let* ((issue (or issue (forge-current-topic)))
	    (pos (tlon-babel-get-todo-position
		  (tlon-babel-make-todo-name-from-issue 'no-action 'no-status issue)
		  (tlon-babel-get-todos-jobs-file))))
      (save-window-excursion
	(tlon-babel-store-todo "tbJ" nil issue)
	(let* ((inhibit-message t))
	  (org-extras-refile-at-position pos)
	  (org-extras-refile-goto-latest)))
    (when (y-or-n-p (format "No master TODO found for issue `%s'. Create?" (oref issue title)))
      (tlon-babel-store-master-job-todo nil issue)
      (tlon-babel-capture-issue issue))))

(defun tlon-babel-get-todos-jobs-file ()
  "Get the file containing the jobs `org-mode' ID."
  (or tlon-babel-todos-jobs-file
      (setq tlon-babel-todos-jobs-file
	    (tlon-babel-get-file-with-id paths-tlon-babel-todos-jobs-id))))

(defun tlon-babel-get-todos-generic-file ()
  "Get the file containing the generic `org-mode' ID."
  (or tlon-babel-todos-generic-file
      (setq tlon-babel-todos-generic-file
	    (tlon-babel-get-file-with-id paths-tlon-babel-todos-generic-id))))

(defun tlon-babel-get-file-with-id (id)
  "Return the file containing the heading with the given `org-mode' ID."
  (when-let ((location (org-roam-id-find id)))
    (car location)))

(defun tlon-babel-get-todo-position (todo file &optional loose)
  "Return the position of TODO exactly matching heading in FILE.
If LOOSE is non-nil, return the position of the first TODO matching a substring
rather than strictly matching the heading."
  (if loose
      (tlon-babel-find-loose-headline-in-file todo file)
    (org-find-exact-headline-in-buffer todo (find-file-noselect file))))

(defun tlon-babel-find-loose-headline-in-file (todo file)
  "Move point to TODO in FILE matching TODO."
  (with-current-buffer (find-file-noselect file)
    (save-restriction
      (widen)
      (goto-char (point-min))
      (when (re-search-forward (concat "^\\*+.*" todo) nil t)
	(point)))))

(defun tlon-babel-capture-issue-p (&optional issue)
  "Return t iff ISSUE should be captured.
An issue should be captured either if it is assigned to the current user or if
the user says so when prompted.

If ISSUE is nil, use the issue at point or in the current buffer."
  (let* ((issue (or issue (forge-current-topic)))
	 (assignee (tlon-babel-user-lookup :name :github (tlon-babel-get-assignee issue))))
    (if (string= user-full-name assignee)
	t
      (pcase (read-char-choice
	      (format "The assignee of `%s' is %s.\nSelf-assign? [y]es | no, and [c]apture | no, and do [n]ot capture"
		      (oref issue title) assignee)
	      '(?y ?c ?n))
	(?y (tlon-babel-set-assignee `(,(tlon-babel-user-lookup :github :name user-full-name)))
	    (while (not (tlon-babel-capture-issue-p issue))
	      (sleep-for 1)))
	(?c t)
	(?n nil)))))

;; TODO: consider using something other than `tlon-babel-get-first-label'
(defun tlon-babel-check-label-or-assignee-present (&optional issue)
  "Check that ISSUE has a label or an assignee.
If not, offer to process it as a new job.

If ISSUE is nil, use the issue at point or in the current buffer."
  (let* ((issue (or issue (forge-current-topic)))
	 (assignee (tlon-babel-user-lookup :name :github (tlon-babel-get-assignee issue)))
	 (label (tlon-babel-get-first-label issue)))
    (unless (and assignee label)
      (if (y-or-n-p "Process issue as a new job (this will assign the issue to you, add the label 'Awaiting processing', and create a new master TODO in your org mode file)?")
	  (save-window-excursion
	    (tlon-babel-store-master-job-todo 'set-issue)
	    (while (not (and (tlon-babel-get-assignee)
			     (tlon-babel-get-first-label)))
	      (sleep-for 1))
	    (tlon-babel-capture-issue issue))
	(user-error "Aborted")))))

(defun tlon-babel-check-label-present (&optional issue)
  "Check that ISSUE has a label.
If ISSUE is nil, use the issue at point or in the current buffer."
  (let* ((issue (or issue (forge-current-topic)))
	 (label (tlon-babel-get-first-label issue)))
    (unless label
      (if (y-or-n-p "The issue has no label. Would you like to add one?")
	  (tlon-babel-set-labels (list (tlon-babel-set-job-label)))
	(user-error "Aborted")))))

(defun tlon-babel-get-todos-file-from-issue ()
  "Get the file where the current issue is or would be stored."
  (if (tlon-babel-issue-is-job-p)
      (tlon-babel-get-todos-jobs-file)
    (tlon-babel-get-todos-generic-file)))

(defun tlon-babel-get-todo-position-from-issue (&optional issue)
  "Get the TODO position of ISSUE, using the appropriate method.
If the issue is a job, use the heading name, else use the `orgit-topic' ID. If
ISSUE is nil, use the issue at point."
  (when-let ((issue (or issue (forge-current-topic))))
    (if (tlon-babel-issue-is-job-p issue)
	(tlon-babel-get-todo-position
	 (tlon-babel-make-todo-name-from-issue nil 'no-status issue)
	 (tlon-babel-get-todos-jobs-file))
      (tlon-babel-get-todo-position
       (oref issue id)
       (tlon-babel-get-todos-generic-file) 'loose))))

;;;###autoload
(defun tlon-babel-visit-counterpart ()
  "Visit the ID associated with TODO, or vice versa."
  (interactive)
  (tlon-babel-todo-issue-funcall #'tlon-babel-visit-issue
				 #'tlon-babel-visit-todo))

;;;###autoload
(defun tlon-babel-visit-counterpart-or-capture ()
  "Visit the issue associated with TODO, or vice versa, creating TODO if necessary."
  (interactive)
  (tlon-babel-todo-issue-funcall #'tlon-babel-visit-issue
				 #'tlon-babel-visit-todo-or-capture))

(defun tlon-babel-todo-issue-funcall (todo-fun issue-fun)
  "Call TODO-FUN or ISSUE-FUN depending on the current major mode."
  (pcase major-mode
    ('org-mode
     (unless (org-at-heading-p)
       (user-error "I could not find an `org-mode' heading at point"))
     (funcall todo-fun))
    ((or 'forge-topic-mode 'forge-issue-mode 'forge-issue-list-mode 'magit-status-mode)
     (unless (tlon-babel-get-issue-name)
       (user-error "I could not find a GitHub issue at point"))
     (funcall issue-fun))
    (_ (user-error "This command cannot be invoked in `%s`" major-mode))))

;;;;; Get heading elements

(defun tlon-babel-get-element-from-heading (regexp)
  "Get element matching REGEXP from the heading at point."
  (when (org-at-heading-p)
    (let ((heading (substring-no-properties (org-get-heading t t t t))))
      (when (string-match regexp heading)
	(match-string 1 heading)))))

(defun tlon-babel-get-issue-number-from-heading ()
  "Get the GitHub issue number from the `org-mode' heading at point."
  (when-let ((issue-number (tlon-babel-get-element-from-heading "#\\([[:digit:]]\\{1,4\\}\\)")))
    (string-to-number issue-number)))

(defun tlon-babel-get-repo-from-heading ()
  "Get the repo from the heading at point."
  (let* ((abbrev-repo (tlon-babel-get-element-from-heading "^\\[\\(.*?\\)\\]")))
    (tlon-babel-repo-lookup :dir :abbrev abbrev-repo)))

(defun tlon-babel-get-issue-number-from-open-issues ()
  "Prompt user to select from a list of open issues and return number of selection."
  (let* ((default-directory (tlon-babel-get-repo nil 'include-all))
	 (repo (forge-get-repository 'full))
	 ;; Fetch all issues, but filter for open ones
	 (issue-list (mapcar #'(lambda (issue)
				 (cons (format "#%d %s"
					       (oref issue number)
					       (oref issue title))
				       (oref issue number)))
			     (cl-remove-if-not (lambda (issue)
						 (string= (oref issue state) "open"))
					       (oref repo issues))))
	 ;; Let the user select one
	 (selected-issue (cdr (assoc (completing-read "Select an issue: " issue-list) issue-list))))
    ;; Return the selected issue number
    selected-issue))

(defun tlon-babel-get-issues (&optional repo)
  "Return a list of all open issues in REPO.
If REPO is nil, use the current repository."
  (let* ((repo (or repo (forge-get-repository t)))
	 (issues (forge-ls-issues repo)))
    issues))

(defun tlon-babel-get-latest-issue (&optional repo)
  "Return the most recently created issue in REPO.
If REPO is nil, use the current repository."
  (let* ((issues (tlon-babel-get-issues repo))
	 (latest-issue (car (sort issues (lambda (a b)
					   (time-less-p
					    (date-to-time (oref b created))
					    (date-to-time (oref a created))))))))
    (list (oref latest-issue number) (oref latest-issue title))))

(defun tlon-babel-count-issues (&optional repo)
  "Return the number of open issues in REPO.
If REPO is nil, use the current repository."
  (length (tlon-babel-get-issues repo)))

;;;;; Set heading elements

(defun tlon-babel-set-repo-in-heading ()
  "Set the repo in the heading at point if not already present."
  (when (and (org-at-heading-p)
	     (not (tlon-babel-get-repo-from-heading)))
    (let* ((repo-name (completing-read "Select repo: " (tlon-babel-repo-lookup-all :name)))
	   (abbrev-repo (tlon-babel-repo-lookup :abbrev :name repo-name)))
      (org-extras-goto-beginning-of-heading-text)
      (insert (format "[%s] " abbrev-repo)))))

(defun tlon-babel-set-issue-number-in-heading (issue-number)
  "Set ISSUE-NUMBER in heading at point if not already present."
  (unless (tlon-babel-get-issue-number-from-heading)
    (org-extras-goto-beginning-of-heading-text)
    ;; move past repo name
    (re-search-forward "\\[.+?\\] ")
    (insert (format "#%s " (number-to-string issue-number)))))


;;;;; Close issues/todo

;;;###autoload
(defun tlon-babel-close-issue-and-todo ()
  "With point on either, close issue and associated TODO."
  (interactive)
  (tlon-babel-todo-issue-funcall
   #'tlon-babel-close-issue-and-todo-from-issue
   (lambda ()
     (tlon-babel-visit-counterpart)
     (tlon-babel-close-issue-and-todo-from-issue))))

(defun tlon-babel-close-issue-and-todo-from-issue ()
  "With point on issue, close issue and associated TODO."
  (let ((issue-number (tlon-babel-get-issue-number-from-heading))
	(repo (tlon-babel-get-repo-from-heading)))
    (tlon-babel-close-issue-number issue-number repo)
    (tlon-babel-visit-todo)
    (org-todo "DONE")
    (message "Closed issue and TODO.")))

;; shouldn’t this be done using the orgit-link rather than issue-number?
(defun tlon-babel-close-issue-number (issue-number repo)
  "Close the issue with ISSUE-NUMBER in REPO."
  (tlon-babel-visit-issue issue-number repo)
  (tlon-babel-close-issue))

;;;;; Set TODO statuses/tags

(defun tlon-babel-get-status-in-issue (&optional issue)
  "Get remote status of ISSUE.
If ISSUE is nil, use the issue at point or in the current buffer.

The status is returned upcased."
  (let ((issue (or issue (forge-current-topic))))
    (if (eq (tlon-babel-get-state) 'closed)
	"DONE"
      (if-let ((labels (tlon-babel-get-element 'labels issue))
	       (status (tlon-babel-get-status-in-labels labels)))
	  status
	""))))

(defun tlon-babel-get-tags-in-issue (&optional issue)
  "Get remote tags of ISSUE.
If ISSUE is nil, use the issue at point or in the current buffer."
  (let ((issue (or issue (forge-current-topic))))
    (when-let ((labels (tlon-babel-get-element 'labels issue)))
      (tlon-babel-get-tags-in-labels labels))))

(defun tlon-babel-get-status-in-todo ()
  "Return the status of the `org-mode' heading at point.
The status is returned downcased."
  (when-let ((status (org-get-todo-state)))
    (when (member status tlon-babel-todo-statuses)
      (downcase status))))

(defun tlon-babel-get-tags-in-todo ()
  "Return the tags in the `org-mode' heading at point."
  (when-let ((tags (cdr (org-get-tags))))
    (let (valid-tags)
      (dolist (tag tags valid-tags)
	(when (member tag tlon-babel-todo-tags)
	  (push tag valid-tags))))))

(defun tlon-babel-get-corresponding-label ()
  "Get TODO status for `org-mode' heading at point from corresponding issue."
  (save-window-excursion
    (tlon-babel-visit-issue)
    (tlon-babel-get-first-label)))

;; MAYBE: delete
(defun tlon-babel-is-valid-status-p (&optional status issue)
  "Return t iff STATUS it is a valid TODO status.
A status is valid iff it is a member of `tlon-babel-todo-statuses'. If
STATUS is nil, use the status of heading or issue at point. If ISSUE is nil, use
the issue at point or in the current buffer."
  (if-let ((status (or status (pcase major-mode
				('org-mode (org-get-todo-state))
				((or 'forge-topic-mode 'forge-issue-mode 'forge-issue-list-mode 'magit-status-mode)
				 (tlon-babel-get-first-label issue))))))
      (when (or (member status tlon-babel-todo-statuses)
		(member status (mapcar #'downcase tlon-babel-todo-statuses)))
	t)
    nil))

(defun tlon-babel-is-valid-tag-p (&optional tag issue)
  "Return t iff TAG it is a valid TODO tag.
A tag is valid iff it is a member of `tlon-babel-todo-tags'. If
STATUS is nil, use the tag of heading or issue at point. If ISSUE is nil, use
the issue at point or in the current buffer."
  (if-let ((tag (or tag (pcase major-mode
			  ('org-mode (org-get-todo-state))
			  ((or 'forge-topic-mode 'forge-issue-mode 'forge-issue-list-mode 'magit-status-mode)
			   (tlon-babel-get-first-label issue))))))
      (when (member tag tlon-babel-todo-tags)
	t)
    nil))

;;;;; Re-sync

;;;###autoload
(defun tlon-babel-reconcile-issue-and-todo ()
  "With point on either, reconcile issue and associated TODO."
  (interactive)
  (tlon-babel-todo-issue-funcall
   (lambda ()
     (with-current-buffer (tlon-babel-get-issue-buffer)
       (tlon-babel-reconcile-issue-and-todo-from-issue)))
   #'tlon-babel-reconcile-issue-and-todo-from-issue))

;;;###autoload
(defun tlon-babel-reconcile-all-issues-and-todos ()
  "Reconcile all TODOs under `paths-tlon-babel-todos-generic-id'."
  (interactive)
  (save-window-excursion
    (org-roam-id-open paths-tlon-babel-todos-generic-id nil)
    (let ((level (org-current-level)))
      (call-interactively 'org-next-visible-heading)
      (while (> (org-current-level) level)
	(if (or (not (tlon-babel-get-issue))
		(member org-archive-tag (org-get-tags)))
	    (org-next-visible-heading 1)
	  (tlon-babel-reconcile-issue-and-todo)
	  (call-interactively 'org-next-visible-heading))))
    (message "Finished reconciling.")))

(defun tlon-babel-reconcile-issue-and-todo-from-issue ()
  "With point on issue, reconcile issue and associated TODO-NAME."
  (let ((issue-name (tlon-babel-make-todo-name-from-issue))
	(pos (tlon-babel-get-todo-position-from-issue)))
    (save-window-excursion
      (tlon-babel-visit-todo pos)
      (let ((todo-name (substring-no-properties (org-get-heading nil nil t t))))
	(unless (string= issue-name todo-name)
	  (tlon-babel-reconcile-issue-and-todo-prompt issue-name todo-name))))))

(defun tlon-babel-reconcile-issue-and-todo-prompt (issue-name todo-name)
  "Prompt the user to reconcile discrepancies between ISSUE-NAME and TODO-NAME."
  (pcase (read-char-choice
	  (format "The issue differs from its todo. Keep (i)ssue | Keep (t)odo | (a)bort\nissue: `%s'\ntodo:  `%s' "
		  issue-name todo-name)
	  '(?i ?t ?a))
    (?i (tlon-babel-update-todo-from-issue issue-name))
    (?t (tlon-babel-update-issue-from-todo todo-name))
    (_ (user-error "Aborted"))))

(defun tlon-babel-update-todo-from-issue (issue-name)
  "Update TODO to match ISSUE-NAME."
  (let ((original-visual-line-mode visual-line-mode))
    (visual-line-mode -1)
    (save-window-excursion
      (beginning-of-line)
      (re-search-forward " ")
      (org-fold-show-subtree)
      (org-kill-line)
      (insert issue-name)
      (message "TODO updated"))
    (visual-line-mode original-visual-line-mode)))

(defun tlon-babel-update-issue-from-todo (_)
  "Update ISSUE to match TODO-NAME."
  (user-error "This command has not yet been developed. Sorry!"))
;; TODO: Develop function. The below approach doesn't work because
;; `org-complex-heading-regexp' fails to match a heading

;; (string-match org-complex-heading-regexp (concat "* " todo-name))
;; (let ((title (match-string-no-properties 4))
;; (state (match-string-no-properties 2)))
;; (message "%s %s" title state)))

;;;;; Change issue properties

(defun tlon-babel-set-properies (properties type &optional issue)
  "Set PROPERTIES of TYPE in ISSUE.
If ISSUE is nil, use issue at point or in the current buffer."
  (interactive)
  (let* ((fun (pcase type
		('label #'forge--set-topic-labels)
		('assignee #'forge--set-topic-assignees)
		(_ (user-error "Property type `%s' not recognized" type))))
	 (issue (or issue (forge-get-topic (forge-current-topic))))
	 (repo (forge-get-repository issue))
	 (crm-separator ","))
    (funcall fun repo issue properties)))

;; TODO: Cleanup the three functions below
(defun tlon-babel-set-labels (&optional labels issue)
  "Apply LABELS to ISSUE.
If ISSUE is nil, use issue at point or in the current buffer."
  (interactive)
  (let* ((issue (or issue (forge-get-topic (forge-current-topic))))
	 (labels (or labels (if (tlon-babel-issue-is-job-p issue)
				(list (tlon-babel-set-job-label))
			      (list (tlon-babel-set-status-label))))))
    (tlon-babel-set-properies labels 'label issue)))

(defun tlon-babel-set-job-label ()
  "Prompt the user to select a job label."
  (let ((label (completing-read "What should be the label? "
				(tlon-babel-label-lookup-all :label))))
    label))

(defun tlon-babel-set-status-label ()
  "Prompt the user to select a status label."
  (let ((label (completing-read "TODO status? " (mapcar #'downcase tlon-babel-todo-statuses) nil t)))
    label))

(defun tlon-babel-set-assignee (assignee &optional issue)
  "Make ASSIGNEE the assignee of ISSUE.
If ISSUE is nil, use issue at point or in the current buffer."
  (interactive
   (list (tlon-babel-select-assignee)))
  (let ((issue (or issue (forge-get-topic (forge-current-topic)))))
    (tlon-babel-set-properies assignee 'assignee issue)))

(defun tlon-babel-select-assignee ()
  "Prompt the user to select an ASSIGNEE.
The prompt defaults to the current user."
  (let ((assignee (completing-read "Who should be the assignee? "
				   (tlon-babel-user-lookup-all :github) nil nil
				   (tlon-babel-user-lookup :github :name user-full-name))))
    assignee))

(defun tlon-babel-set-initial-label-and-assignee ()
  "Set label to `Awaiting processing' and assignee to current user."
  (tlon-babel-set-labels '("Awaiting processing"))
  (tlon-babel-set-assignee `(,(tlon-babel-user-lookup :github :name user-full-name))))

(defun tlon-babel-get-element (element &optional issue)
  "Return ELEMENT of ISSUE.
If ISSUE is nil, use the issue at point or in the current buffer."
  (when-let ((issue (or issue (forge-current-topic))))
    (closql--iref issue element)))

(defun tlon-babel-get-first-element (element &optional issue)
  "Return first ELEMENT of ISSUE.
If the issue has more than one element, return the first. If ISSUE is nil, use
the issue at point or in the current buffer."
  (when-let ((issue (or issue (forge-current-topic))))
    (caar (closql--iref issue element))))

(defun tlon-babel-get-assignee (&optional issue)
  "Return the assignee of the current ISSUE.
If the issue has more than one assignee, return the first. If ISSUE is nil, use
the issue at point or in the current buffer."
  (tlon-babel-get-first-element 'assignees issue))

(defun tlon-babel-get-status-in-labels (labels)
  "Return the status in LABELS.
A label is considered a status if it exists in `tlon-babel-todo-statuses'.
The status is returned in UPPERCASE."
  (catch 'found
    (dolist (element labels)
      (let ((label (car element)))
	(when (member (upcase label) tlon-babel-todo-statuses)
	  (throw 'found (upcase label)))))))

(defun tlon-babel-get-tags-in-labels (labels)
  "Return the tag(s) in LABELS.
A label is considered a tag if it is not a status and it exists in
`tlon-babel-todo-tags'."
  (let (tags)
    (dolist (element labels tags)
      (let ((tag (car element)))
	(when (and (member tag tlon-babel-todo-tags)
		   (not (member (upcase tag) tlon-babel-todo-statuses)))
	  (push tag tags))))))

;; TODO: should return all labels, not just first
(defun tlon-babel-get-first-label (&optional issue)
  "Return the first label of the issue at point.
If ISSUE is nil, use the issue at point or in the current buffer."
  (tlon-babel-get-first-element 'labels issue))

(defun tlon-babel-get-state (&optional issue)
  "Return state of ISSUE.
If ISSUE is nil, use the issue at point or in the current buffer."
  (when-let ((issue (or issue (forge-current-topic))))
    (oref (forge-current-topic) state)))

;;;;; ?

(defun tlon-babel-get-issue-name (&optional issue)
  "Get the name of ISSUE.
An issue name is its number followed by its title.

If ISSUE is nil, get the issue at point or in current buffer."
  (let* ((issue (or issue (forge-current-topic)))
	 (title (oref issue title))
	 (number (oref issue number)))
    (format "#%s %s" number title)))

(defun tlon-babel-get-issue-link (&optional issue)
  "Get an `org-mode' link to ISSUE.
If ISSUE is nil, get the issue at point or in current buffer."
  (let* ((issue (or issue (forge-current-topic)))
	 (name (tlon-babel-get-issue-name issue))
	 (id (oref issue id)))
    (org-link-make-string (format "orgit-topic:%s" id) name)))

(defun tlon-babel-make-todo-name-from-issue (&optional no-action no-status issue)
  "Construct the name of TODO from ISSUE.
For job TODOs, the resulting name will have a name with the form \"[REPO] ACTION
NAME\". ACTION is optional, and used only for job TODOs. For example, if the
TODO is \"[uqbar-es] #591 Job: `Handbook2022ExerciseForRadical`\", and ACTION is
\"Process\", the function returns \"[uqbar-es] Process #591 Job:
`Handbook2022ExerciseForRadical`\".

If NO-ACTION is non-nil, omit, the ACTION element. If NO-STATUS is non-nil, omit
the STATUS element. If ISSUE is nil, use the issue at point or in the current
buffer."
  (let* ((issue (or issue (forge-current-topic)))
	 (action (if (and (tlon-babel-issue-is-job-p issue)
			  (not no-action))
		     (or (tlon-babel-label-lookup :action :label (tlon-babel-get-first-label issue))
			 "")
		   ""))
	 (status (if (tlon-babel-issue-is-job-p issue)
		     "TODO"
		   (tlon-babel-get-status-in-issue issue)))
	 (tags (tlon-babel-get-tags-in-issue issue))
	 (repo-abbrev (tlon-babel-repo-lookup :abbrev :dir (tlon-babel-get-repo 'error 'include-all)))
	 (todo-name (replace-regexp-in-string
		     "[[:space:]]\\{2,\\}"
		     " "
		     (concat
		      (unless no-status (format "%s " status))
		      (format "[%s] %s %s" repo-abbrev action (tlon-babel-get-issue-link issue))
		      (when tags (format "   :%s:" (mapconcat #'identity tags ":")))))))
    todo-name))

(defun tlon-babel-get-file-from-issue (&optional issue)
  "Get the file path of ISSUE.
If ISSUE is nil, use the issue at point or in current buffer."
  (let* ((issue (or issue (forge-current-topic)))
	 (name (tlon-babel-get-issue-name issue)))
    (if (string-match tlon-babel-key-regexp name)
	(tlon-babel-get-file-from-key (match-string 1 name))
      (user-error "I wasn't able to find a file at point or in the forge buffer"))))

;;;###autoload
(defun tlon-babel-open-forge-file ()
  "Open the file of the issue at point or in the current buffer."
  (interactive)
  (find-file (tlon-babel-get-file-from-issue)))

;;;###autoload
(defun tlon-babel-open-forge-counterpart ()
  "Open the file counterpart of the issue at point or in the current buffer."
  (interactive)
  (tlon-babel-open-counterpart nil (tlon-babel-get-file-from-issue)))

;;;;

(defun tlon-babel-create-issue (title &optional repo body)
  "Create new GitHub issue in REPO with TITLE and BODY."
  (let* ((repo (or repo (tlon-babel-get-repo 'error 'include-all)))
	 (body (or body ""))
	 (default-directory repo)
	 (repo (forge-get-repository t))
	 (owner (oref repo owner))
	 (reponame (oref repo name))
	 (resource (format "/repos/%s/%s/issues" owner reponame))
	 (data `(("title" . ,title)
		 ("body" . ,body))))
    (ghub-post resource data
	       :auth 'forge
	       :noerror t ;; avoid showing the original large output
	       :reader 'ignore) ;; do not parse the response json
    (message "Created issue with title %s" title)))

;;;###autoload
(defun tlon-babel-create-issue-from-todo ()
  "Create a new GitHub issue based on the current `org-mode' heading."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "You need to be in `org-mode' to use this function"))
  (when (tlon-babel-get-issue-number-from-heading)
    (user-error "This heading already has an issue"))
  (unless (tlon-babel-is-valid-status-p)
    (user-error "Invalid TODO status"))
  (unless (tlon-babel-get-repo-from-heading)
    (tlon-babel-set-repo-in-heading))
  (let (todo-linkified)
    (save-excursion
      (let* ((default-directory (tlon-babel-get-repo-from-heading))
	     (heading (substring-no-properties (org-get-heading t t t t)))
	     (status (tlon-babel-get-status-in-todo))
	     (tags (tlon-babel-get-tags-in-todo))
	     (abbrev-repo (tlon-babel-repo-lookup :abbrev :dir default-directory))
	     (issue-title (substring heading (+ (length abbrev-repo) 3)))
	     (latest-issue-pre (car (tlon-babel-get-latest-issue)))
	     (latest-issue-post latest-issue-pre))
	(tlon-babel-create-issue issue-title default-directory)
	;; TODO: consider replacing this with `tlon-babel-create-and-visit-issue'
	(forge-pull)
	(message (concat "Reflect on this fine proverb while you wait: " (tlon-core-proverb)))
	(while (eq latest-issue-pre latest-issue-post)
	  (sleep-for 0.1)
	  (setq latest-issue-post (car (tlon-babel-get-latest-issue))))
	(tlon-babel-set-issue-number-in-heading latest-issue-post)
	(tlon-babel-visit-issue)
	(tlon-babel-set-assignee `(,(tlon-babel-user-lookup :github :name user-full-name)))
	(tlon-babel-set-labels (append (list status) tags)))
      (setq todo-linkified (tlon-babel-make-todo-name-from-issue nil 'no-status)))
    (org-edit-headline todo-linkified)))

(defun tlon-babel-create-issue-or-todo ()
  "Create issue from TODO or vice versa."
  (interactive)
  (tlon-babel-todo-issue-funcall #'tlon-babel-create-issue-from-todo
				 #'tlon-babel-capture-issue))

(defun tlon-babel-create-issue-from-key (&optional key)
  "Create an issue based on KEY.
If KEY is not provided, the key in the Markdown buffer at point is used."
  (let ((default-directory (tlon-babel-get-repo 'error))
	(key (or key (tlon-babel-get-key-in-buffer))))
    (tlon-babel-create-issue (format "Job: `%s`" key) default-directory)))

(defun tlon-babel-issue-lookup (string &optional dir)
  "Return the first issue in DIR whose title includes STRING.
If DIR is nil, use the current repository."
  (let* ((string (concat "%" string "%"))
	 (default-directory (or dir default-directory))
	 (repo (forge-get-repository t))
	 (issue-id (caar (emacsql (forge-db)
				  [:select [number]
					   :from 'issue
					   :where (and (= repository $s1)
						       (like title $s2))]
				  (oref repo id)
				  string))))
    (when issue-id
      (forge-get-issue repo issue-id))))

(defun tlon-babel-close-issue (&optional issue)
  "Close ISSUE.
If ISSUE is nil, use the issue at point or in the current buffer."
  (let* ((issue (or issue (forge-current-topic)))
	 (repo (forge-get-repository issue)))
    (when (eq 'open (oref issue state))
      (forge--set-topic-state repo issue 'closed))))

(defun tlon-babel-get-parent-todo (todo)
  "Get parent of TODO in `tlon-babel-todos-jobs-file'."
  (let ((pos (tlon-babel-get-todo-position todo (tlon-babel-get-todos-jobs-file))))
    (save-window-excursion
      (tlon-babel-visit-todo pos (tlon-babel-get-todos-jobs-file))
      (widen)
      (org-up-heading-safe)
      (org-no-properties (org-get-heading)))))

(defun tlon-babel-mark-todo-done (todo file)
  "Mark TODO in FILE as DONE."
  (let ((pos (tlon-babel-get-todo-position todo file)))
    (save-window-excursion
      (tlon-babel-visit-todo pos file)
      (org-todo "DONE")
      (save-buffer)
      (message "Marked `%s' as DONE" todo))))

;; MAYBE: move to jobs?
(defun tlon-babel-check-label-and-assignee (repo)
  "Check that clocked action, user match label, assignee of issue in REPO."
  (save-window-excursion
    (let* ((default-directory repo)
	   (key (tlon-babel-get-clock-key))
	   (issue (format "Job: `%s" key))
	   (clocked-label (tlon-babel-get-clock-label)))
      (magit-status-setup-buffer repo)
      (magit-section-show-level-3-all)
      (goto-char (point-min))
      (if (search-forward issue nil t)
	  (let ((label (tlon-babel-get-first-label))
		(assignee (tlon-babel-user-lookup :name :github (tlon-babel-get-assignee))))
	    (unless (string= clocked-label label)
	      (user-error "The `org-mode' TODO says the label is `%s', but the actual issue label is `%s'"
			  clocked-label label))
	    (unless (string= user-full-name assignee)
	      (user-error "The `org-mode' TODO says the assignee is `%s', but the actual issue assignee is `%s'"
			  user-full-name assignee))
	    t)
	(user-error "No issue found for %s" key)))))

;;;;; Meetings

(defun tlon-babel-create-or-visit-meeting-issue (person date)
  "Create or visit issue for a meeting with PERSON on DATE."
  (interactive (list (tlon-babel-prompt-for-all-other-users)
		     (org-read-date)))
  (let* ((dir (tlon-babel-get-meeting-repo person user-full-name)))
    (if-let ((issue (tlon-babel-issue-lookup date dir)))
	(forge-visit-issue issue)
      (tlon-babel-create-and-visit-issue date dir))))

;; TODO: generate the next three functions with macro
(defun tlon-babel-create-or-visit-meeting-issue-leo-pablo ()
  "Create or visit issue for a meeting with Leo and Pablo."
  (interactive)
  (let ((person (pcase user-full-name
		  ("Pablo Stafforini" "Leonardo Picón")
		  ("Leonardo Picón" "Pablo Stafforini")
		  (_ (user-error "This command is only for Leo and Pablo meetings")))))
    (tlon-babel-create-or-visit-meeting-issue person (org-read-date))))

(defun tlon-babel-create-or-visit-meeting-issue-fede-pablo ()
  "Create or visit issue for a meeting with Fede and Pablo."
  (interactive)
  (let ((person (pcase user-full-name
		  ("Pablo Stafforini" "Federico Stafforini")
		  ("Federico Stafforini" "Pablo Stafforini")
		  (_ (user-error "This command is only for Fede and Pablo meetings")))))
    (tlon-babel-create-or-visit-meeting-issue person (org-read-date))))

(defun tlon-babel-create-or-visit-meeting-issue-fede-leo ()
  "Create or visit issue for a meeting with Fede and Leo."
  (interactive)
  (let ((person (pcase user-full-name
		  ("Federico Stafforini" "Leonardo Picón")
		  ("Leonardo Picón" "Federico Stafforini")
		  (_ (user-error "This command is only for Leo and Fede meetings")))))
    (tlon-babel-create-or-visit-meeting-issue person (org-read-date))))

(defun tlon-babel-prompt-for-all-other-users ()
  "Ask the user to select from a list of all users except himself."
  (completing-read "Person: "
		   (cl-remove-if (lambda (user)
				   (string= user user-full-name))
				 (tlon-babel-user-lookup-all :name))))

;; TODO: create `tlon-babel-issue-lookup-all', analogous to `tlon-babel-lookup-all'
(defun tlon-babel-get-meeting-repo (participant1 participant2)
  "Get directory of meeting repo for PARTICIPANT1 and PARTICIPANT2."
  (catch 'found
    (dolist (repo tlon-babel-repos)
      (when (and
	     (eq 'meetings (plist-get repo :subtype))
	     (member participant1 (plist-get repo :participants))
	     (member participant2 (plist-get repo :participants)))
	(throw 'found (plist-get repo :dir))))))

(defun tlon-babel-create-and-visit-issue (title dir)
  "Create an issue with TITLE in DIR and visit it."
  (with-temp-buffer
    (cd dir)
    (when (forge-current-repository 'full)
      (tlon-babel-create-issue title dir)
      (forge-pull)
      (message (concat "Reflect on this fine proverb while you wait: " (tlon-core-proverb)))
      (while (not (tlon-babel-issue-lookup title dir))
	(sleep-for 0.1))
      (forge-visit-issue (tlon-babel-issue-lookup title dir)))))

(provide 'tlon-babel-org-ghub)
;;; tlon-babel-org-ghub.el ends here