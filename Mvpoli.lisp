;; Ispetioning 

(defun monomial-degree (x)
  (third x))

(defun monomial-coefficient (x)
  (second x))

(defun varpowers (x)
  (fourth x))

(defun var-of (x)
  (let ((a (varpowers x)))
    (var-of-helper a)))

(defun var-of-helper (x)
  (if (eql 'nil (cdr x))
      (third (car x))
      (list (third (car x)) (var-of-helper (cdr x)))))

;;; Parsing and normalization

(defun as-monomial (x) 
  (cond ((integerp x)
         (list 'm x 0 'nil))
        ((and (atom x) (symbolp x)) 
              (list 'm 1 1 (list 'v 1 x)))
        ((eql (car x) '*) 
         (let ((a (as-monomial-helper (cdr x) 0)))
            (list 'm (if (integerp (second x))
                         (second x)
                         1)
                  (first (last a))
                  (sort (butlast a) #' string-lessp :key #' third))))))


(defun as-monomial-helper (x acc)
  (if (eql 'nil x) 
        (list acc)
      (cond ((and (atom (car x)) (symbolp (car x)))
            (cons (list 'v 1 (car x)) 
                  (as-monomial-helper (cdr x) (+ acc 1)))) 
            (T (cons (list 'v (third (car x)) (second (car x)))
              (as-monomial-helper (cdr x) (+ acc (third (car x)))))))))
        
(defun as-polynomial (x)
  (if (eql (car x) '+)
      (let ((a (as-polynomial-helper (cdr x))))
        (list 'p (sort a #'> :key #' third)))))
(defun as-polynomial-helper (x) 
  (if (eql 'nil(cdr x))
      (list (as-monomial (car x)))
      (cons (as-monomial (car x)) (as-polynomial-helper (cdr x)))))
      

;;; Checking

(defun is-monomial (m)
  (and (listp m)
       (eq 'm (first m))
       (let ((mtd (monomial-degree m))
             (vps (monomial-vars-and-powers m))
             )
         (and (integerp mtd)
              (>= mtd 0)
              (listp vps)
              (every #'is-varpower vps)))))