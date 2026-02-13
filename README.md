# GNOME accent theme switcher for GNU Emacs

VIDEO DEMO: <https://protesilaos.com/codelog/2026-02-13-emacs-gnome-accent-theme-switcher/>.

* * *

This is a small package that provides the minor mode
`gnome-accent-theme-switcher-mode`. Once enabled, this mode receives
input from the GNOME desktop environment to update the Emacs theme
based on the user's choice of accent color and light/dark mode. Those
are settings provided by the GNOME desktop environment.

The user option `gnome-accent-theme-switcher-collection` defines
the list of themes that are used for each accent color, grouped by
light and dark mode. By default, almost all of my themes are included,
spanning the packages `modus-themes`, `ef-themes`, `doric-themes`, and
`standard-themes`.

The command `gnome-accent-theme-switcher-toggle-mode` toggles the
GNOME light/dark preference from inside Emacs. While the command
`gnome-accent-theme-switcher-change-accent` prompts for an accent
color and changes it accordingly.

```elisp
(use-package gnome-accent-theme-switcher
  :demand t
  :init
  ;; Then upgrade it with the command `package-vc-upgrade' or `package-vc-upgrade-all'.
  (unless (package-installed-p 'gnome-accent-theme-switcher)
    (package-vc-install "https://github.com/protesilaos/gnome-accent-theme-switcher.git"))
  :bind
  (("<f5>" . gnome-accent-theme-switcher-toggle-mode)
   ("C-<f5>" . gnome-accent-theme-switcher-change-accent))
  :config
  (gnome-accent-theme-switcher-mode 1))
```
