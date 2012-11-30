(setq inhibit-splash-screen t)

;; el-get インストール後のロードパスの用意
(add-to-list 'load-path "~/.emacs.d/el-get/el-get")
;; もし el-get がなければインストールを行う
(unless (require 'el-get nil t)
  (url-retrieve
   "https://github.com/dimitri/el-get/raw/master/el-get-install.el"
   (lambda (s)
     (let (el-get-master-branch)
       (end-of-buffer)
       (eval-print-last-sexp)))))
(require 'el-get)

(defmacro set-path (list-var list)
  (list 'mapc `(lambda (x)
		 (when (file-accessible-directory-p x)
		   (add-to-list ',list-var x)))
	list))

(set-path load-path
	  (list
	   "~/.emacs.d/el-get/haskell-mode/"
	   "~/Library/Haskell/ghc-7.4.2/lib/ghc-mod-1.11.2/share/"
	   "~/.emacs.d/el-get/ghc-mod/"
	   "~/.emacs.d/el-get/ghc-mod/elisp/"
	   ))

(require 'haskell-mode)
(add-to-list 'auto-mode-alist '("\\.[hg]s$" . haskell-mode))
(custom-set-variables
 '(haskell-mode-hook '(turn-on-haskell-indentation)))

;; ghc-mod のHook
(autoload 'ghc-init "ghc" nil t)
(add-hook 'haskell-mode-hook (lambda () (ghc-init) (flymake-mode)))
