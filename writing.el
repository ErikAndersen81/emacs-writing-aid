(defvar site-url)
(defvar m1)
(defvar m2)

(defun find-synonyms ()
  "Finds synonyms for the word at point."
  (interactive)
  (setq site-url (concat "http://www.synonyms.net/subserp.php?lang=EN&qtype=1&st=" (current-word)))
  (url-retrieve site-url 'parse-for (list site-url (current-buffer) t t))
  )

(defun find-antonyms ()
  "Finds antonyms for the word at point"
  (interactive)
  (setq site-url (concat "http://www.synonyms.net/subserp.php?lang=EN&qtype=1&st=" (current-word)))
  (url-retrieve site-url 'parse-for (list site-url (current-buffer) t nil))
  )

(defun parse-for (status site-url &optional point buffer syns)
  "Parses for synonyms or antonyms depending on the value of syns. "
  (let ((redirect (plist-get status :redirect))) 
    (when redirect
      (setq site-url redirect)))
  (if syns (setq class "class=\"syns\"") (setq class "class=\"ants\""))
  (switch-to-buffer-other-window (url-retrieve-synchronously site-url))
  (shrink-window (- (window-total-width) 30) t)
  (setq m1 (make-marker))
  (setq m2 (make-marker))
  (set-marker m1 (point-min))
  (while (search-forward class nil t)
    (delete-region m1 (point))
    (search-forward "</p>" nil t)
    (backward-word 3)
    (set-marker m1 (point))
    )
  (delete-region (point) (point-max))
  (goto-char (point-min))
  (set-marker m2 (point))
  (while (re-search-forward "synonym/[a-z]*[\s]?[-]?[a-z]*" nil t)
    (set-marker m1 (point))
    (search-backward "synonym")
    (forward-word)
    (forward-char)
    (delete-region m2 (point))
    (goto-char m1)
    (insert "\n")
    (set-marker m2 (point))
    )
  (delete-region (point) (point-max))
  (uniquify-all-lines-buffer)
  )

(defun define-word ()
  "Defines the word at point."
  (interactive)
  (setq site-url (concat "http://www.dictionary.com/dic?s=t&q=" (current-word)))
  (url-retrieve site-url 'parse-for-definitions (list site-url (current-buffer)))
  )

(defun parse-for-definitions (status site-url &optional point buffer encode)
  "Parses for definitions."
  (let ((redirect (plist-get status :redirect)))
    (when redirect
      (setq site-url redirect)))
  (switch-to-buffer-other-window (url-retrieve-synchronously site-url))
  (setq m1 (make-marker))
  (set-marker m1 (point-min))
  (while (re-search-forward "def-content\">" nil t)
    (delete-region m1 (point))
    (re-search-forward "[</]div>?" nil t)
    (backward-word 2)
    (forward-word)
    (forward-char)
    (set-marker m1 (point))
    )
  (delete-region m1 (point-max))
  (goto-char (point-min))
  (while (re-search-forward "</?[a-z-\s=/\"]*>" nil t)
    (set-marker m1 (point))
    (re-search-backward "<")
    (delete-region (point) m1)
    )
  (delete-trailing-whitespace)
  (delete-blank-lines)
  )

(defun uniquify-all-lines-region (start end)
  "Find duplicate lines in region START to END keeping first occurrence."
    (interactive "*r")
    (save-excursion
      (let ((end (copy-marker end)))
        (while
            (progn
              (goto-char start)
              (re-search-forward "^\\(.*\\)\n\\(\\(.*\n\\)*\\)\\1\n" end t))
          (replace-match "\\1\n\\2")))))

(defun uniquify-all-lines-buffer ()
  "Delete duplicate lines in buffer and keep first occurrence."
  (interactive "*")
  (uniquify-all-lines-region (point-min) (point-max)))
