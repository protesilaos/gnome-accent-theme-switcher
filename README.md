# GNOME accent color switcher for GNU Emacs

This is a small package that provides the minor mode
`gnome-accent-color-switcher-mode`. Once enabled, this mode receives
input from the GNOME desktop environment to update the Emacs theme
based on the user's choice of accent color and light/dark mode. Those
are settings provided by the GNOME desktop environment.

The user option `gnome-accent-color-theme-switcher-collection` defines
the list of themes that are used for each accent color, grouped by
light and dark mode. By default, almost all of my themes are included,
spanning the packages `modus-themes`, `ef-themes`, `doric-themes`, and
`standard-themes`.

```elisp
(use-package gnome-accent-color-theme-switcher
  :init
  (unless (package-installed-p 'gnome-accent-color-theme-switcher)
    (package-vc-install "https://github.com/protesilaos/gnome-accent-color-theme-switcher.git"))
  :config
  (gnome-accent-color-theme-switcher-mode 1))
```
