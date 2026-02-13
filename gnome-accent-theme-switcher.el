;;; gnome-accent-theme-switcher.el --- Automatically load theme to match the GNOME accent and light -*- lexical-binding: t -*-

;; Copyright (C) 2026  Protesilaos Stavrou

;; Author: Protesilaos Stavrou <info@protesilaos.com>
;; Maintainer: Protesilaos Stavrou <info@protesilaos.com>
;; URL: https://github.com/protesilaos/gnome-accent-theme-switcher
;; Version: 0.0.0
;; Package-Requires: ((emacs "29.1") (modus-themes "5.2.0") (ef-themes "2.1.0") (doric-themes "1.0.0") (standard-themes "3.0.0"))
;; Keywords: convenience, faces, theme

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This is a small package that provides the minor mode
;; `gnome-accent-theme-switcher-mode'.  Once enabled, this mode
;; receives input from the GNOME desktop environment to update the
;; Emacs theme based on the user's choice of accent color and
;; light/dark mode.  Those are settings provided by the GNOME desktop
;; environment.
;;
;; The user option `gnome-accent-theme-switcher-collection' defines
;; the list of themes that are used for each accent color, grouped by
;; light and dark mode.  By default, almost all of my themes are
;; included, spanning the packages `modus-themes', `ef-themes',
;; `doric-themes', and `standard-themes'.
;;
;; The command `gnome-accent-theme-switcher-toggle-mode' toggles the
;; GNOME light/dark preference from inside Emacs.  While the command
;; `gnome-accent-theme-switcher-change-accent' prompts for an accent
;; color and changes it accordingly.

;;; Code:

