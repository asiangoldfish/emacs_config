;;;; Configuration from https://protesilaos.com/codelog/2024-11-28-basic-emacs-configuration/
(message "Loaded init file: %s" user-init-file)
(message "Emacs config dir: %s" user-emacs-directory)

;; Auto generated configurations by the UI
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;;; Global settings
(global-display-line-numbers-mode)

;;; Global keybinds
(global-set-key (kbd "C-z") 'undo-only)
(global-set-key (kbd "C-S-z") 'undo-redo)

;;; Add third-party package manager
(require 'package)
(package-initialize)

(add-to-list 'package-archives
	     ;; '("melpa" . "https://melpa.org/packages")
	     '("melpa" . "https://mirrorservice.org/sites/melpa.org/packages/")
	     )

;; If using Emacs prior to version 29
(when (< emacs-major-version 29)
  (unless (package-installed-p 'use-package)
    (unless package-archive-contents
      (package-refresh-contents))
    (package-install 'use-package)))

;; Hide useless package installation errors for users
(add-to-list 'display-buffer-alist
	     '("\\`\\*\\(Warnings\\|Compile-Log\\)\\*\\'"
	       (display-buffer-no-window)
	       (allow-no-window . t)))

;; Delete thee select text upon text insertion
(use-package delsel
  :ensure nil ; no need to install it as it is built-in
  :hook (after-init . delete-selection-mode))

(defun prot/keyboard-quit-dwin ()
  "Do-What-I-Mean behaviour for a general `keyboard-quit'.
The generic `keyboard-quit' does not do the expected thing when the minibuffer is open. whereas,
we want it to close the minibuffer, even without explicitly focusing it.


The DWIN behaviour of this command is as follows:

- When the region is active, disable it
- When the minibuffer is open, but not focused, close the minibuffer.
- When the Completions buffer is selected, close it.
- In every other case use the regualr `keyboard-quit'."
  (interactive)
  (cond
   ((region-active-p)
    (keyboard-quit))
   ((derived-mode-p 'completion-list-mode)
    (delete-completion-window))
   ((> (minibuffer-depth) 0)
    (abort-recursive-edit))
   (t
    (keyboard-quit))))

(define-key global-map (kbd "C-g") #'prot/keyboard-quit-dwin)

;; Tweak the menu and tool bars visibility
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;; Configure fonts
(let ((mono-spaced-font "Monospace")
      (proportionately-spaced-font "Sans"))
  (set-face-attribute 'default nil :family mono-spaced-font :height 120)
  (set-face-attribute 'fixed-pitch nil :family mono-spaced-font :height 1.0)
  (set-face-attribute 'variable-pitch nil :family proportionately-spaced-font :height 1.0))

;; Configure theme. Apparently, many people prefer this.
(use-package modus-themes
  :ensure t
  :config
  (load-theme 'modus-vivendi-tinted :no-confirm-loading))

;; Configure icon fonts
;; To make this work, the user must press M-x and call 'nerd-icons-install-fonts'
(use-package nerd-icons
  :ensure t)

(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :config
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package nerd-icons-corfu
  :ensure t
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package nerd-icons-dired
  :ensure t
  :hook
  (dired-mode . nerd-icons-dired-mode))

;; Because I am a noob, produce a vertical layout for the minibuffer
(use-package vertico
  :ensure t
  :hook (after-init . vertico-mode))

;; Add some more context to the minibuffer
(use-package marginalia
  :ensure t
  :hook (after-init . marginalia-mode))

;; Orderless: help the noob with entering hard-to-remember commands
(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic))
  (setq completion-category-defaults nil)
  (setq completion-category-overrides nil))

;; Save commands history
(use-package savehist
  :ensure nil ; built-in functionality
  :hook (after-init . savehist-mode))

;; Popup interface for in-buffer completion. Typically used for LSP autocompletion
(use-package corfu
  :ensure t
  :hook (after-init . global-corfu-mode)
  :bind (:map corfu-map ("<tab>" . corfu-complete))
  :config
  (setq tab-always-indent 'complete)
  (setq corfu-preview-current nil)
  (setq corfu-min-width 20)

  (setq corfu-popupinfo-delay '(1.25 . 0.5))
  (corfu-popupinfo-mode -1) ; shows documentation after `corfu-popupinfo-delay'

  ;; Sort by input history (no need to modify `corfu-sort-function')
  (with-eval-after-load 'savehist
    (corfu-history-mode 1)
    (add-to-list 'savehist-additional-variables 'corfu-history)))

;; Configure the dired Emacs file manager
;; Add operations for copying, renaming and deleting files.
;;
;; More details in dired can be toggled with M-x dired-hide-details-mode. Bound
;; to ( key in dired buffers.
(use-package dired
  :ensure nil
  :commands (dired)
  :init
  ;; Set dired default location to open as $HOME
  (setq-default default-directory "~/")
  :hook
  ((dired-mode . dired-hide-details-mode)
   (dired-mode . hl-line-mode))
  :config
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq delete-by-moving-to-trash t)
  (setq dired-dwin-target t))

;;; View contents of a folder by pressing the TAB key
(use-package dired-subtree
  :ensure t
  :after dired
  :bind
  ( :map dired-mode-map
    ("<tab>" . dired-subtree-toggle)
    ("TAB" . dired-subtree-toggle)
    ("<backtab>" . dired-subtree-remove)
    ("S-TAB" . dired-subtree-remove))
  :config
  (setq dired-subtree-use-backgrounds nil))


;;; Useful package to provide a Dired-like interface for this compartment
(use-package trashed
  :ensure t
  :commands (trashed)
  :config
  (setq trashed-action-confirmer 'y-or-n-p)
  (setq trashed-use-header-line t)
  (setq trashed-sort-key '("Date deleted" . t))
  (setq trashed-date-format "Y%-%m-%d %H:%M:%S"))

;;; Disable splash screen
(setq inhibit-splash-screen t)

;;; Enable transient mark-mode
(transient-mark-mode 1)

(defun dw/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (auto-fill-mode 0)
  (visual-line-mode 1)
  (setq evil-auto-indent nil))

(use-package org
  :ensure nil
  :hook
  (org-mode . dw/org-mode-setup)
  ;(org-mode . font-lock-mode)

  :custom
  (org-ellipsis " ▾")
  (org-hide-emphasis-markers t)
  (org-startup-indented t)
  (org-src-fontify-natively t)
  (org-fontify-quote-and-verse-blocks t)
  (org-pretty-entities t)

  :config
  ;; Replace list hyphen with dot
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  (dolist (face '((org-level-1 . 1.35)
                  (org-level-2 . 1.25)
                  (org-level-3 . 1.15)
                  (org-level-4 . 1.10)
                  (org-level-5 . 1.05)
                  (org-level-6 . 1.05)
                  (org-level-7 . 1.05)
                  (org-level-8 . 1.05)))
    (set-face-attribute (car face) nil
			:family "Cantarell"
			:weight 'bold
			:height (cdr face)))
  ;; Make sure org-indent face is available
  (require 'org-indent)

  ;; Fixed-pitch elements
  (with-eval-after-load 'org
    (set-face-attribute 'org-block nil
			:inherit 'fixed-pitch)
    (set-face-attribute 'org-block-begin-line nil
			:inherit '(fixed-pitch font-lock-comment-face))
    (set-face-attribute 'org-block-end-line nil
			:inherit '(fixed-pitch font-lock-comment-face))
    (set-face-attribute 'org-code nil
			:inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-table nil
			:inherit 'fixed-pitch)
    (set-face-attribute 'org-verbatim nil
			:inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-meta-line nil
			:inherit '(font-lock-comment-face fixed-pitch))
    (set-face-attribute 'org-special-keyword nil
			:inherit '(font-lock-comment-face fixed-pitch))
    (set-face-attribute 'org-checkbox nil
			:inherit 'fixed-pitch)
    (set-face-attribute 'org-indent nil
			:inherit '(org-hide fixed-pitch))))


;;; Org-mode appearance
(use-package org-appear
  :hook
  ;; When hovering the cursor over a word, reveal hidden symbols
  (org-mode . org-appear-mode))

(use-package org-bullets
  :ensure t
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

;;; Dashboard: create a nice interface on opening the Emacs client
(use-package dashboard
  :ensure t
  :config
  ;; Use built-in project.el instead of Projectile
  (setq dashboard-projects-backend 'project-el)

  ;; Customize what sections appear and how many items to show
  (setq dashboard-items '((projects . 8)
                          (recents  . 5)
                          (bookmarks . 5)))

  ;; Visual polish
  (setq dashboard-startup-banner 'logo) ;; Use 'official, 'logo, or path to a custom PNG
  (setq dashboard-center-content t)
  (setq dashboard-show-shortcuts t)

  ;; Ensure every new emacsclient frame opens to a refreshed dashboard
  (setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name)))
  (add-hook 'server-after-make-frame-hook #'dashboard-refresh-buffer)

  (dashboard-setup-startup-hook))
