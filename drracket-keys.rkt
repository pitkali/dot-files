#lang s-exp framework/keybinding-lang

(define (rebind key command)
  (keybinding
   key
   (λ (ed evt)
     (send (send ed get-keymap) call-function
           command ed evt #t))))

(rebind "d:left" "backward-word")
(rebind "d:right" "forward-word")
(rebind "d:s:left" "backward-select-word")
(rebind "d:s:right" "forward-select-word")
(rebind "d:backspace" "backward-kill-word")
(rebind "d:delete" "kill-word")