(require 'dbus)

(defgroup gnome-accent-theme-switcher-themes nil
  "Automatically load theme to match the GNOME accent and light."
  :group 'faces
  :group 'modus-themes
  :group 'ef-themes
  :group 'doric-themes
  :group 'standard-themes)

(defconst gnome-accent-theme-switcher-colors
  '("blue" "teal" "green" "yellow" "orange" "red" "pink" "purple" "slate")
  "Names of accent colors used by the GNOME desktop environment.")

(defcustom gnome-accent-theme-switcher-collection
  '(("blue"
     :light (ef-maris-light ef-deuteranopia-light)
     :dark  (ef-night ef-deuteranopia-dark ef-dark ef-duo-dark doric-mermaid standard-dark-tinted))
    ("teal"
     :light (ef-spring ef-frost doric-wind doric-jade)
     :dark  (ef-maris-dark doric-valley))
    ("green"
     :light (ef-cyprus ef-elea-light doric-oak)
     :dark  (ef-bio ef-elea-dark ef-symbiosis doric-pine))
    ("yellow"
     :light (ef-melissa-light ef-duo-light ef-eagle doric-earth)
     :dark  (ef-melissa-dark))
    ("orange"
     :light (ef-orange ef-day doric-beach)
     :dark  (ef-autumn doric-copper))
    ("red"
     :light (modus-operandi-tinted standard-light-tinted ef-tritanopia-light ef-arbutus)
     :dark  (ef-tritanopia-dark doric-fire))
    ("pink"
     :light (ef-summer ef-reverie doric-cherry ef-kassio)
     :dark  (ef-cherie ef-rosa))
    ("purple"
     :light (ef-trio-light ef-light doric-siren)
     :dark  (ef-trio-dark ef-winter ef-fig ef-dream doric-plum))
    ("slate"
     :light (doric-marble doric-light)
     :dark  (ef-owl doric-obsidian doric-water doric-dark)))
  "Collection of themes grouped by accent color and by light or dark mode.
This is an alist where each element is of the following form:

    (ACCENT :light (THEMES) :dark (THEMES))

ACCENT is a string among `gnome-accent-theme-switcher-colors', while
THEMES are one or more symbols of themes."
  :type `(alist
          :key-type (choice ,@(mapcar
                               (lambda (accent)
                                 (list 'string :tag accent accent))
                               gnome-accent-theme-switcher-colors))
          ;; TODO 2026-02-13: Maybe we should provide a list
          ;; here.  In all of my themes there are functions to
          ;; get themes based on their light/dark mode.  That is
          ;; already a good place to start.
          :value-type (plist :keys ( :light (repeat 'symbol)
                                     :dark (repeat 'symbol)))))

(defun gnome-accent-theme-switcher--get-gsettings (key)
  "Return KEY of gsettings org.gnome.desktop.interface namespace."
  (unless (executable-find "gsettings")
    (error "The `gsettings' program is not available"))
  (unless (member key '("accent-color" "color-scheme"))
    (error "The key `%S' is not `%S' or `%S'" key "accent-color" "color-scheme"))
  (shell-command-to-string (format "gsettings get org.gnome.desktop.interface %s" key)))

(defun gnome-accent-theme-switcher--set-gsettings (key value)
  "Set KEY of gsettings org.gnome.desktop.interface namespace to VALUE."
  (unless (executable-find "gsettings")
    (error "The `gsettings' program is not available"))
  (unless (member key '("accent-color" "color-scheme"))
    (error "The key `%S' is not `%S' or `%S'" key "accent-color" "color-scheme"))
  (call-process "gsettings" nil 0 nil "set" "org.gnome.desktop.interface" key value))

(defun gnome-accent-theme-switcher-gnome--get-accent-color-string (accent)
  "Return the string that corresponds to GNOME's ACCENT color."
  (seq-find
   (lambda (color)
     (string-match-p color accent))
   gnome-accent-theme-switcher-colors))

(defun gnome-accent-theme-switcher--dark-p ()
  "Return non-nil if GNOME has a dark theme preference."
  (and-let* ((preference (gnome-accent-theme-switcher--get-gsettings "color-scheme"))
             (_ (string-match-p "dark" preference)))))

(defun gnome-accent-theme-switcher--get-themes ()
  "Return list of themes based on accent and light/dark color scheme."
  (when-let* ((accent (gnome-accent-theme-switcher--get-gsettings "accent-color"))
              (accent-color (gnome-accent-theme-switcher-gnome--get-accent-color-string accent))
              (subset (alist-get accent-color gnome-accent-theme-switcher-collection nil nil #'string=))
              (light-or-dark (if (gnome-accent-theme-switcher--dark-p) :dark :light))
              (themes (plist-get subset light-or-dark)))
    themes))

(defun gnome-accent-theme-switcher-load-random-theme (themes)
  "Load a random theme from THEMES.
Disable all other themes before loading the new one."
  (let ((theme (seq-random-elt themes)))
    (mapc #'disable-theme custom-enabled-themes)
    (cond
     ((and (fboundp 'modus-themes--modus-theme-p)
           (modus-themes--modus-theme-p theme))
      (if (fboundp 'modus-themes-load-theme)
          (modus-themes-load-theme theme)
        (load-theme theme :no-confirm)))
     ((and (bound-and-true-p doric-themes-collection)
           (memq theme doric-themes-collection))
      (if (fboundp 'doric-themes-load-theme)
          (doric-themes-load-theme theme)
        (load-theme theme :no-confirm)))
     (t
      (load-theme theme :no-confirm)))))

(defun gnome-accent-theme-switcher-load-theme ()
  "Load a theme based on GNOME settings."
  (when-let* ((themes (gnome-accent-theme-switcher--get-themes)))
    (gnome-accent-theme-switcher-load-random-theme themes)))

(defvar gnome-accent-theme-switcher--dbus-object nil
  "DBus object for GNOME accent color changes.")

(defun gnome-accent-theme-switcher-gnome-accent-color-changed-handler (namespace key _value)
  "Handle D-Bus signal for accent color change.
NAMESPACE is the gsettings path as a string.  KEY is the specific domain
as a string.  VALUE is what corresponds to KEY, as a list of strings."
  (when (and (string= namespace "org.gnome.desktop.interface")
             (or (string= key "accent-color")
                 (string= key "color-scheme")))
    (gnome-accent-theme-switcher-load-theme)))

;;;###autoload
(define-minor-mode gnome-accent-theme-switcher-mode
  "Toggle syncing of a theme with the GNOME accent color and color scheme."
  :global t
  :init-value nil
  (require 'dbus)
  (if gnome-accent-theme-switcher-mode
      (progn
        (when (and (fboundp 'dbus-register-signal)
                   (null gnome-accent-theme-switcher--dbus-object))
          (setq gnome-accent-theme-switcher--dbus-object
                (dbus-register-signal
                 :session
                 "org.freedesktop.portal.Desktop"
                 "/org/freedesktop/portal/desktop"
                 "org.freedesktop.portal.Settings"
                 "SettingChanged"
                 #'gnome-accent-theme-switcher-gnome-accent-color-changed-handler))
          (gnome-accent-theme-switcher-load-theme)))
    (when gnome-accent-theme-switcher--dbus-object
      (dbus-unregister-object gnome-accent-theme-switcher--dbus-object)
      (setq gnome-accent-theme-switcher--dbus-object nil))))

;;;###autoload
(defun gnome-accent-theme-switcher-toggle-mode ()
  "Toggle the GNOME preference for light or dark themes."
  (interactive)
  (if (gnome-accent-theme-switcher--dark-p)
      (gnome-accent-theme-switcher--set-gsettings "color-scheme" "'prefer-light'")
    (gnome-accent-theme-switcher--set-gsettings "color-scheme" "'prefer-dark'")))

(defun gnome-accent-theme-switcher-get-completion-table (candidates &rest metadata)
  "Return completion table with CANDIDATES and METADATA.
CANDIDATES is a list of strings.  METADATA is described in
`completion-metadata'."
  (lambda (string pred action)
    (if (eq action 'metadata)
        (cons 'metadata metadata)
      (complete-with-action action candidates string pred))))

(defun gnome-accent-theme-switcher-annotate (accent)
  "Annotate ACCENT color with its corresponding themes."
  (when-let* ((subset (alist-get accent gnome-accent-theme-switcher-collection nil nil #'string=))
              (light-or-dark (if (gnome-accent-theme-switcher--dark-p) :dark :light))
              (themes (plist-get subset light-or-dark)))
    (format " -- %s" (propertize (format "%S" themes) 'face 'completions-annotations))))

(defvar gnome-accent-theme-switcher-color-prompt-history nil
  "Minibuffer history for `gnome-accent-theme-switcher-color-prompt'.")

(defun gnome-accent-theme-switcher-color-prompt ()
  "Select color among `gnome-accent-theme-switcher-colors'."
  (let ((default (car gnome-accent-theme-switcher-color-prompt-history)))
    (completing-read
     (format-prompt "Select GNOME accent color" default)
     (gnome-accent-theme-switcher-get-completion-table
      gnome-accent-theme-switcher-colors
      '(category . gnome-accent-color)
      '(annotation-function . gnome-accent-theme-switcher-annotate))
     nil t nil 'gnome-accent-theme-switcher-color-prompt-history default)))

;;;###autoload
(defun gnome-accent-theme-switcher-change-accent (accent)
  "Change the current GNOME color preference to ACCENT.
When called interactively, prompt for ACCENT.  When called from Lisp,
ACCENT is a string that is a member of `gnome-accent-theme-switcher-colors'."
  (interactive (list (gnome-accent-theme-switcher-color-prompt)))
  (unless (member accent gnome-accent-theme-switcher-colors)
    (error "The accent `%S' is not a member of `gnome-accent-theme-switcher-colors'" accent))
  (gnome-accent-theme-switcher--set-gsettings "accent-color" accent))

(provide 'gnome-accent-theme-switcher)
;;; gnome-accent-theme-switcher.el ends here
